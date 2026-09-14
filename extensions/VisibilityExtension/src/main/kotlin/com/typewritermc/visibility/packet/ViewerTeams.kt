package com.typewritermc.visibility.packet

import com.github.retrooper.packetevents.PacketEvents
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTeams
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.format.NamedTextColor
import org.bukkit.entity.Player
import org.bukkit.scoreboard.Team

// Helpers for the client side scoreboard teams that visibility effects use to change glow color,
// nametag visibility and friendly invisibility. The teams exist only on the viewer's client; the
// server side scoreboard is never modified.

/** Name prefix of every team this extension sends, which is how its own packets are recognised. */
const val VISIBILITY_TEAM_PREFIX = "twv_"

fun visibilityTeamName(kind: String, id: Int): String = "$VISIBILITY_TEAM_PREFIX${kind}_$id"

private val NO_TEAM_INFO: WrapperPlayServerTeams.ScoreBoardTeamInfo? = null

/**
 * The parts of a real scoreboard team a client side team has to reproduce, so a target keeps their
 * rank prefix and collision behaviour while an effect is active.
 */
data class RealTeamInfo(
    val color: NamedTextColor?,
    val prefix: Component,
    val suffix: Component,
    val nameTagVisibility: WrapperPlayServerTeams.NameTagVisibility,
    val collisionRule: WrapperPlayServerTeams.CollisionRule,
)

/**
 * Reads the team the viewer's client currently has the member in.
 * Must be called on the main thread. Returns null when the member has no team.
 */
fun realTeamInfoFor(viewer: Player, memberName: String): RealTeamInfo? {
    val team = viewer.scoreboard.getEntryTeam(memberName) ?: return null
    return RealTeamInfo(
        color = if (team.hasColor()) NamedTextColor.nearestTo(team.color()) else null,
        prefix = team.prefix(),
        suffix = team.suffix(),
        nameTagVisibility = team.getOption(Team.Option.NAME_TAG_VISIBILITY).toNameTagVisibility(),
        collisionRule = team.getOption(Team.Option.COLLISION_RULE).toCollisionRule(),
    )
}

/**
 * What has to happen to a team packet the server sends to a viewer whose client side teams we own.
 */
sealed interface TeamPacketEdit {
    /** The packet names none of the held entries and can go out unchanged. */
    data object Untouched : TeamPacketEdit

    /** Every name in the packet is held, so the viewer must never receive it. */
    data object Cancel : TeamPacketEdit

    /** The packet has to go out with only these members remaining. */
    data class KeepMembers(val members: List<String>) : TeamPacketEdit
}

/**
 * Decides how to treat a team packet so it cannot touch the entries we moved into a team of our own.
 *
 * A client entry belongs to exactly one team. A real team claiming one of our names removes it from
 * our team and stops the effect, and removing one of our names from a real team throws on the client
 * and disconnects the viewer. Our own teams are recognised by [VISIBILITY_TEAM_PREFIX] and always
 * pass through untouched.
 *
 * A create still goes out with all of its members stripped, because the team itself has to exist on
 * the client before a member can be restored into it. The listener never routes one here though: a
 * create keeps its members behind component data that cannot be decoded cheaply, so it is passed
 * through whole and our memberships are reclaimed afterwards.
 */
fun editTeamPacket(
    teamName: String,
    mode: WrapperPlayServerTeams.TeamMode,
    players: Collection<String>,
    held: Set<String>,
): TeamPacketEdit {
    if (held.isEmpty()) return TeamPacketEdit.Untouched
    if (teamName.startsWith(VISIBILITY_TEAM_PREFIX)) return TeamPacketEdit.Untouched
    if (mode !in MEMBER_TEAM_MODES) return TeamPacketEdit.Untouched

    val kept = players.filterNot { it in held }
    if (kept.size == players.size) return TeamPacketEdit.Untouched
    if (kept.isEmpty() && mode != WrapperPlayServerTeams.TeamMode.CREATE) return TeamPacketEdit.Cancel
    return TeamPacketEdit.KeepMembers(kept)
}

/** The team modes carrying member names, which are the only ones that can move an entry. */
private val MEMBER_TEAM_MODES = setOf(
    WrapperPlayServerTeams.TeamMode.CREATE,
    WrapperPlayServerTeams.TeamMode.ADD_ENTITIES,
    WrapperPlayServerTeams.TeamMode.REMOVE_ENTITIES,
)

/**
 * One packet the team manager has to send to bring a viewer's client side teams up to date.
 *
 * [diffTeamLayout] decides the transition from one team layout to the next as pure data, so every
 * step of it can be tested without a client on the other end.
 */
sealed interface TeamPacket {
    data class Create(val spec: TeamSpec) : TeamPacket
    data class Update(val spec: TeamSpec) : TeamPacket
    data class Remove(val teamName: String) : TeamPacket
    data class AddMembers(val teamName: String, val members: List<String>) : TeamPacket

    /** Returns a member the viewer no longer holds to the real team the server has them in. */
    data class RestoreRealTeam(val memberName: String) : TeamPacket
}

/**
 * The packets that take a viewer's client from one team layout to the next.
 *
 * A team that lost a member is removed and recreated rather than having the member removed from it.
 * Removing an entry from a team throws on the client when something else moved that entry in the
 * meantime, which disconnects the viewer, while adding an entry can never throw.
 */
fun diffTeamLayout(previous: Map<String, TeamSpec>, current: Map<String, TeamSpec>): List<TeamPacket> {
    val packets = ArrayList<TeamPacket>()

    previous.keys.filterNot { it in current }.forEach { packets.add(TeamPacket.Remove(it)) }

    for ((name, spec) in current) {
        val before = previous[name]
        if (before == null) {
            packets.add(TeamPacket.Create(spec))
            continue
        }
        if (before.members.any { it !in spec.members }) {
            packets.add(TeamPacket.Remove(name))
            packets.add(TeamPacket.Create(spec))
            continue
        }
        if (before.optionsDiffer(spec)) packets.add(TeamPacket.Update(spec))
        val added = spec.members.filterNot { it in before.members }
        if (added.isNotEmpty()) packets.add(TeamPacket.AddMembers(name, added))
    }

    val currentMembers = current.values.flatMapTo(HashSet<String>()) { it.members }
    previous.values.asSequence()
        .flatMap { it.members }
        .distinct()
        .filterNot { it in currentMembers }
        .forEach { packets.add(TeamPacket.RestoreRealTeam(it)) }

    return packets
}

internal fun TeamSpec.optionsDiffer(other: TeamSpec): Boolean =
    copy(members = emptyList()) != other.copy(members = emptyList())

fun sendViewerTeamCreate(
    viewer: Player,
    teamName: String,
    info: WrapperPlayServerTeams.ScoreBoardTeamInfo,
    members: Collection<String>,
) {
    WrapperPlayServerTeams(teamName, WrapperPlayServerTeams.TeamMode.CREATE, info, members) sendSilentlyTo viewer
}

fun sendViewerTeamUpdate(viewer: Player, teamName: String, info: WrapperPlayServerTeams.ScoreBoardTeamInfo) {
    WrapperPlayServerTeams(
        teamName,
        WrapperPlayServerTeams.TeamMode.UPDATE,
        info,
        emptyList<String>(),
    ) sendSilentlyTo viewer
}

fun sendViewerTeamRemove(viewer: Player, teamName: String) {
    WrapperPlayServerTeams(
        teamName,
        WrapperPlayServerTeams.TeamMode.REMOVE,
        NO_TEAM_INFO,
        emptyList<String>(),
    ) sendSilentlyTo viewer
}

fun teamAddEntitiesPacket(teamName: String, members: Collection<String>): WrapperPlayServerTeams =
    WrapperPlayServerTeams(teamName, WrapperPlayServerTeams.TeamMode.ADD_ENTITIES, NO_TEAM_INFO, members)

fun sendViewerTeamAddEntities(viewer: Player, teamName: String, members: Collection<String>) {
    if (members.isEmpty()) return
    teamAddEntitiesPacket(teamName, members) sendSilentlyTo viewer
}

/**
 * Re sends the member's real scoreboard team membership to the viewer.
 * Call this after removing a member from a viewer side team, otherwise the viewer's client treats
 * the member as having no team at all. The team is read from the viewer's own scoreboard, the only
 * one their client knows about. Must be called on the main thread.
 */
fun restoreServerTeamMembership(viewer: Player, memberName: String) {
    val team = viewer.scoreboard.getEntryTeam(memberName) ?: return
    teamAddEntitiesPacket(team.name, listOf(memberName)) sendSilentlyTo viewer
}

/**
 * Sends a team packet without offering it to any packet listener, this extension's included.
 *
 * Two things depend on it. Our own listener filters held names out of team packets, and a restore
 * carries exactly such a name, so the listener would drop the packet that returns it. And reading a
 * team packet back through a wrapper is lossy: packetevents maps the `RESET` color of every
 * uncolored team onto `WHITE`, so a packet that round trips through one comes out recolored.
 */
private infix fun WrapperPlayServerTeams.sendSilentlyTo(viewer: Player) {
    PacketEvents.getAPI().playerManager.sendPacketSilently(viewer, this)
}

private fun Team.OptionStatus.toNameTagVisibility(): WrapperPlayServerTeams.NameTagVisibility = when (this) {
    Team.OptionStatus.ALWAYS -> WrapperPlayServerTeams.NameTagVisibility.ALWAYS
    Team.OptionStatus.NEVER -> WrapperPlayServerTeams.NameTagVisibility.NEVER
    Team.OptionStatus.FOR_OTHER_TEAMS -> WrapperPlayServerTeams.NameTagVisibility.HIDE_FOR_OTHER_TEAMS
    Team.OptionStatus.FOR_OWN_TEAM -> WrapperPlayServerTeams.NameTagVisibility.HIDE_FOR_OWN_TEAM
}

private fun Team.OptionStatus.toCollisionRule(): WrapperPlayServerTeams.CollisionRule = when (this) {
    Team.OptionStatus.ALWAYS -> WrapperPlayServerTeams.CollisionRule.ALWAYS
    Team.OptionStatus.NEVER -> WrapperPlayServerTeams.CollisionRule.NEVER
    Team.OptionStatus.FOR_OTHER_TEAMS -> WrapperPlayServerTeams.CollisionRule.PUSH_OTHER_TEAMS
    Team.OptionStatus.FOR_OWN_TEAM -> WrapperPlayServerTeams.CollisionRule.PUSH_OWN_TEAM
}
