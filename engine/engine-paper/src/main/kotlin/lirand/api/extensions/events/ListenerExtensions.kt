package lirand.api.extensions.events

import com.typewritermc.engine.paper.utils.server
import org.bukkit.event.Event
import org.bukkit.event.EventPriority
import org.bukkit.event.HandlerList
import org.bukkit.event.Listener
import org.bukkit.plugin.Plugin
import kotlin.reflect.KClass
import kotlin.reflect.cast

data class ListenerWithPlugin(val listener: Listener, val plugin: Plugin)

class SimpleListener : Listener

fun Listener.unregister() = HandlerList.unregisterAll(this)

inline fun <reified T : Event> Listener.listen(
    plugin: Plugin,
    priority: EventPriority = EventPriority.NORMAL,
    ignoreCancelled: Boolean = false,
    noinline block: (event: T) -> Unit
): Unit = listen(plugin, T::class, priority, ignoreCancelled, block)

inline fun <reified T : Event> ListenerWithPlugin.listen(
    priority: EventPriority = EventPriority.NORMAL,
    ignoreCancelled: Boolean = false,
    noinline block: (event: T) -> Unit
): Unit = listen(T::class, priority, ignoreCancelled, block)


fun <T : Event> Listener.listen(
    plugin: Plugin,
    type: KClass<T>,
    priority: EventPriority = EventPriority.NORMAL,
    ignoreCancelled: Boolean = false,
    block: (event: T) -> Unit
): Unit = server.pluginManager.registerEvent(
    type.java,
    this,
    priority,
    { _, event ->
        if (!type.isInstance(event)) {
            return@registerEvent
        }
        type.cast(event).let(block)
    },
    plugin,
    ignoreCancelled
)

fun <T : Event> ListenerWithPlugin.listen(
    type: KClass<T>,
    priority: EventPriority = EventPriority.NORMAL,
    ignoreCancelled: Boolean = false,
    block: (event: T) -> Unit
): Unit = listener.listen(plugin, type, priority, ignoreCancelled, block)


inline fun <reified T : Event> Plugin.listen(
    listener: Listener = SimpleListener(),
    priority: EventPriority = EventPriority.NORMAL,
    ignoreCancelled: Boolean = false,
    noinline block: (event: T) -> Unit,
): Listener = listener.apply {
    listen(this@listen, priority, ignoreCancelled, block)
}


inline fun Plugin.events(
    listener: Listener = SimpleListener(),
    crossinline block: ListenerWithPlugin.() -> Unit
) = listener.apply {
    ListenerWithPlugin(listener, this@events).apply(block)
}