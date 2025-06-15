package com.typewritermc.example.entries.trigger

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.ContextKeys
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.extension.annotations.KeyType
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.triggerAllFor
import org.bukkit.entity.Player
import org.bukkit.event.Cancellable
import org.bukkit.event.HandlerList
import org.bukkit.event.player.PlayerEvent
import kotlin.reflect.KClass

//<code-block:event_entry>
@Entry("example_event", "An example event entry.", Colors.YELLOW, "material-symbols:bigtop-updates")
class ExampleEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : EventEntry
//</code-block:event_entry>

//<code-block:event_entry_listener>
@EntryListener(ExampleEventEntry::class)
fun onEvent(event: SomeBukkitEvent, query: Query<ExampleEventEntry>) {
    // Do something
    val entries = query.find() // Find all the entries of this type, for more information see the Query section
    // Do something with the entries, for example trigger them
    entries.triggerAllFor(event.player, context())
}
//</code-block:event_entry_listener>

//<code-block:event_entry_with_context_keys>
@Entry(
    "example_event_with_context_keys",
    "An example event entry with context keys.",
    Colors.YELLOW,
    "material-symbols:bigtop-updates"
)
// This tells Typewriter that this entry exposes some context
// highlight-next-line
@ContextKeys(ExampleContextKeys::class)
class ExampleEventEntryWithContextKeys(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : EventEntry

// highlight-start
enum class ExampleContextKeys(override val klass: KClass<*>) : EntryContextKey {
    // The two `String::class` have to be the same.
    // The @KeyType is for the panel to know
    @KeyType(String::class)
    // The type here is for casting during runtime
    TEXT(String::class),

    @KeyType(Int::class)
    NUMBER(Int::class),

    // More complex types are also allowed.
    @KeyType(Position::class)
    POSITION(Position::class)
}
// highlight-end

@EntryListener(ExampleEventEntryWithContextKeys::class)
fun onEventAddContext(event: SomeBukkitEvent, query: Query<ExampleEventEntryWithContextKeys>) {
    val entries = query.find()
    // highlight-start
    entries.triggerAllFor(event.player) {
        // Make sure these values are drawn from the event.
        // You MUST supply all the context keys.
        ExampleContextKeys.TEXT withValue "Hello World"
        ExampleContextKeys.NUMBER withValue 42
        ExampleContextKeys.POSITION withValue Position.ORIGIN
    }
    // highlight-end
}
//</code-block:event_entry_with_context_keys>

//<code-block:cancelable_event_entry>
@Entry("example_cancelable_event", "An example cancelable event.", Colors.YELLOW, "material-symbols:block")
class ExampleCancelableEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    // highlight-start
    override val cancel: Var<Boolean> = ConstVar(false),
) : CancelableEventEntry
// highlight-end
//</code-block:cancelable_event_entry>

//<code-block:cancelable_event_listener>
@EntryListener(ExampleCancelableEventEntry::class)
fun onCancelableEvent(event: SomeBukkitEvent, query: Query<ExampleCancelableEventEntry>) {
    val entries = query.find().toList()
    entries.triggerAllFor(event.player, context())

    // highlight-start
    if (entries.shouldCancel(event.player)) {
        event.isCancelled = true
    }
    // highlight-end
}
//</code-block:cancelable_event_listener>

class SomeBukkitEvent(player: Player) : PlayerEvent(player), Cancellable {
    override fun getHandlers(): HandlerList = HANDLER_LIST

    private var cancelled: Boolean = false
    override fun isCancelled(): Boolean = cancelled

    override fun setCancelled(cancelled: Boolean) {
        this@SomeBukkitEvent.cancelled = cancelled
    }

    companion object {
        @JvmStatic
        val HANDLER_LIST = HandlerList()
    }
}
