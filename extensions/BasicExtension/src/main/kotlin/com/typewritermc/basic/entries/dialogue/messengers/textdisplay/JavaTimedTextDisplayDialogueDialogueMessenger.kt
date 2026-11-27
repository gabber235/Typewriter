package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.basic.entries.dialogue.TimedTextDisplayDialogueEntry
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import org.bukkit.event.EventHandler
import org.bukkit.entity.Player
import org.bukkit.event.player.PlayerRespawnEvent
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
) : DialogueMessenger<TimedTextDisplayDialogueEntry>(player, context, entry) {
    private val playback = TextDisplayDialoguePlayback(player, context, entry.origin, entry.orientation, timedTextDisplayFormat)

    override var animationComplete: Boolean
        get() = entry.allowSkip.get(player, context) && playback.animationComplete
        set(value) = playback.requestAnimationCompletion(value)

    @EventHandler
    private fun onPlayerRespawn(event: PlayerRespawnEvent) {
        if (event.player.uniqueId == player.uniqueId) playback.playerRespawned()
    }

    override fun dispose() {
        super.dispose()
        playback.dispose()
    }

    private var completionTime: Duration = Duration.ZERO
    private var lastTypingPhase = true
    private var lastRemainingSeconds = -1
    private var lastCanSkip = false

    override fun init() {
        super.init()
        playback.prepare(entry.text.get(player, context), entry.typingDuration.get(player, context))
        completionTime = playback.typingDuration + entry.waitDuration.get(player, context).coerceAtLeast(Duration.ZERO)
        val canSkip = entry.allowSkip.get(player, context)
        refreshInstruction(canSkip)
        state = playback.spawn(entry.id, canSkip, playback.typingDuration)
    }

    override fun tick(context: TickContext) {
        if (state != MessengerState.RUNNING) return
        val canSkip = entry.allowSkip.get(player, this.context)
        state = playback.tick(context, canConfirm = canSkip, autoContinueAt = completionTime) {
            refreshInstruction(canSkip)
        }
    }

    private fun refreshInstruction(canSkip: Boolean) {
        val typingPhase = playback.playedTime < playback.typingDuration
        val remainingSeconds = if (typingPhase) -1 else remainingSeconds()
        if (typingPhase == lastTypingPhase &&
            remainingSeconds == lastRemainingSeconds &&
            canSkip == lastCanSkip
        ) {
            return
        }

        lastTypingPhase = typingPhase
        lastRemainingSeconds = remainingSeconds
        lastCanSkip = canSkip
        playback.display.setInstruction(instruction(typingPhase, remainingSeconds, canSkip))
    }

    private fun remainingSeconds(): Int {
        val remainingMillis = (completionTime - playback.playedTime).toMillis().coerceAtLeast(0)
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
