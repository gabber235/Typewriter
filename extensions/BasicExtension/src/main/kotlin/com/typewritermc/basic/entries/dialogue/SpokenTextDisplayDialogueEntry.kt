package com.typewritermc.basic.entries.dialogue

import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.BedrockSpokenTextDisplayDialogueDialogueMessenger
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.JavaSpokenTextDisplayDialogueDialogueMessenger
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
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.DialogueEntry
import com.typewritermc.engine.paper.entry.entries.SpeakerEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.isFloodgate
import org.bukkit.entity.Player
import java.time.Duration

@Entry(
    "spoken_text_display_dialogue",
    "An in-world spoken dialogue",
    "#1E88E5",
    "material-symbols:text-ad-rounded"
)
/**
 * Displays spoken dialogue at a dynamic position until the player confirms it.
 *
 * Use a position variable such as an NPC origin when the dialogue should follow something that moves.
 */
class SpokenTextDisplayDialogueEntry(
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
    @Help("The duration it takes to type out the message.")
    val duration: Var<Duration> = ConstVar(Duration.ZERO),
) : DialogueEntry {
    override fun messenger(
        player: Player,
        context: InteractionContext,
    ): DialogueMessenger<SpokenTextDisplayDialogueEntry> {
        return if (player.isFloodgate) BedrockSpokenTextDisplayDialogueDialogueMessenger(player, context, this)
        else JavaSpokenTextDisplayDialogueDialogueMessenger(player, context, this)
    }
}
