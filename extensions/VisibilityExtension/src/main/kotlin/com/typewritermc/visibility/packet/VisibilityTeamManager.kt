package com.typewritermc.visibility.packet

import com.github.retrooper.packetevents.PacketEvents
import com.github.retrooper.packetevents.netty.channel.ChannelHelper
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTeams
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.server
import kotlinx.coroutines.Dispatchers
import it.unimi.dsi.fastutil.ints.Int2ObjectOpenHashMap
import it.unimi.dsi.fastutil.objects.Object2LongOpenHashMap
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.format.NamedTextColor
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicLong
import java.util.logging.Logger

/**
 * Which effect a team contribution comes from. One contribution per kind per pair.
 */
enum class TeamContributionKind { GLOW, GHOST, NAMETAG_HIDDEN, NAME }

/**
 * A single effect's request for the client side team of a viewer and target pair.
 */
data class TeamContribution(
    val kind: TeamContributionKind,
    val color: NamedTextColor? = null,
    val hidesNametag: Boolean = false,
    val friendlyInvisible: Boolean = false,
    /** Replaces the prefix of the target's real team. */
    val prefix: Component? = null,
    /** Replaces the suffix of the target's real team. */
    val suffix: Component? = null,
)

/**
 * Everything known about one viewer and target pair when the viewer's teams are composed.
 */
data class PairTeamInput(
    val entityId: Int,
    /** The name the viewer's client displays the target under. A name effect can change it. */
    val targetName: String,
    val contributions: Collection<TeamContribution>,
    val realTeam: RealTeamInfo? = null,
    /** The target's server side name. Differs from [targetName] only under a name effect. */
    val realName: String = targetName,
)

/**
 * One client side team as it should exist on the viewer's client.
 */
data class TeamSpec(
    val name: String,
    /** null when the team has no color of its own, as most real teams do not. */
    val color: NamedTextColor?,
    val nameTagVisibility: WrapperPlayServerTeams.NameTagVisibility,
    val option: WrapperPlayServerTeams.OptionData,
    val prefix: Component,
    val suffix: Component,
    val collisionRule: WrapperPlayServerTeams.CollisionRule,
    val members: List<String>,
)

/** Name of the single team containing the viewer and all of their ghost targets. */
const val GHOST_TEAM_NAME = "${VISIBILITY_TEAM_PREFIX}ghost"

/**
 * Composes every client side team a viewer needs from the contributions of all their pairs.
 *
 * A client scoreboard entry belongs to exactly one team, and vanilla only renders an invisible
 * entity as translucent for a viewer on that entity's team. The viewer therefore has to be a member
 * of every ghost target's team at once, which requires all ghost targets to share a single team.
 * Pairs without a ghost keep a team of their own, so a glow or hidden nametag on one pair never
 * affects another.
 *
 * The shared ghost team carries a single color and a single nametag setting. When ghost pairs
 * disagree the lowest entity id wins, which [hasGhostConflict] reports. Color and collision fall
 * back to [viewerTeam] because the viewer is always a member. Prefix and suffix are dropped: one
 * team has one prefix, and keeping the viewer's would apply their rank to every ghost.
 */
fun composeTeams(
    viewerName: String,
    viewerTeam: RealTeamInfo?,
    pairs: Collection<PairTeamInput>,
): List<TeamSpec> {
    val ordered = pairs.sortedBy { it.entityId }
    val ghostPairs = ghostTeamPairs(viewerName, ordered)
    val teams = ArrayList<TeamSpec>(ordered.size - ghostPairs.size + 1)

    if (ghostPairs.isNotEmpty()) {
        // Only the ghost pairs decide the shared team's appearance. The viewer's own pair is a
        // member because a client entry belongs to one team, not because it requested anything, so
        // a self effect on the viewer must not choose the color for every ghost.
        val contributions = ghostContributors(ordered).flatMap { it.contributions }
        val members = ghostPairs.mapTo(ArrayList(ghostPairs.size + 1)) { it.targetName }
        if (viewerName !in members) members.add(viewerName)

        teams.add(
            TeamSpec(
                name = GHOST_TEAM_NAME,
                color = contributions.firstNotNullOfOrNull { it.color } ?: viewerTeam?.color,
                nameTagVisibility = nameTagVisibilityOf(contributions, viewerTeam?.nameTagVisibility),
                option = WrapperPlayServerTeams.OptionData.FRIENDLY_CAN_SEE_INVISIBLE,
                prefix = Component.empty(),
                suffix = Component.empty(),
                collisionRule = viewerTeam?.collisionRule ?: WrapperPlayServerTeams.CollisionRule.ALWAYS,
                members = members,
            )
        )
    }

    val ghostEntityIds = ghostPairs.mapTo(HashSet(ghostPairs.size)) { it.entityId }
    for (pair in ordered) {
        if (pair.entityId in ghostEntityIds) continue
        teams.add(
            TeamSpec(
                name = visibilityTeamName("p", pair.entityId),
                color = pair.contributions.firstNotNullOfOrNull { it.color } ?: pair.realTeam?.color,
                nameTagVisibility = nameTagVisibilityOf(pair.contributions, pair.realTeam?.nameTagVisibility),
                option = WrapperPlayServerTeams.OptionData.NONE,
                prefix = pair.contributions.firstNotNullOfOrNull { it.prefix }
                    ?: pair.realTeam?.prefix
                    ?: Component.empty(),
                suffix = pair.contributions.firstNotNullOfOrNull { it.suffix }
                    ?: pair.realTeam?.suffix
                    ?: Component.empty(),
                collisionRule = pair.realTeam?.collisionRule ?: WrapperPlayServerTeams.CollisionRule.ALWAYS,
                members = listOf(pair.targetName),
            )
        )
    }

    return teams
}

/**
 * True when the pairs sharing the viewer's ghost team ask for different colors or different
 * nametag visibility, which a single team cannot satisfy at once.
 */
fun hasGhostConflict(pairs: Collection<PairTeamInput>): Boolean {
    val ghosts = ghostContributors(pairs.sortedBy { it.entityId })
    if (ghosts.size < 2) return false

    val colors = ghosts.map { pair -> pair.contributions.firstNotNullOfOrNull { it.color } }
    if (colors.distinct().size > 1) return true
    return ghosts.map { pair -> pair.contributions.any { it.hidesNametag } }.distinct().size > 1
}

/**
 * The name two of the viewer's pairs share, if any two of them do.
 *
 * A client keeps one team per entry name, so two targets displayed under the same name cannot both
 * keep a team of their own. Only reachable through a name effect, since real names are unique.
 */
fun duplicateTargetName(pairs: Collection<PairTeamInput>): String? =
    pairs.groupingBy { it.targetName }.eachCount().entries.firstOrNull { it.value > 1 }?.key

/**
 * How long a viewer waits before their real teams are read again, in ticks.
 *
 * A rank or color change reaching the client half a second late is not worth noticing. A scoreboard
 * plugin rewriting its teams every tick is, so the recompose that would otherwise run for every
 * viewer with an effect is capped at this rate.
 */
const val REAL_TEAM_REFRESH_COOLDOWN_TICKS = 10L

/**
 * The viewers among [pending] whose real teams are due to be read again on [tick].
 *
 * A viewer that is not due keeps their place in the pending set, so a request is only ever delayed
 * and never lost.
 */
fun dueForRealTeamRefresh(
    pending: Collection<UUID>,
    tick: Long,
    lastRefresh: (UUID) -> Long,
): List<UUID> = pending.filter { tick - lastRefresh(it) >= REAL_TEAM_REFRESH_COOLDOWN_TICKS }

/**
 * The first pair disguised under a name a real player already answers to, if there is one.
 *
 * A client keeps one scoreboard entry per name, so such a pair shares its entry with the real bearer
 * of the name, and every team the disguise needs applies to that player too. A disguise using the
 * viewer's own name additionally places the target in the shared ghost team.
 *
 * @param isRealName whether a player of that name is online. Asked only about names that really are
 * a disguise, so a viewer without one costs nothing.
 */
fun stolenTargetName(pairs: Collection<PairTeamInput>, isRealName: (String) -> Boolean): PairTeamInput? =
    pairs.firstOrNull { it.targetName != it.realName && isRealName(it.targetName) }

/**
 * The pairs that have to live in the viewer's shared ghost team.
 *
 * Besides the ghosts themselves this includes the viewer's own pair, because the viewer is a member
 * of the ghost team and a client entry belongs to exactly one team. A separate team for their own
 * pair would take the viewer out of the ghost team, turning every ghost from translucent into fully
 * invisible.
 */
private fun ghostTeamPairs(viewerName: String, ordered: List<PairTeamInput>): List<PairTeamInput> {
    if (ghostContributors(ordered).isEmpty()) return emptyList()
    return ordered.filter { pair ->
        pair.targetName == viewerName || pair.contributions.any { it.friendlyInvisible }
    }
}

/** The pairs that asked for friendly invisibility, which is what the ghost team exists for. */
private fun ghostContributors(ordered: List<PairTeamInput>): List<PairTeamInput> =
    ordered.filter { pair -> pair.contributions.any { it.friendlyInvisible } }

private fun nameTagVisibilityOf(
    contributions: Collection<TeamContribution>,
    fallback: WrapperPlayServerTeams.NameTagVisibility?,
): WrapperPlayServerTeams.NameTagVisibility {
    if (contributions.any { it.hidesNametag }) return WrapperPlayServerTeams.NameTagVisibility.NEVER
    return fallback ?: WrapperPlayServerTeams.NameTagVisibility.ALWAYS
}

/**
 * Owns the client side scoreboard teams of every viewer, shared by all effects that need a team
 * (glow color, hidden nametag, ghost friendly invisibility).
 *
 * Effects register a [TeamContribution] with [contribute] and drop it with [withdraw]. The manager
 * recomposes the viewer's whole team layout once per tick, when the engine calls [flush], and sends
 * only the difference. Routing every team using effect through here is what stops them from
 * overwriting each other, both within a pair and across the pairs of one viewer.
 *
 * All methods must be called from the main thread.
 */
@Singleton
class VisibilityTeamManager : Initializable, KoinComponent {
    private val logger: Logger by inject()

    private class PairState {
        val contributions = LinkedHashMap<TeamContributionKind, TeamContribution>()

        /** The target's server side name, the only one the server scoreboard knows them by. */
        var realName: String = ""

        /** The name the viewer's client displays, which the pair's team has to be keyed by. */
        var displayName: String = ""
        var realTeam: RealTeamInfo? = null
    }

    private class ViewerState {
        val pairs = Int2ObjectOpenHashMap<PairState>()
        var sentTeams: Map<String, TeamSpec> = emptyMap()
        var warnedGhostConflict = false
        var warnedDuplicateName = false
        var warnedStolenName = false
    }

    /**
     * One viewer's client side teams as the packet listener sees them.
     *
     * @property version tells a deferred release whether it is still the newest claim. A release
     * that lost that race does nothing and leaves the newer claim in place.
     */
    private class HeldTeams(
        val version: Long,
        val members: Set<String>,
        val teams: Map<String, List<String>>,
    )

    private val states = ConcurrentHashMap<UUID, ViewerState>()
    private val heldTeams = ConcurrentHashMap<UUID, HeldTeams>()
    private val claimVersions = AtomicLong()
    private val pendingRefreshes = ConcurrentHashMap.newKeySet<UUID>()

    /** The viewers whose pairs changed since the last [flush]. */
    private val dirtyViewers = ConcurrentHashMap.newKeySet<UUID>()

    /** Counted here, not read from the server, so the throttle depends only on its own calls. */
    private var tick = 0L

    // Main thread only, like everything the flush touches. The default places a viewer that was
    // never refreshed past the cooldown, so a first request is served on the next tick.
    private val lastRefreshTick = Object2LongOpenHashMap<UUID>().apply {
        defaultReturnValue(-REAL_TEAM_REFRESH_COOLDOWN_TICKS)
    }

    override suspend fun initialize() {}

    /**
     * The names this manager currently holds in a team of its own on the viewer's client.
     *
     * Kept as an immutable snapshot beside the state the main thread works with, because
     * [VisibilityPacketBridge] reads it from netty threads to keep the server's own scoreboard
     * packets away from these names.
     */
    fun heldTeamMembers(viewerId: UUID): Set<String> = heldTeams[viewerId]?.members ?: emptySet()

    /** The members of each team this manager holds on the viewer's client, keyed by team name. */
    fun heldTeamMemberships(viewerId: UUID): Map<String, List<String>> =
        heldTeams[viewerId]?.teams ?: emptyMap()

    /**
     * Notes that the viewer's copies of the real scoreboard teams may be out of date.
     *
     * Only records the viewer, which is all a netty thread can afford: any team packet at all may
     * have changed a team one of ours copies from, and identifying which would mean decoding every
     * one of them. [flush] does the reading on the server thread. Callable from any thread.
     */
    fun requestRealTeamRefresh(viewerId: UUID) {
        pendingRefreshes.add(viewerId)
    }

    /** Whether [flush] has anything to do. Readable from any thread. */
    fun hasPendingWork(): Boolean = dirtyViewers.isNotEmpty() || pendingRefreshes.isNotEmpty()

    /**
     * Reads the real teams again for the viewers that asked and are due, then sends every viewer
     * whose pairs changed their new team layout.
     *
     * One recompose per viewer per tick, however many contributions arrived. Every effect a viewer
     * gains on joining would otherwise recompose the whole layout once each, and a scoreboard plugin
     * rewriting its teams every tick would make each of its packets pay for a full recompose of every
     * viewer with an effect. Here the refreshes are capped per viewer by
     * [REAL_TEAM_REFRESH_COOLDOWN_TICKS], and all of it runs inside the batch the tick loop already
     * measures.
     *
     * A viewer requested while cooling down keeps their request and is served once the window opens,
     * so a change is delayed rather than dropped. Must be called on the main thread.
     */
    fun flush() {
        tick++
        if (pendingRefreshes.isNotEmpty()) {
            dueForRealTeamRefresh(pendingRefreshes, tick) { viewerId -> lastRefreshTick.getLong(viewerId) }
                .forEach { viewerId ->
                    pendingRefreshes.remove(viewerId)
                    lastRefreshTick.put(viewerId, tick)
                    readRealTeams(viewerId)
                }
        }

        if (dirtyViewers.isEmpty()) return
        val viewers = dirtyViewers.toList()
        dirtyViewers.removeAll(viewers.toSet())
        for (viewerId in viewers) {
            val state = states[viewerId] ?: continue
            apply(viewerId, state)
            if (state.pairs.isEmpty()) states.remove(viewerId, state)
        }
    }

    /**
     * Reads the real team of every target this viewer has a pair for. A rank change or a team recolor
     * during an effect would otherwise never reach the client, since the target sits in one of our
     * teams and no longer in the one that changed.
     */
    private fun readRealTeams(viewerId: UUID) {
        val state = states[viewerId] ?: return
        val viewer = server.getPlayer(viewerId) ?: return
        state.pairs.values.forEach { pair -> pair.realTeam = realTeamInfoFor(viewer, pair.realName) }
        dirtyViewers.add(viewerId)
    }

    /**
     * Takes every team this manager sent back off the clients.
     *
     * A reload discards the manager along with the rest of the extension, so a team still on a
     * client at that point has nothing left to clean it up.
     */
    override suspend fun shutdown() {
        Dispatchers.Sync.switchContext {
            states.forEach { (viewerId, state) ->
                val sent = state.sentTeams
                state.pairs.clear()
                state.sentTeams = emptyMap()
                pendingRefreshes.remove(viewerId)
                dirtyViewers.remove(viewerId)
                lastRefreshTick.removeLong(viewerId)

                val viewer = server.getPlayer(viewerId)
                if (viewer == null) {
                    heldTeams.remove(viewerId)
                    return@forEach
                }

                sent.keys.forEach { name -> sendViewerTeamRemove(viewer, name) }
                sent.values.asSequence()
                    .flatMap { it.members }
                    .distinct()
                    .forEach { member -> restoreServerTeamMembership(viewer, member) }

                // The claim is released behind the packets above, for the reason [releaseAfterFlush] documents:
                // releasing here filters packets the server queued earlier against a claim the
                // client has not received yet, and a real team reclaiming one of our names
                // disconnects the viewer.
                behindPackets(viewer) { heldTeams.remove(viewerId) }
            }
            states.clear()
            pendingRefreshes.clear()
            dirtyViewers.clear()
            lastRefreshTick.clear()
        }
    }

    fun contribute(viewer: Player, target: Player, contribution: TeamContribution) {
        val state = states.computeIfAbsent(viewer.uniqueId) { ViewerState() }
        val pair = state.pairs.computeIfAbsent(target.entityId) { PairState() }
        pair.realName = target.name
        if (pair.displayName.isEmpty()) pair.displayName = target.name
        pair.realTeam = realTeamInfoFor(viewer, target.name)
        pair.contributions[contribution.kind] = contribution
        dirtyViewers.add(viewer.uniqueId)
    }

    /**
     * Tells the manager what the viewer's client calls the target from now on.
     *
     * A client scoreboard entry is keyed by name, so a target shown under a different name has to be
     * placed in the team under that name. Otherwise the team keeps the real name, which the client
     * no longer displays anyone under, and every team using effect on the pair stops applying.
     *
     * Must be called on the main thread.
     */
    fun overrideTargetName(viewer: Player, target: Player, name: String) {
        val state = states.computeIfAbsent(viewer.uniqueId) { ViewerState() }
        val pair = state.pairs.computeIfAbsent(target.entityId) { PairState() }
        pair.realName = target.name
        pair.realTeam = realTeamInfoFor(viewer, target.name)
        pair.displayName = name
        dirtyViewers.add(viewer.uniqueId)
    }

    /**
     * Removes a name effect from a pair, restoring the real name and dropping the prefix and suffix
     * that came with the disguise.
     *
     * Both in one pass rather than a [withdraw] followed by a separate restore, which would send the
     * viewer a team carrying the target's real rank under the disguised name before removing it
     * again. Takes ids rather than players so a name effect can still clean up after either of them
     * went offline. Must be called on the main thread.
     */
    fun restoreTargetName(viewerId: UUID, targetEntityId: Int) {
        val state = states[viewerId] ?: return
        val pair = state.pairs.get(targetEntityId) ?: return

        val dropped = pair.contributions.remove(TeamContributionKind.NAME) != null
        if (!dropped && pair.displayName == pair.realName) return

        pair.displayName = pair.realName
        if (pair.contributions.isEmpty()) state.pairs.remove(targetEntityId)
        dirtyViewers.add(viewerId)
    }

    /**
     * Drops one effect's contribution to a pair.
     * Takes the viewer's id rather than their player so an effect can still clean up after they went
     * offline.
     */
    fun withdraw(viewerId: UUID, targetEntityId: Int, kind: TeamContributionKind) {
        val state = states[viewerId] ?: return
        val pair = state.pairs.get(targetEntityId) ?: return

        pair.contributions.remove(kind)
        // A pair displayed under a different name still needs its team, since that team is what
        // carries the name. Dropping it here would leave the pair without a team on the client.
        if (pair.contributions.isEmpty() && pair.displayName == pair.realName) {
            state.pairs.remove(targetEntityId)
        }
        dirtyViewers.add(viewerId)
    }

    /**
     * Drops all state of a viewer without sending anything.
     * Called when the viewer disconnects. A reconnect starts from an empty scoreboard, so any team
     * recorded as sent no longer exists.
     */
    fun forget(viewerId: UUID) {
        states.remove(viewerId)
        heldTeams.remove(viewerId)
        pendingRefreshes.remove(viewerId)
        dirtyViewers.remove(viewerId)
        lastRefreshTick.removeLong(viewerId)
    }

    private fun apply(viewerId: UUID, state: ViewerState) {
        val viewer = server.getPlayer(viewerId)
        if (viewer == null) {
            state.sentTeams = emptyMap()
            heldTeams.remove(viewerId)
            pendingRefreshes.remove(viewerId)
            dirtyViewers.remove(viewerId)
            lastRefreshTick.removeLong(viewerId)
            return
        }

        val inputs = state.pairs.int2ObjectEntrySet().map { entry ->
            PairTeamInput(
                entry.intKey,
                entry.value.displayName,
                entry.value.contributions.values,
                entry.value.realTeam,
                entry.value.realName,
            )
        }

        if (!state.warnedStolenName) {
            stolenTargetName(inputs) { name -> server.getPlayerExact(name) != null }?.let { pair ->
                state.warnedStolenName = true
                logger.warning(
                    "Viewer ${viewer.name} reads the name '${pair.targetName}' on ${pair.realName}, which is " +
                            "really another player's name. A client keeps one team per name, so the player " +
                            "that name belongs to takes on this disguise's team as well. Give the name " +
                            "visibility effect a name nobody on the server goes by."
                )
            }
        }

        if (!state.warnedDuplicateName && inputs.size > 1) {
            duplicateTargetName(inputs)?.let { name ->
                state.warnedDuplicateName = true
                logger.warning(
                    "Viewer ${viewer.name} reads the name '$name' on more than one player at once. A client " +
                            "keeps one team per name, so all but one of them lose their glow color, hidden " +
                            "nametag or ghost transparency. Give the name visibility effects distinct names."
                )
            }
        }

        // A single pair cannot disagree with itself, and almost every viewer has exactly one, so the
        // check is worth skipping rather than repeating on every contribution.
        if (!state.warnedGhostConflict && inputs.size > 1 && hasGhostConflict(inputs)) {
            state.warnedGhostConflict = true
            logger.warning(
                "Viewer ${viewer.name} has ghost visibility effects with different colors or nametag settings. " +
                        "A client can only put a player in one team, so all ghost targets share the settings of " +
                        "the lowest entity id."
            )
        }

        val previous = state.sentTeams
        val current = composeTeams(viewer.name, realTeamInfoFor(viewer, viewer.name), inputs)
            .associateBy { it.name }

        // The claim covers both the current and the previous members until the packets below are
        // encoded. Filtering runs on the connection's own thread, after the main thread wrote those
        // packets, so releasing a name here would filter packets the server queued earlier against a
        // claim the client has not received yet. Removing an entry that way disconnects the viewer.
        val currentMembers = current.values.flatMapTo(HashSet<String>()) { it.members }
        val version = claim(viewerId, currentMembers + previous.values.flatMap { it.members }, current)

        diffTeamLayout(previous, current).forEach { send(viewer, it) }

        releaseAfterFlush(viewer, viewerId, version, currentMembers, current)
        state.sentTeams = current
    }

    private fun claim(viewerId: UUID, members: Set<String>, teams: Map<String, TeamSpec>): Long {
        val version = claimVersions.incrementAndGet()
        // A viewer with no names claimed gets no entry at all. Storing an empty one would leave a
        // record for every viewer that ever had a rule, which only a disconnect would clear.
        if (members.isEmpty()) {
            heldTeams.remove(viewerId)
            return version
        }
        heldTeams[viewerId] = HeldTeams(version, members, teams.mapValues { (_, spec) -> spec.members })
        return version
    }

    /**
     * Narrows the claim down to what the viewer's teams actually hold, once our packets are encoded.
     *
     * Queued on the connection's thread behind those packets, so by the time it runs the client has
     * received every team change of this pass. A newer claim taken in the meantime wins, and its own
     * release settles the names.
     */
    private fun releaseAfterFlush(
        viewer: Player,
        viewerId: UUID,
        version: Long,
        members: Set<String>,
        teams: Map<String, TeamSpec>,
    ) {
        // Nothing was released, so there is nothing to narrow and no packet to wait behind. A viewer
        // without a claim holds nothing, which is the same as an empty set here.
        if ((heldTeams[viewerId]?.members ?: emptySet<String>()) == members) return

        behindPackets(viewer) {
            heldTeams.computeIfPresent(viewerId) { _, held ->
                if (held.version != version) held
                else if (members.isEmpty()) null
                else HeldTeams(version, members, teams.mapValues { (_, spec) -> spec.members })
            }
        }
    }

    /**
     * Runs [block] on the viewer's own connection, behind every packet already written to it.
     *
     * Runs it inline when there is no connection left, since then there is nothing to wait behind and
     * nothing left to filter against the claim.
     */
    private fun behindPackets(viewer: Player, block: Runnable) {
        val channel = PacketEvents.getAPI().playerManager.getChannel(viewer)
        if (channel == null) {
            block.run()
            return
        }
        ChannelHelper.runInEventLoop(channel, block)
    }

    private fun send(viewer: Player, packet: TeamPacket) = when (packet) {
        is TeamPacket.Create -> sendViewerTeamCreate(viewer, packet.spec.name, packet.spec.toTeamInfo(), packet.spec.members)
        is TeamPacket.Update -> sendViewerTeamUpdate(viewer, packet.spec.name, packet.spec.toTeamInfo())
        is TeamPacket.Remove -> sendViewerTeamRemove(viewer, packet.teamName)
        is TeamPacket.AddMembers -> sendViewerTeamAddEntities(viewer, packet.teamName, packet.members)
        is TeamPacket.RestoreRealTeam -> restoreServerTeamMembership(viewer, packet.memberName)
    }
}

private fun TeamSpec.toTeamInfo() = WrapperPlayServerTeams.ScoreBoardTeamInfo(
    Component.empty(),
    prefix,
    suffix,
    nameTagVisibility,
    collisionRule,
    color,
    option,
)
