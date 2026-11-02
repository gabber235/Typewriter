package com.typewritermc.visibility.entry.effect

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerTeams
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.entry.entity.FakeEntity
import com.typewritermc.engine.paper.entry.entity.toCollectors
import com.typewritermc.engine.paper.entry.entity.toProperty
import com.typewritermc.engine.paper.entry.entity.withPriority
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.EntityDefinitionEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.playerHides
import com.typewritermc.visibility.VisibilityEngine
import com.typewritermc.visibility.VisibilityHideRegistry
import com.typewritermc.visibility.VisibleReplacement
import com.typewritermc.visibility.effector.ProvidesVisibleReplacement
import com.typewritermc.visibility.effector.TickableVisibilityEffector
import com.typewritermc.visibility.effector.VisibilityConfigurationException
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.packet.EntityFlag
import com.typewritermc.visibility.packet.EntityFlagOverlay
import com.typewritermc.visibility.packet.RealTeamInfo
import com.typewritermc.visibility.packet.TeamContribution
import com.typewritermc.visibility.packet.TeamContributionKind
import com.typewritermc.visibility.packet.VisibilityTeamManager
import com.typewritermc.visibility.packet.targetPlayer
import com.typewritermc.visibility.packet.viewerPlayer
import com.typewritermc.visibility.rule.VisibilityRule
import kotlinx.coroutines.Dispatchers
import net.kyori.adventure.text.Component
import org.bukkit.GameMode
import org.bukkit.World
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

@Entry(
    "disguise_visibility_effect",
    "Shows the target as a different entity to the viewer",
    Colors.BLUE_VIOLET,
    "fa6-solid:masks-theater"
)
/**
 * The `Disguise Visibility Effect` replaces the target with an entity from an entity definition,
 * but only for the viewer. The real player is hidden and the definition entity mirrors their
 * movement.
 *
 * Any entity definition works, from a zombie to an npc with a different skin.
 *
 * With the self option the target also sees the disguise where their own body would be. Their body turns
 * invisible for them, or see through when they are on a scoreboard team that shows invisible teammates, which
 * teams do by default. Their bare arm disappears in first person either way, while their armor and held items
 * stay visible. The disguise surrounds their view, so they cannot break, place or hit anything through it. It is
 * left out while they ride, are dead or spectate. To turn it off during a cinematic, give the option a variable
 * that is false while the cinematic plays.
 *
 * ## How could this be used?
 * Turn a werewolf player into a wolf for everyone without the detection ability, or let an
 * infiltrator appear as a guard npc to the guards' faction.
 */
class DisguiseVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The entity definition the viewer sees instead of the target.")
    val definition: Ref<out EntityDefinitionEntry> = emptyRef(),
    @Help(
        "Also apply this effect to the target's own view of themselves. Their own body turns invisible or " +
            "see through, and the disguise blocks clicks on anything behind it."
    )
    val self: Var<Boolean> = ConstVar(false),
) : VisibilityEffectEntry {
    // A toggle that is always on still changes its answer when the player mounts, dies or spectates.
    override val selfView: SelfView
        get() = when (val toggle = selfToggle(id, self)) {
            SelfView.Never -> SelfView.Never
            else -> SelfView.PerPlayer { player ->
                val standing = canShowOwnDisguise(player.vehicle != null, player.isDead, player.gameMode)
                if (standing) toggle.partsFor(player) else emptySet()
            }
        }

    override fun createEffector(rule: VisibilityRule): VisibilityEffector =
        DisguiseVisibilityEffector(rule, definition)
}

/**
 * Whether a player can be shown their own disguise. A rider is placed at the vehicle's position, a dead player
 * lies on the ground and a spectator flies through blocks, so none of them has a standing body for the disguise
 * to take the place of.
 */
internal fun canShowOwnDisguise(riding: Boolean, dead: Boolean, gameMode: GameMode): Boolean =
    !riding && !dead && gameMode != GameMode.SPECTATOR

/**
 * The team a fake player sits in on its own: nametag hidden, since a client always draws a player's
 * nametag unless a team hides it, and no collision.
 */
internal val FAKE_PLAYER_BASE_TEAM = RealTeamInfo(
    color = null,
    prefix = Component.empty(),
    suffix = Component.empty(),
    nameTagVisibility = WrapperPlayServerTeams.NameTagVisibility.NEVER,
    collisionRule = WrapperPlayServerTeams.CollisionRule.NEVER,
)

/**
 * What a disguise itself needs from the pair's team, or null when it needs nothing.
 *
 * A [fakePlayer] leaves its own team when a bundled glow or ghost moves it into the pair's team. Holding
 * it there for as long as the disguise lives, starting from the settings of that team, keeps its nametag
 * from appearing and disappearing with the other effects. The [selfView] also keeps the disguise from
 * pushing the player on their client, since it follows a tick behind their own movement.
 */
internal fun disguiseTeamContribution(fakePlayer: Boolean, selfView: Boolean): TeamContribution? {
    if (!fakePlayer && !selfView) return null
    return TeamContribution(
        kind = TeamContributionKind.DISGUISE,
        collisionRule = if (selfView) WrapperPlayServerTeams.CollisionRule.NEVER else null,
        baseTeam = if (fakePlayer) FAKE_PLAYER_BASE_TEAM else null,
    )
}

/**
 * The world a viewer can be shown a disguise in, or null when it has to stay away.
 *
 * A client only holds the entities of its own world. Another feature hiding the target, like a
 * cinematic, hides the disguise with them.
 */
internal fun disguiseWorld(viewerWorld: World, targetWorld: World, hiddenByOthers: Boolean): World? {
    if (viewerWorld != targetWorld) return null
    if (hiddenByOthers) return null
    return targetWorld
}

private class DisguiseVisibilityEffector(
    private val rule: VisibilityRule,
    private val definitionRef: Ref<out EntityDefinitionEntry>,
) : TickableVisibilityEffector, ProvidesVisibleReplacement, KoinComponent {
    private val hideRegistry: VisibilityHideRegistry by inject()
    private val teamManager: VisibilityTeamManager by inject()
    private val engine: VisibilityEngine by inject()

    // Stays on the player's real entity. Every other overlay of a bundle follows the disguise.
    private val ownBody = EntityFlagOverlay(rule, EntityFlag.INVISIBLE, followsReplacement = false)

    // The tab list entry is re added by the pair re render: hiding the target removes it along
    // with the world entity, and the re render puts it back without touching the fake. A bundled
    // name effect rewrites it to the disguised name on the way through.
    override val needsPairRerender: Boolean get() = !rule.isSelf

    // Initialize, tick and dispose all run on the server thread and none of them suspends while it
    // touches this state, so it needs no lock.
    private var entity: FakeEntity? = null
    private var teamKey = -1
    private var shownIn: World? = null
    private var restartRequested = false
    private var disposed = false

    override suspend fun initialize() {
        if (rule.isSelf) ownBody.attach()
        Dispatchers.Sync.switchContext {
            if (disposed) return@switchContext
            val viewer = rule.viewerPlayer ?: return@switchContext
            val target = rule.targetPlayer ?: return@switchContext
            val definition = definitionRef.get() ?: throw VisibilityConfigurationException(
                "Could not find entity definition '${definitionRef.id}' for disguise effect on entry '${rule.entryId}'"
            )

            val disguise = definition.create(viewer)
            val properties = definition.data.withPriority().toCollectors().mapNotNull { it.collect(viewer) }

            hideRegistry.hide(viewer, target, VisibleReplacement(disguise.entityId, disguise.scoreboardMember))
            // The field is set before the spawn: a spawn that throws partway has already placed
            // entities on the client, and only dispose can remove those.
            entity = disguise
            // Contributed after the replacement is recorded, so the team holds the fake and not the player.
            val fakePlayer = disguise.scoreboardMember != disguise.uuid.toString()
            disguiseTeamContribution(fakePlayer, rule.isSelf)?.let {
                teamKey = teamManager.contribute(viewer, target, it)
            }

            val world = worldToShowIn(viewer, target) ?: return@switchContext
            shownIn = world
            disguise.spawn(target.location.toProperty())
            disguise.consumeProperties(properties)
        }
    }

    // A player is never hidden from themselves, so only the world counts for the self view. Every other pair
    // holds one hide of its own, the one this disguise placed.
    private fun worldToShowIn(viewer: Player, target: Player): World? {
        val hiddenByOthers = !rule.isSelf && playerHides.ownerCount(viewer.uniqueId, target.uniqueId) > 1
        return disguiseWorld(viewer.world, target.world, hiddenByOthers)
    }

    override suspend fun tick() {
        if (disposed || restartRequested) return
        val disguise = entity ?: return
        val viewer = rule.viewerPlayer ?: return
        val target = rule.targetPlayer ?: return

        // A shown disguise cannot be taken back and shown again under the same entity, and a client
        // that changed world has dropped it already. A fresh effect spawns a new one and moves the
        // bundle's siblings over to it.
        if (worldToShowIn(viewer, target) != shownIn) {
            restartRequested = true
            engine.restartEffectOf(rule)
            return
        }
        if (shownIn == null) return

        disguise.consumeProperties(target.location.toProperty())
        disguise.tick()
    }

    override suspend fun dispose() {
        Dispatchers.Sync.switchContext {
            disposed = true
            if (teamKey != -1) teamManager.withdraw(rule.viewer, teamKey, TeamContributionKind.DISGUISE)
            entity?.dispose()
            entity = null
            shownIn = null
            hideRegistry.show(rule.viewer, rule.target)
        }
        // After the disguise is gone, so the player never sees their body and the disguise at once.
        if (rule.isSelf) ownBody.detach()
    }
}
