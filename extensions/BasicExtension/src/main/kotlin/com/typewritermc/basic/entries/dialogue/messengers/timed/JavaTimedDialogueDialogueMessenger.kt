package com.typewritermc.basic.entries.dialogue.messengers.timed

import com.typewritermc.basic.entries.dialogue.TimedDialogueEntry
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.dialogue.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.*
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import java.time.Duration

val timedFormat: String by snippet(
    "dialogue.timed.format",
    """
		|<gray><st>${" ".repeat(60)}</st>
		|
		|<gray><padding>[ <bold><speaker></bold><reset><gray> ]
		|
		|<message>
		|
		|<gray><countdown_text>
		|<gray><st>${" ".repeat(60)}</st>
		""".trimMargin()
)

val timedCountdownWithSkip: String by snippet(
    "dialogue.timed.countdown.withSkip",
    "${" ".repeat(3)}Press<white> <confirmation_key> </white>to <skip_text>, or <continue_text> <seconds> <time_unit>"
)
val timedCountdownWithoutSkip: String by snippet(
    "dialogue.timed.countdown.withoutSkip",
    "${" ".repeat(13)}<continue_text> <seconds> <time_unit>"
)
val timedCountdownSkipText: String by snippet("dialogue.timed.countdown.skipText", "skip")
val timedCountdownContinueText: String by snippet("dialogue.timed.countdown.continueText", "Continuing in")
val timedCountdownTimeUnitSingular: String by snippet("dialogue.timed.countdown.timeUnit.singular", "second")
val timedCountdownTimeUnitPlural: String by snippet("dialogue.timed.countdown.timeUnit.plural", "seconds")
val timedPadding: String by snippet("dialogue.timed.padding", "    ")
val timedMinLines: Int by snippet("dialogue.timed.minLines", 3)
val timedMaxLineLength: Int by snippet("dialogue.timed.maxLineLength", 40)

class JavaTimedDialogueDialogueMessenger(player: Player, context: InteractionContext, entry: TimedDialogueEntry) :
    DialogueMessenger<TimedDialogueEntry>(player, context, entry) {
    private var confirmationKeyHandler: ConfirmationKeyHandler? = null

    private var speakerDisplayName = ""
    private var text = ""
    private var typingDuration = Duration.ZERO
    private var waitDuration = Duration.ZERO
    private var totalDuration = Duration.ZERO
    private var playedTime = Duration.ZERO

    override var animationComplete: Boolean
        get() = playedTime >= typingDuration
        set(value) {
            playedTime = if (!value) Duration.ZERO
            else typingDuration
        }

    override fun init() {
        super.init()
        speakerDisplayName = entry.speakerDisplayName.get(player).parsePlaceholders(player)
        text = entry.text.get(player).parsePlaceholders(player)
        typingDuration = typingDurationType.totalDuration(text.stripped(), entry.typingDuration.get(player))
        waitDuration = entry.waitDuration.get(player)
        totalDuration = typingDuration + waitDuration

        confirmationKeyHandler = confirmationKey.handler(player) {
            if (state != MessengerState.RUNNING) return@handler
            if (!entry.allowSkip.get(player, context)) return@handler
            completeOrFinish()
        }
    }

    override fun tick(context: TickContext) {
        if (state != MessengerState.RUNNING) return
        playedTime += context.deltaTime

        if (playedTime >= totalDuration) {
            state = MessengerState.FINISHED
            return
        }

        player.sendTimedDialogue(
            text,
            speakerDisplayName,
            entry.typingDuration.get(player),
            typingDuration,
            waitDuration,
            playedTime,
            entry.allowSkip.get(player, this.context)
        )
    }

    override fun dispose() {
        super.dispose()
        confirmationKeyHandler?.dispose()
        confirmationKeyHandler = null
    }
}

fun Player.sendTimedDialogue(
    text: String,
    speakerDisplayName: String,
    typingDurationConfig: Duration,
    typingDuration: Duration,
    waitDuration: Duration,
    playTime: Duration,
    allowSkip: Boolean
) {
    val rawText = text.stripped()

    val isTypingPhase = playTime < typingDuration
    val isWaitingPhase = playTime >= typingDuration && playTime < typingDuration + waitDuration

    val percentage = if (isTypingPhase) {
        typingDurationType.calculatePercentage(playTime, typingDurationConfig, rawText)
    } else {
        1.0
    }

    if (percentage > 1.1) {
        return
    }

    val remainingWaitTime = if (isWaitingPhase) {
        (typingDuration + waitDuration - playTime).toMillis()
    } else {
        0L
    }

    val remainingSeconds = kotlin.math.ceil(remainingWaitTime / 1000.0).toInt().coerceAtLeast(1)

    val countdownText = if (isTypingPhase) {
        ""
    } else if (isWaitingPhase) {
        val timeUnit = if (remainingSeconds == 1) timedCountdownTimeUnitSingular else timedCountdownTimeUnitPlural
        val countdownFormat = if (allowSkip) timedCountdownWithSkip else timedCountdownWithoutSkip
        countdownFormat.asMiniWithResolvers(
            Placeholder.parsed("skip_text", timedCountdownSkipText),
            Placeholder.parsed("continue_text", timedCountdownContinueText),
            Placeholder.parsed("seconds", remainingSeconds.toString()),
            Placeholder.parsed("time_unit", timeUnit)
        ).asMini()
    } else {
        ""
    }

    val resultingLines = rawText.limitLineLength(timedMaxLineLength).lineCount

    val message = if (isTypingPhase) {
        text.asPartialFormattedMini(
            percentage,
            padding = timedPadding,
            minLines = timedMinLines.coerceAtLeast(resultingLines),
            maxLineLength = timedMaxLineLength
        )
    } else {
        text.asPartialFormattedMini(
            1.0,
            padding = timedPadding,
            minLines = timedMinLines.coerceAtLeast(resultingLines),
            maxLineLength = timedMaxLineLength
        )
    }

    val component = timedFormat.asMiniWithResolvers(
        Placeholder.parsed("speaker", speakerDisplayName),
        Placeholder.component("message", message),
        Placeholder.parsed("countdown_text", countdownText),
        Placeholder.parsed("padding", timedPadding)
    )

    val componentWithDarkMessages = chatHistory.composeDarkMessage(component)
    sendMessage(componentWithDarkMessages)
}

