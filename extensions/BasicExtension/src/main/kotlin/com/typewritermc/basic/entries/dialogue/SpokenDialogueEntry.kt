package com.typewritermc.basic.entries.dialogue

import com.typewritermc.basic.entries.dialogue.messengers.spoken.BedrockSpokenDialogueDialogueMessenger
import com.typewritermc.basic.entries.dialogue.messengers.spoken.JavaSpokenDialogueDialogueMessenger
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.DialogueEntry
import com.typewritermc.engine.paper.entry.entries.SpeakerEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.isFloodgate
import org.bukkit.entity.Player
import java.time.Duration

@Entry("spoken", "Display an animated message to the player", "#1E88E5", "mingcute:message-4-fill")
/**
 * The `Spoken Dialogue Action` is an action that displays an animated message to the player. This action provides you with the ability to display a message with a specified speaker, text, and duration.
 *
 * ## How could this be used?
 *
 * This action can be useful in a variety of situations. You can use it to create storylines, provide instructions to players, or create immersive roleplay experiences. The possibilities are endless!
 */
class SpokenDialogueEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    override val speaker: Ref<SpeakerEntry> = emptyRef(),
    @Placeholder
    @Colored
    @MultiLine
    val text: Var<String> = ConstVar(""),
    @Help("The duration it takes to type out the message.")
    val duration: Var<Duration> = ConstVar(Duration.ZERO),
) : DialogueEntry {
    override fun messenger(player: Player, context: InteractionContext): DialogueMessenger<SpokenDialogueEntry> {
        return if (player.isFloodgate) BedrockSpokenDialogueDialogueMessenger(player, context, this)
        else JavaSpokenDialogueDialogueMessenger(player, context, this)
    }
}