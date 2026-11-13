package com.typewritermc.basic.entries.dialogue

import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.BedrockOptionTextDisplayDialogueDialogueMessenger
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.JavaOptionTextDisplayDialogueDialogueMessenger
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.TextDisplayOrientation
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.isFloodgate
import org.bukkit.entity.Player
import java.time.Duration

@Entry(
    "option_text_display_dialogue",
    "An in-world dialogue with options",
    "#4CAF50",
    "fa6-solid:list"
)
@ContextKeys(OptionContextKeys::class)
/**
 * Displays selectable dialogue options at a dynamic position.
 *
 * Use this when a player should scroll through responses in the world instead of choosing from chat. The display
 * follows [origin] as it changes.
 */
class OptionTextDisplayDialogueEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    override val speaker: Ref<SpeakerEntry> = emptyRef(),
    @Help("The position where the dialogue display appears.")
    val origin: Var<Position> = ConstVar(Position.ORIGIN),
    @Help("Billboard faces the player. Fixed uses the origin's yaw and pitch.")
    val orientation: TextDisplayOrientation = TextDisplayOrientation.BILLBOARD,
    @Placeholder
    @Colored
    @MultiLine
    val text: Var<String> = ConstVar(""),
    val options: List<Option> = emptyList(),
    @Help("The duration it takes to type out the message.")
    val duration: Var<Duration> = ConstVar(Duration.ZERO),
) : DialogueEntry {
    override fun messenger(
        player: Player,
        context: InteractionContext,
    ): DialogueMessenger<OptionTextDisplayDialogueEntry> {
        return if (player.isFloodgate) BedrockOptionTextDisplayDialogueDialogueMessenger(player, context, this)
        else JavaOptionTextDisplayDialogueDialogueMessenger(player, context, this)
    }
}
