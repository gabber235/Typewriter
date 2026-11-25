package com.typewritermc.engine.paper

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import com.typewritermc.identity.SessionReporter
import kotlinx.coroutines.suspendCancellableCoroutine
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.HandlerList
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerJoinEvent
import org.bukkit.event.player.PlayerQuitEvent
import org.bukkit.plugin.Plugin

/**
 * Reports each Minecraft player as a session of its protagonist: a join starts the session's key write and a quit
 * leaves the session vacant. The reporter only queues the writes, so the tick never waits on NATS.
 *
 * Each activation registers the listener and takes over the players already online, so an engine reload keeps their
 * sessions without a gap; quiescing unregisters it and leaves the keys to the next activation or to their expiry.
 */
class SessionListener(
    private val plugin: Plugin,
    private val sessions: SessionReporter,
) : Listener,
    RuntimeRegistrar {
    context(scope: RuntimeScope)
    override suspend fun register() {
        // Registering and taking over on the main thread orders the takeover before any later join or quit event.
        plugin.onMainThread {
            plugin.server.pluginManager.registerEvents(this, plugin)
            plugin.server.onlinePlayers.forEach(::connected)
        }
        scope.own { HandlerList.unregisterAll(this) }
    }

    @EventHandler(priority = EventPriority.MONITOR)
    fun onJoin(event: PlayerJoinEvent) = connected(event.player)

    @EventHandler(priority = EventPriority.MONITOR)
    fun onQuit(event: PlayerQuitEvent) = sessions.disconnected(event.player.session)

    private fun connected(player: Player) = sessions.connected(player.protagonist, player.session)
}

/** A player's protagonist: the Minecraft principal of its UUID. */
private val Player.protagonist: Protagonist get() = Protagonist(PrincipalId(PrincipalId.MINECRAFT, uniqueId.toString()))

/** A Minecraft player has one session at a time, named by its UUID, so a rejoin continues it. */
private val Player.session: SessionId get() = SessionId(uniqueId.toString())

/** Runs [block] on the server's main thread and returns its result. */
private suspend fun <T> Plugin.onMainThread(block: () -> T): T {
    if (server.isPrimaryThread) return block()
    return suspendCancellableCoroutine { continuation ->
        val task = server.scheduler.runTask(this, Runnable { continuation.resumeWith(runCatching(block)) })
        continuation.invokeOnCancellation { task.cancel() }
    }
}
