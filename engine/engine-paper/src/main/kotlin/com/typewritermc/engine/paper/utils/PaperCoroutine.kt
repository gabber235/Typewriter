package com.typewritermc.engine.paper.utils

import com.github.shynixn.mccoroutine.folia.asyncDispatcher
import com.github.shynixn.mccoroutine.folia.entityDispatcher
import com.github.shynixn.mccoroutine.folia.globalRegionDispatcher
import com.github.shynixn.mccoroutine.folia.regionDispatcher
import com.github.shynixn.mccoroutine.folia.registerSuspendingEvents
import com.typewritermc.core.utils.TypewriterDispatcher
import com.typewritermc.engine.paper.plugin
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.bukkit.Location
import org.bukkit.entity.Entity
import org.bukkit.event.Event
import org.bukkit.event.EventHandler
import org.bukkit.event.Listener
import org.bukkit.event.block.BlockEvent
import org.bukkit.event.entity.EntityEvent
import org.bukkit.event.player.PlayerEvent
import org.bukkit.plugin.Plugin
import org.bukkit.plugin.PluginManager
import kotlin.coroutines.CoroutineContext

private object PaperTickedAsyncDispatcher : TypewriterDispatcher(plugin.asyncDispatcher)
private object PaperGlobalSyncDispatcher : TypewriterDispatcher(plugin.globalRegionDispatcher)

/**
 * Dispatcher for the global region.
 * On Folia this is the global region thread: safe for world time, weather, and global state,
 * but NOT for entities, blocks, or chunks. Use [syncDispatcher] on an [Entity] or [Location]
 * for those instead. On Paper this is the main thread, like before.
 */
val Dispatchers.Sync: CoroutineDispatcher get() = PaperGlobalSyncDispatcher
val Dispatchers.TickedAsync: CoroutineDispatcher get() = PaperTickedAsyncDispatcher

/**
 * Dispatcher that ticks with the entity's region scheduler on Folia.
 * Falls back to the main thread on Paper.
 */
val Entity.syncDispatcher: CoroutineContext get() = plugin.entityDispatcher(this)

/**
 * Dispatcher that ticks with the region owning this location on Folia.
 * Falls back to the main thread on Paper.
 */
val Location.syncDispatcher: CoroutineContext get() = plugin.regionDispatcher(this)

/** Runs [block] on the thread that owns this entity. */
suspend fun <T> Entity.switchContext(block: suspend CoroutineScope.() -> T): T =
    withContext(plugin.entityDispatcher(this), block)

/** Runs [block] on the thread that owns the region of this location. */
suspend fun <T> Location.switchContext(block: suspend CoroutineScope.() -> T): T =
    withContext(plugin.regionDispatcher(this), block)

/**
 * Registers a suspending listener with an automatically derived event-dispatcher map.
 * Folia requires every handled event class to be mapped to the scheduler that owns it:
 * player events run on the player's entity scheduler, entity events on the entity's,
 * block events on the owning region, everything else on the global region.
 */
fun PluginManager.registerSuspendingEvents(listener: Listener, plugin: Plugin) {
    registerSuspendingEvents(listener, plugin, eventDispatchersFor(listener))
}

private val eventContextResolver: (Event) -> CoroutineContext = { event ->
    when (event) {
        is PlayerEvent -> plugin.entityDispatcher(event.player)
        is EntityEvent -> plugin.entityDispatcher(event.entity)
        is BlockEvent -> plugin.regionDispatcher(event.block.location)
        else -> plugin.globalRegionDispatcher
    }
}

private fun eventDispatchersFor(listener: Listener): Map<Class<out Event>, (Event) -> CoroutineContext> =
    generateSequence<Class<*>>(listener.javaClass) { it.superclass }
        .flatMap { it.declaredMethods.asSequence() }
        .filter { it.getAnnotation(EventHandler::class.java) != null }
        .filter { it.parameterCount >= 1 && Event::class.java.isAssignableFrom(it.parameterTypes[0]) }
        .associate {
            @Suppress("UNCHECKED_CAST")
            (it.parameterTypes[0] as Class<out Event>) to eventContextResolver
        }
