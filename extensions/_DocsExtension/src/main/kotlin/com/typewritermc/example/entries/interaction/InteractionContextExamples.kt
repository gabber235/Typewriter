package com.typewritermc.example.entries.interaction

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.GlobalContextKey
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.dialogue.*
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.DialogueEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.entries.SpeakerEntry
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.example.entries.trigger.SomeBukkitEvent
import org.bukkit.entity.Player
import kotlin.reflect.KClass

//<code-block:entry_context_keys>
enum class ExampleEntryContextKeys(override val klass: KClass<*>) : EntryContextKey {
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
//</code-block:entry_context_keys>

//<code-block:global_context_key>
@GlobalKey(Int::class)
object LuckyNumberKey : GlobalContextKey<Int>(Int::class)
//</code-block:global_context_key>


//<code-block:event_entry_with_context_keys>
@Entry(
    "example_event_with_context_keys",
    "An example event entry with context keys.",
    Colors.YELLOW,
    "material-symbols:bigtop-updates"
)
// This tells Typewriter that this entry exposes some context
// highlight-next-line
@ContextKeys(ExampleEntryContextKeys::class)
class ExampleEventEntryWithContextKeys(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : EventEntry

@EntryListener(ExampleEventEntryWithContextKeys::class)
fun onEventAddContext(event: SomeBukkitEvent, query: Query<ExampleEventEntryWithContextKeys>) {
    val entries = query.find()
    // highlight-start
    entries.triggerAllFor(event.player) {
        // Make sure these values are drawn from the event.
        // You MUST supply all the context keys.
        ExampleEntryContextKeys.TEXT withValue "Hello World"
        ExampleEntryContextKeys.NUMBER withValue 42
        // You can also use += to assign the value to the key
        ExampleEntryContextKeys.POSITION += Position.ORIGIN

        // Or we can assign any global key to it.
        LuckyNumberKey += 69
    }
    // highlight-end
}
//</code-block:event_entry_with_context_keys>

//<code-block:action_context_basic>
@Entry("example_action_with_context", "An action that reads/writes from/to interaction context", Colors.RED, "material-symbols:touch-app-rounded")
// This tells Typewriter that this entry exposes some context
// highlight-next-line
@ContextKeys(ExampleEntryContextKeys::class)
class ExampleActionWithContextEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        // Writing values to the context
        // highlight-start
        context[ref(), ExampleEntryContextKeys.TEXT] = "Hey there"
        context[ref(), ExampleEntryContextKeys.NUMBER] = 42
        context[ref(), ExampleEntryContextKeys.POSITION] = Position.ORIGIN
        context[LuckyNumberKey] = 69
        // highlight-end

        // Reading values from the context
        // highlight-start
        val text: String? = context[ref(), ExampleEntryContextKeys.TEXT]
        val number: Int? = context[ref(), ExampleEntryContextKeys.NUMBER]
        val position: Position? = context[ref(), ExampleEntryContextKeys.POSITION]
        val luckyNumber = context[LuckyNumberKey]
        // highlight-end

        player.sendMessage("$text, the number is $number at $position and the lucky number is $luckyNumber".asMini())
    }
}
//</code-block:action_context_basic>

//<code-block:dialogue_context_input>
@Entry("example_dialogue_with_context_keys", "A dialogue that captures string input", Colors.BLUE, "material-symbols:keyboard-rounded")
// This tells Typewriter that this entry exposes some context
// highlight-next-line
@ContextKeys(ExampleEntryContextKeys::class)
class ExampleStringInputDialogueEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    override val speaker: Ref<SpeakerEntry> = emptyRef(),
) : DialogueEntry {
    override fun messenger(player: Player, context: InteractionContext): DialogueMessenger<*> {
        return ExampleDialogueMessenger(player, context, this)
    }
}

class ExampleDialogueMessenger(
    player: Player,
    context: InteractionContext,
    entry: ExampleStringInputDialogueEntry,
) : DialogueMessenger<ExampleStringInputDialogueEntry>(player, context, entry) {

    override fun init() {
        super.init()

        // We can read and write the context in the init
        // highlight-start
        context[entry, ExampleEntryContextKeys.TEXT] = "Hey there"
        val text: String? = context[entry, ExampleEntryContextKeys.TEXT]
        // highlight-end
    }

    override fun tick(context: TickContext) {
        // We can also read and write the context in the tick method.
        // If we modify it, it will live modify the player.interactionContext values which other entries can use.
        // highlight-start
        this.context[entry, ExampleEntryContextKeys.NUMBER] = 42
        this.context[entry, ExampleEntryContextKeys.POSITION] = player.position
        this.context[LuckyNumberKey] = 69
        // highlight-end

        // And also read from the context
        // highlight-start
        val number: Int? = this.context[entry, ExampleEntryContextKeys.NUMBER]
        val position: Position? = this.context[entry, ExampleEntryContextKeys.POSITION]
        val luckyNumber = this.context[LuckyNumberKey]
        // highlight-end

        state = MessengerState.FINISHED
        super.tick(context)
    }
}
//</code-block:dialogue_context_input>