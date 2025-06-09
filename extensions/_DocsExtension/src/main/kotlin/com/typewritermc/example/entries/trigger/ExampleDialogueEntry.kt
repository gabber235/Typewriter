package com.typewritermc.example.entries.trigger

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.dialogue.*
import com.typewritermc.engine.paper.entry.entries.DialogueEntry
import com.typewritermc.engine.paper.entry.entries.SpeakerEntry
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.utils.asMini
import org.bukkit.entity.Player

//<code-block:dialogue_entry>
@Entry("example_dialogue", "An example dialogue entry.", Colors.BLUE, "material-symbols:chat-rounded")
class ExampleDialogueEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    override val speaker: Ref<SpeakerEntry> = emptyRef(),
    @MultiLine
    @Placeholder
    @Colored
    @Help("The text to display to the player.")
    val text: String = "",
) : DialogueEntry {
    // May return null to skip the dialogue
    override fun messenger(player: Player, context: InteractionContext): DialogueMessenger<*>? {
        // You can use if statements to return a different messenger depending on different conditions
        return ExampleDialogueDialogueMessenger(player, context, this)
    }
}
//</code-block:dialogue_entry>

//<code-block:dialogue_messenger>
class ExampleDialogueDialogueMessenger(player: Player, context: InteractionContext, entry: ExampleDialogueEntry) :
    DialogueMessenger<ExampleDialogueEntry>(player, context, entry) {

    // Called every game tick (20 times per second).
    // The cycle is a parameter that is incremented every tick, starting at 0.
    override fun tick(context: TickContext) {
        super.tick(context)
        if (state != MessengerState.RUNNING) return

        player.sendMessage("${entry.speakerDisplayName}: ${entry.text}".parsePlaceholders(player).asMini())

        // When we want the dialogue to end, we can set the state to FINISHED.
        state = MessengerState.FINISHED
    }
}
//</code-block:dialogue_messenger>

@Entry(
    "example_confirmation_dialogue",
    "A dialogue requiring confirmation.",
    Colors.BLUE,
    "material-symbols:chat-rounded"
)
class ExampleConfirmationDialogueEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    override val speaker: Ref<SpeakerEntry> = emptyRef(),
    @MultiLine
    @Placeholder
    @Colored
    @Help("The text to display to the player.")
    val text: String = "",
) : DialogueEntry {
    override fun messenger(player: Player, context: InteractionContext): DialogueMessenger<*>? {
        return ExampleConfirmationDialogueMessenger(player, context, this)
    }
}

//<code-block:dialogue_confirmation_messenger>
class ExampleConfirmationDialogueMessenger(
    player: Player,
    context: InteractionContext,
    entry: ExampleConfirmationDialogueEntry,
) : DialogueMessenger<ExampleConfirmationDialogueEntry>(player, context, entry) {

    // highlight-next-line
    private var confirmationKeyHandler: ConfirmationKeyHandler? = null

    override fun init() {
        super.init()
        player.sendMessage(
            "${entry.speakerDisplayName}: ${entry.text} <gray><confirmation_key>".parsePlaceholders(
                player
            ).asMini()
        )
        // highlight-start
        confirmationKeyHandler = confirmationKey.handler(player) {
            state = MessengerState.FINISHED
        }
        // highlight-end
    }

    override fun dispose() {
        super.dispose()
        // highlight-start
        confirmationKeyHandler?.dispose()
        confirmationKeyHandler = null
        // highlight-end
    }
}
//</code-block:dialogue_confirmation_messenger>
