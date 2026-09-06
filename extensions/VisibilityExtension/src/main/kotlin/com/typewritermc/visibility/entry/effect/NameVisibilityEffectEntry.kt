package com.typewritermc.visibility.entry.effect

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerPlayerInfoUpdate
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Colored
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.packet.ProfilePacketHook
import com.typewritermc.visibility.packet.TeamContribution
import com.typewritermc.visibility.packet.TeamContributionKind
import com.typewritermc.visibility.packet.VisibilityPacketBridge
import com.typewritermc.visibility.packet.VisibilityTeamManager
import com.typewritermc.visibility.packet.targetPlayer
import com.typewritermc.visibility.packet.viewerPlayer
import com.typewritermc.visibility.rule.VisibilityRule
import kotlinx.coroutines.Dispatchers
import net.kyori.adventure.text.Component
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.EnumSet
import java.util.logging.Logger

@Entry(
    "name_visibility_effect",
    "Changes the name the viewer sees on the target",
    Colors.PINK,
    "mdi:rename-outline"
)
/**
 * The `Name Visibility Effect` changes the name the viewer reads on the target, in the tab list and
 * above their head, and the prefix and suffix around it. The target keeps their real name for
 * everyone else, and for the server: chat, commands and death messages are unaffected.
 *
 * The name has to look like a Minecraft name, so at most 16 characters. Colors belong in the prefix
 * and the suffix rather than in the name itself.
 *
 * ## How could this be used?
 * Give a staff member a plain second identity while they walk through an event, or combine it with
 * a skin visibility effect so an undercover player is unrecognisable to the players they infiltrate.
 */
class NameVisibilityEffectEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The name the viewer reads on the target. Leave this empty to keep their real name.")
    val disguisedName: Var<String> = ConstVar(""),
    @Colored
    @Placeholder
    @Help("Shown in front of the name, replacing the prefix of the target's real team.")
    val prefix: Var<String> = ConstVar(""),
    @Colored
    @Placeholder
    @Help("Shown behind the name, replacing the suffix of the target's real team.")
    val suffix: Var<String> = ConstVar(""),
) : VisibilityEffectEntry {
    // A client reads its own name from the session it logged in with rather than from the tab list,
    // so a viewer cannot be renamed for themselves the way a target can.
    override val supportsSelf: Boolean get() = false

    override fun appliesToSelf(viewer: Player): Boolean = false

    override fun createEffector(rule: VisibilityRule): VisibilityEffector =
        NameVisibilityEffector(rule, disguisedName, prefix, suffix)
}

/** Longest name a client accepts in a profile, which is what the disguise is written into. */
private const val MAX_NAME_LENGTH = 16

private class NameVisibilityEffector(
    private val rule: VisibilityRule,
    private val disguisedName: Var<String>,
    private val prefix: Var<String>,
    private val suffix: Var<String>,
) : VisibilityEffector, ProfilePacketHook, KoinComponent {
    private val logger: Logger by inject()
    private val bridge: VisibilityPacketBridge by inject()
    private val teamManager: VisibilityTeamManager by inject()

    @Volatile
    private var nameOverride: String? = null

    @Volatile
    private var targetEntityId = -1

    @Volatile
    private var hooked = false

    override suspend fun initialize() {
        Dispatchers.Sync.switchContext {
            if (rule.isSelf) return@switchContext
            val viewer = rule.viewerPlayer ?: return@switchContext
            val target = rule.targetPlayer ?: return@switchContext
            targetEntityId = target.entityId

            val name = resolveName(viewer, target)
            val prefixText = prefix.componentFor(viewer)
            val suffixText = suffix.componentFor(viewer)
            if (name == null && prefixText == null && suffixText == null) return@switchContext

            // The name first, so the team it needs is created keyed by that name immediately rather
            // than under the real one and then moved.
            if (name != null) {
                nameOverride = name
                teamManager.overrideTargetName(viewer, target, name)
                bridge.addProfileHook(viewer.uniqueId, rule.target, this@NameVisibilityEffector)
                hooked = true
            }
            if (prefixText != null || suffixText != null) {
                teamManager.contribute(
                    viewer,
                    target,
                    TeamContribution(kind = TeamContributionKind.NAME, prefix = prefixText, suffix = suffixText),
                )
            }
        }
    }

    // A client keeps the profile it received when the player was added to it, so it only reads a new
    // name once the player is added again. Stays true through the disposal, which is what restores the
    // real name the same way.
    override val needsPairRerender: Boolean get() = hooked

    override fun onPlayerInfo(
        actions: EnumSet<WrapperPlayServerPlayerInfoUpdate.Action>,
        entry: WrapperPlayServerPlayerInfoUpdate.PlayerInfo,
    ) {
        val name = nameOverride ?: return
        if (WrapperPlayServerPlayerInfoUpdate.Action.ADD_PLAYER in actions) {
            entry.gameProfile.name = name
        }
        // The tab list renders a display name set by anything else in place of the profile name, so
        // the disguise has to clear it too. Only reachable when the packet carries the field, and a
        // packet omitting it cannot have changed it either.
        if (WrapperPlayServerPlayerInfoUpdate.Action.UPDATE_DISPLAY_NAME in actions) {
            entry.displayName = null
        }
    }

    override suspend fun dispose() {
        Dispatchers.Sync.switchContext {
            if (hooked) bridge.removeProfileHook(rule.viewer, rule.target, this@NameVisibilityEffector)
            if (targetEntityId == -1) return@switchContext

            teamManager.restoreTargetName(rule.viewer, targetEntityId)
            nameOverride = null
        }
    }

    /**
     * The name to disguise the target under, or null to leave their name unchanged.
     * A name the client would reject is reported and dropped rather than allowed to break the target's
     * tab entry, so a prefix and suffix configured beside it still apply.
     */
    private fun resolveName(viewer: Player, target: Player): String? {
        val requested = disguisedName.get(viewer).trim()
        if (requested.isEmpty() || requested == target.name) return null
        if (requested.length > MAX_NAME_LENGTH) {
            logger.warning(
                "The name visibility effect of entry '${rule.entryId}' wants ${target.name} to be called " +
                        "'$requested', which is longer than the $MAX_NAME_LENGTH characters a client takes " +
                        "for a name. Their real name is used instead."
            )
            return null
        }
        // A client keeps one scoreboard entry per name, so a disguise under a name somebody on the
        // server answers to would put every team the disguise needs on that player as well.
        if (server.getPlayerExact(requested) != null) {
            logger.warning(
                "The name visibility effect of entry '${rule.entryId}' wants ${target.name} to be called " +
                        "'$requested', which is the name of a player on the server. Their real name is used " +
                        "instead."
            )
            return null
        }
        return requested
    }

    private fun Var<String>.componentFor(viewer: Player): Component? =
        get(viewer).takeIf { it.isNotBlank() }?.parsePlaceholders(viewer)?.asMini()
}
