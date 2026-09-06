package com.typewritermc.visibility

import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.visibility.packet.VisibilityPacketBridge
import com.typewritermc.visibility.packet.VisibilityTeamManager
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.HandlerList
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerQuitEvent
import org.bukkit.plugin.Plugin
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

/**
 * Keeps the per player state of the visibility system in step with connections.
 *
 * The engine disposes effectors a tick after a player leaves the selection, which for a disconnect
 * is a tick after the player is already gone. Anything an effector keys by the viewer (packet hooks,
 * client side teams) would then survive into the viewer's next session and apply with no rule behind
 * it, so it is dropped here the moment the connection ends. Hides need no such care: the engine's
 * [com.typewritermc.engine.paper.utils.PlayerHides] forgets a disconnected player itself.
 */
@Singleton
class VisibilityPlayerListener : Initializable, Listener, KoinComponent {
    private val plugin: Plugin by inject()
    private val bridge: VisibilityPacketBridge by inject()
    private val teamManager: VisibilityTeamManager by inject()

    override suspend fun initialize() {
        server.pluginManager.registerEvents(this, plugin)
    }

    override suspend fun shutdown() {
        HandlerList.unregisterAll(this)
    }

    @EventHandler(priority = EventPriority.MONITOR)
    fun onQuit(event: PlayerQuitEvent) {
        val player = event.player.uniqueId
        bridge.forget(player)
        teamManager.forget(player)
    }
}
