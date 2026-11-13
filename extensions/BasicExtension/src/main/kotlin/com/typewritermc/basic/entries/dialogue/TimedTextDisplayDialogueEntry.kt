package com.typewritermc.basic.entries.dialogue

import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.BedrockTimedTextDisplayDialogueDialogueMessenger
import com.typewritermc.basic.entries.dialogue.messengers.textdisplay.JavaTimedTextDisplayDialogueDialogueMessenger
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
    "timed_text_display_dialogue",
    "A timed in-world dialogue",
    "#FF9800",
    "mingcute:sandglass-fill"
)
/**
 * Displays timed dialogue at a position in the world.
 *
 * [origin] can be a fixed position or a position variable, such as an NPC's location.
 */
class TimedTextDisplayDialogueEntry(
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
    @Help("The duration it takes to type out the message. Zero displays the message instantly.")
    val typingDuration: Var<Duration> = ConstVar(Duration.ZERO),
    @Help("The duration to wait after typing completes before automatically continuing.")
    val waitDuration: Var<Duration> = ConstVar(Duration.ZERO),
    @Help("Whether the confirmation key can complete typing or skip the remaining wait.")
    @Default("true")
    val allowSkip: Var<Boolean> = ConstVar(true),
) : DialogueEntry {
    override fun messenger(
        player: Player,
        context: InteractionContext,
    ): DialogueMessenger<TimedTextDisplayDialogueEntry> {
        return if (player.isFloodgate) BedrockTimedTextDisplayDialogueDialogueMessenger(player, context, this)
        else JavaTimedTextDisplayDialogueDialogueMessenger(player, context, this)
    }
}
