package com.typewritermc.visibility.packet

import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.visibility.rule.PlayerPair
import com.typewritermc.visibility.rule.VisibilityRule
import kotlinx.coroutines.Dispatchers
import org.bukkit.entity.Player

val VisibilityRule.viewerPlayer: Player? get() = server.getPlayer(viewer)
val VisibilityRule.targetPlayer: Player? get() = server.getPlayer(target)

/**
 * Forces the server to re send every tracking packet of the target to the viewer by untracking and
 * re tracking the pair. The re sent packets pass through the [VisibilityPacketBridge], so hooks
 * registered before this runs apply to the fresh state.
 *
 * Driven by the engine once per lifecycle transition, for the effectors that report
 * [com.typewritermc.visibility.effector.VisibilityEffector.needsPairRerender]. Used for effects that
 * only apply on spawn, such as skins and names. Metadata style effects send synthetic packets
 * instead, which avoids the respawn flicker entirely.
 */
suspend fun PlayerPair.refreshRendering() {
    Dispatchers.Sync.switchContext {
        // Bukkit refuses to hide anyone once the plugin is disabled, and by then every client is
        // being dropped anyway.
        if (!plugin.isEnabled) return@switchContext
        if (viewer == target) return@switchContext
        val viewerPlayer = server.getPlayer(viewer) ?: return@switchContext
        val targetPlayer = server.getPlayer(target) ?: return@switchContext
        if (!viewerPlayer.canSee(targetPlayer)) return@switchContext
        viewerPlayer.hidePlayer(plugin, targetPlayer)
        viewerPlayer.showPlayer(plugin, targetPlayer)
    }
}
