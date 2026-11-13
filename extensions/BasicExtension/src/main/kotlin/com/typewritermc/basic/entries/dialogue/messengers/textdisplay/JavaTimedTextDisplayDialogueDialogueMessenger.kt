package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.basic.entries.dialogue.TimedTextDisplayDialogueEntry
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.dialogue.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.Confirmation
import com.typewritermc.engine.paper.interaction.awaitConfirmation
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import org.bukkit.event.player.PlayerRespawnEvent
import org.bukkit.event.EventHandler
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

class JavaTimedTextDisplayDialogueDialogueMessenger(
    player: Player,
    context: InteractionContext,
    entry: TimedTextDisplayDialogueEntry,
) : DialogueMessenger<TimedTextDisplayDialogueEntry>(player, context, entry) {
    private var confirmation: Confirmation? = null
    private var display: TextDisplayDialogueDisplay? = null
    private lateinit var typewriter: TextDisplayTypewriter
    private var typingDurationConfig = Duration.ZERO
    private var typingDuration = Duration.ZERO
    private var totalDuration = Duration.ZERO
    private var playedTime = Duration.ZERO
    private var lastTypingPhase = true
    private var lastRemainingSeconds = -1
    private var lastCanSkip = false

    private val canSkip: Boolean
        get() = entry.allowSkip.get(player, context)

    override var animationComplete: Boolean
        get() {
            if (!canSkip) return state == MessengerState.FINISHED
            return playedTime >= typingDuration
        }
        set(value) {
            if (!canSkip) return
            playedTime = if (value) typingDuration else Duration.ZERO
        }

    @Synchronized
    override fun init() {
        super.init()
        val text = entry.text.get(player, context).parsePlaceholders(player)
        typewriter = TextDisplayTypewriter(text, player)
        typingDurationConfig = entry.typingDuration.get(player, context)
        typingDuration = typingDurationType.totalDuration(typewriter.rawText, typingDurationConfig)
            .coerceAtLeast(Duration.ZERO)
        totalDuration = typingDuration + entry.waitDuration.get(player, context).coerceAtLeast(Duration.ZERO)

        refreshConfirmation()
        display = TextDisplayDialogueDisplay(
            player,
            context,
            entry.origin,
            entry.orientation,
        ).also {
            it.spawn(displayText(true)!!)
        }
        refreshInstruction(true)
    }

    @Synchronized
    override fun tick(context: TickContext) {
        if (state != MessengerState.RUNNING) return

        val text = if (display?.isClosing == true) null else {
            if (display?.ready == true) playedTime += context.deltaTime
            refreshConfirmation()
            displayText().also {
                refreshInstruction()
            }
        }

        display?.tick(context.deltaTime, text)
        if (display?.invalid == true) {
            state = MessengerState.CANCELLED
            return
        }
        if (display?.ready == true && playedTime >= totalDuration) display?.close()
        if (display?.finished == true) state = MessengerState.FINISHED
    }

    @EventHandler
    @Synchronized
    private fun onPlayerRespawn(event: PlayerRespawnEvent) {
        if (event.player.uniqueId == player.uniqueId) state = MessengerState.CANCELLED
    }

    @Synchronized
    override fun dispose() {
        super.dispose()
        confirmation?.dispose()
        confirmation = null
        display?.dispose()
        display = null
    }

    private fun refreshConfirmation() {
        if (canSkip == (confirmation != null)) return
        if (!canSkip) {
            confirmation?.dispose()
            confirmation = null
            return
        }
        confirmation = player.awaitConfirmation {
            synchronized(this) {
                if (state != MessengerState.RUNNING || !canSkip || display?.isClosing == true) return@awaitConfirmation
                if (animationComplete) display?.close()
                else animationComplete = true
            }
        }
    }

    private fun displayText(force: Boolean = false): Component? {
        val percentage = if (typingDuration.toMillis() <= 0) {
            1.0
        } else {
            typingDurationType.calculatePercentage(playedTime, typingDurationConfig, typewriter.rawText)
        }
        return typewriter.render(timedTextDisplayFormat, percentage, force)
    }

    private fun refreshInstruction(force: Boolean = false) {
        val typingPhase = playedTime < typingDuration
        val remainingSeconds = if (typingPhase) -1 else remainingSeconds()
        val canSkip = confirmation != null
        if (!force &&
            typingPhase == lastTypingPhase &&
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
        val remainingMillis = (totalDuration - playedTime).toMillis().coerceAtLeast(0)
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
