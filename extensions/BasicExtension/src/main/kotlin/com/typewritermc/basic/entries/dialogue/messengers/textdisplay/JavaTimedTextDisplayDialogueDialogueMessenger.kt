package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.basic.entries.dialogue.TimedTextDisplayDialogueEntry
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import java.time.Duration
import kotlin.math.ceil

private val timedTextDisplayFormat: String by snippet(
    "dialogue.textDisplay.timed.bodyFormat",
    "<white> <message> </white>",
)
private val timedTextDisplayTypingWithSkip: String by snippet(
    "dialogue.textDisplay.timed.instruction.typing.withSkip",
    "<white><confirmation_key> to skip</white>",
)
private val timedTextDisplayTypingWithoutSkip: String by snippet(
    "dialogue.textDisplay.timed.instruction.typing.withoutSkip",
    " ",
)
private val timedTextDisplayWaitingWithSkip: String by snippet(
    "dialogue.textDisplay.timed.instruction.waiting.withSkip",
    "<white><confirmation_key> to skip  •  <seconds>s</white>",
)
private val timedTextDisplayWaitingWithoutSkip: String by snippet(
    "dialogue.textDisplay.timed.instruction.waiting.withoutSkip",
    "<white>Continuing in <seconds> <time_unit></white>",
)
private val timedTextDisplaySecond: String by snippet(
    "dialogue.textDisplay.timed.instruction.timeUnit.singular",
    "second",
)
private val timedTextDisplaySeconds: String by snippet(
    "dialogue.textDisplay.timed.instruction.timeUnit.plural",
    "seconds",
)

internal class JavaTimedTextDisplayDialogueDialogueMessenger(
    player: Player,
    context: InteractionContext,
    entry: TimedTextDisplayDialogueEntry,
) : JavaTextDisplayDialogueMessenger<TimedTextDisplayDialogueEntry>(
    player, context, entry, entry.text, entry.typingDuration, entry.origin, entry.orientation,
    timedTextDisplayFormat,
) {
    override val canConfirm: Boolean get() = entry.allowSkip.get(player, context)
    override val autoContinue: Boolean get() = true
    override var completionTime: Duration = Duration.ZERO
        private set
    private var lastTypingPhase = true
    private var lastRemainingSeconds = -1
    private var lastCanSkip = false

    override val animationEnd: Duration get() = typingDuration

    override fun prepareDialogue(): Boolean {
        completionTime = typingDuration + entry.waitDuration.get(player, context).coerceAtLeast(Duration.ZERO)
        return true
    }

    override fun updateDialogue() {
        refreshInstruction()
    }

    private fun refreshInstruction() {
        val typingPhase = playedTime < typingDuration
        val remainingSeconds = if (typingPhase) -1 else remainingSeconds()
        val canSkip = canConfirm
        if (typingPhase == lastTypingPhase &&
            remainingSeconds == lastRemainingSeconds &&
            canSkip == lastCanSkip
        ) {
            return
        }

        lastTypingPhase = typingPhase
        lastRemainingSeconds = remainingSeconds
        lastCanSkip = canSkip
        display?.setInstruction(instruction(typingPhase, remainingSeconds, canSkip))
    }

    private fun remainingSeconds(): Int {
        val remainingMillis = (completionTime - playedTime).toMillis().coerceAtLeast(0)
        return ceil(remainingMillis / 1000.0).toInt()
    }

    private fun instruction(typing: Boolean, seconds: Int, canSkip: Boolean): Component {
        val format = when {
            typing && canSkip -> timedTextDisplayTypingWithSkip
            typing -> timedTextDisplayTypingWithoutSkip
            seconds < 1 -> return Component.empty()
            canSkip -> timedTextDisplayWaitingWithSkip
            else -> timedTextDisplayWaitingWithoutSkip
        }
        val timeUnit = if (seconds == 1) timedTextDisplaySecond else timedTextDisplaySeconds
        return format.asMiniWithResolvers(
            player,
            Placeholder.parsed("seconds", seconds.toString()),
            Placeholder.parsed("time_unit", timeUnit),
        )
    }
}
