package com.typewritermc.basic.entries.dialogue

import com.typewritermc.basic.entries.dialogue.messengers.timed.BedrockTimedDialogueDialogueMessenger
import com.typewritermc.basic.entries.dialogue.messengers.timed.JavaTimedDialogueDialogueMessenger
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

@Entry("timed_dialogue", "Display a timed animated message to the player", "#FF9800", "mingcute:sandglass-fill")
/**
 * The `Timed Dialogue Action` is an action that displays an animated message to the player with separate durations for typing and waiting. This action provides you with the ability to display a message with a specified speaker, text, typing duration, and wait duration.
 *
 * ## How could this be used?
 *
 * This action can be useful in a variety of situations. You can use it to create storylines with automatic progression, provide instructions to players that advance automatically, or create immersive roleplay experiences where dialogue continues after a set time. The possibilities are endless!
 */
class TimedDialogueEntry(
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
    val typingDuration: Var<Duration> = ConstVar(Duration.ZERO),
    @Help("The duration to wait after typing completes before automatically continuing.")
    val waitDuration: Var<Duration> = ConstVar(Duration.ZERO),
    @Help("Whether the confirmation key can be used to skip the dialogue. When enabled, first press completes typing, second press finishes.")
    @Default("true")
    val allowSkip: Var<Boolean> = ConstVar(true),
) : DialogueEntry {
    override fun messenger(player: Player, context: InteractionContext): DialogueMessenger<TimedDialogueEntry> {
        return if (player.isFloodgate) BedrockTimedDialogueDialogueMessenger(player, context, this)
        else JavaTimedDialogueDialogueMessenger(player, context, this)
    }
}

