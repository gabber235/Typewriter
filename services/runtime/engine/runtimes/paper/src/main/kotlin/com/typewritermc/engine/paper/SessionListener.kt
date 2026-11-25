package com.typewritermc.engine.paper

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.discovery.RuntimeScope
import com.typewritermc.identity.OnlineSessions
import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.suspendCancellableCoroutine
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.HandlerList
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerJoinEvent
import org.bukkit.event.player.PlayerQuitEvent
import org.bukkit.plugin.Plugin
import java.time.Instant

/**
 * The online Minecraft players, each a session of its protagonist with the instant it logged in, kept on the main
 * thread from Paper's own list and its join and quit events. A player already online when the listener starts keeps
 * its own login instant too, so a reloaded engine never claims a session as newer than a connection made elsewhere
 * since. Changing the set only records it, so the tick never waits on NATS, and the engine reads it
 * from any thread without asking Bukkit.
 *
 * Each activation registers the listener and starts the set from the players already online, so an engine reload
 * keeps their sessions without a gap; quiescing unregisters it and leaves the keys to the next activation or to their
 * expiry.
 */
class SessionListener(
    private val plugin: Plugin,
) : OnlineSessions,
    Listener,
    RuntimeRegistrar {
    private val online = MutableStateFlow<Map<Session, Instant>>(emptyMap())

    override val sessions: StateFlow<Map<Session, Instant>> = online.asStateFlow()

    context(scope: RuntimeScope)
    override suspend fun register() {
        // Registering and reading the players on the main thread orders the start before any later join or quit event.
        plugin.onMainThread {
            plugin.server.pluginManager.registerEvents(this, plugin)
            online.value = plugin.server.onlinePlayers.associate { it.session to it.connected }
        }
        scope.own { HandlerList.unregisterAll(this) }
    }

    @EventHandler(priority = EventPriority.MONITOR)
    fun onJoin(event: PlayerJoinEvent) = online.update { it + (event.player.session to event.player.connected) }

    @EventHandler(priority = EventPriority.MONITOR)
    fun onQuit(event: PlayerQuitEvent) = online.update { it - event.player.session }
}

/**
 * A player's session: its protagonist is the Minecraft principal of its UUID, and a player has one session at a time,
 * named by its UUID, so a rejoin continues it.
 */
private val Player.session: Session
    get() = Session(Protagonist(PrincipalId(PrincipalId.MINECRAFT, uniqueId.toString())), SessionId(uniqueId.toString()))

/** Runs [block] on the server's main thread and returns its result. */
private suspend fun <T> Plugin.onMainThread(block: () -> T): T {
    if (server.isPrimaryThread) return block()
    return suspendCancellableCoroutine { continuation ->
        val task = server.scheduler.runTask(this, Runnable { continuation.resumeWith(runCatching(block)) })
        continuation.invokeOnCancellation { task.cancel() }
    }
}

/** When the player's connection began: Paper stamps each login before its join event, and keeps it while it lasts. */
private val Player.connected: Instant get() = Instant.ofEpochMilli(lastLogin)
