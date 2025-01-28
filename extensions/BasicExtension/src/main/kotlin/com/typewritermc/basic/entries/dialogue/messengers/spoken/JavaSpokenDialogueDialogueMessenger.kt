package com.typewritermc.basic.entries.dialogue.messengers.spoken

import com.typewritermc.basic.entries.dialogue.SpokenDialogueEntry
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.dialogue.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.*
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import java.time.Duration

val spokenFormat: String by snippet(
    "dialogue.spoken.format",
    """
		|<gray><st>${" ".repeat(60)}</st>
		|
		|<gray><padding>[ <bold><speaker></bold><reset><gray> ]
		|
		|<message>
		|
		|<next_color>${" ".repeat(20)} Press<white> <confirmation_key> </white>to <finish_text>
		|<gray><st>${" ".repeat(60)}</st>
		""".trimMargin()
)

val spokenInstructionNextText: String by snippet("dialogue.spoken.instruction.next", "continue")
val spokenInstructionFinishText: String by snippet("dialogue.spoken.instruction.finish", "finish")
val spokenInstructionBaseColor: String by snippet("dialogue.spoken.instruction.color.base", "<gray>")
val spokenInstructionHighlightColor: String by snippet("dialogue.spoken.instruction.color.highlight", "<red>")
val spokenPadding: String by snippet("dialogue.spoken.padding", "    ")
val spokenMinLines: Int by snippet("dialogue.spoken.minLines", 3)
val spokenMaxLineLength: Int by snippet("dialogue.spoken.maxLineLength", 40)
val spokenInstructionTicksHighlighted: Long by snippet("dialogue.spoken.instruction.ticks.highlighted", 10)
val spokenInstructionTicksBase: Long by snippet("dialogue.spoken.instruction.ticks.base", 30)

class JavaSpokenDialogueDialogueMessenger(player: Player, context: InteractionContext, entry: SpokenDialogueEntry) :
    DialogueMessenger<SpokenDialogueEntry>(player, context, entry) {
    private var confirmationKeyHandler: ConfirmationKeyHandler? = null

    private var speakerDisplayName = ""
    private var text = ""
    private var typingDuration = Duration.ZERO
    private var playedTime = Duration.ZERO

    override var isCompleted: Boolean
        get() = playedTime >= typingDuration
        set(value) {
            playedTime = if (!value) Duration.ZERO
            else typingDuration
        }

    override fun init() {
        super.init()
        speakerDisplayName = entry.speakerDisplayName.get(player).parsePlaceholders(player)
        text = entry.text.get(player).parsePlaceholders(player)
        typingDuration = typingDurationType.totalDuration(text.stripped(), entry.duration.get(player))

        confirmationKeyHandler = confirmationKey.handler(player) {
            completeOrFinish()
        }
    }

    override fun tick(context: TickContext) {
        if (state != MessengerState.RUNNING) return
        playedTime += context.deltaTime
        player.sendSpokenDialogue(
            text,
            speakerDisplayName,
            entry.duration.get(player),
            playedTime,
            eventTriggers.isEmpty()
        )
    }

    override fun dispose() {
        super.dispose()
        confirmationKeyHandler?.dispose()
        confirmationKeyHandler = null
    }
}


fun Player.sendSpokenDialogue(
    text: String,
    speakerDisplayName: String,
    duration: Duration,
    playTime: Duration,
    canFinish: Boolean
) {
    val rawText = text.stripped()
    val playedTicks = playTime.toTicks()
    val durationInTicks = typingDurationType.totalDuration(rawText, duration).toTicks()

    val percentage = typingDurationType.calculatePercentage(playTime, duration, rawText)

    val totalInstructionDuration = spokenInstructionTicksHighlighted + spokenInstructionTicksBase
    val instructionCycle = playedTicks % totalInstructionDuration
    // When the messages is send we don't want to keep sending the message every tick.
    // However, we only start reducing after the message has been displayed fully.
    if (percentage > 1.1) {
        // Change in highlight color
        val shouldDisplay = instructionCycle == 0L || instructionCycle == spokenInstructionTicksHighlighted
        if (!shouldDisplay) return
    }

    val highlightStarted = playedTicks > durationInTicks * 2.5
    val needsHighlight = instructionCycle < spokenInstructionTicksHighlighted
    val nextColor =
        if (highlightStarted && needsHighlight) spokenInstructionHighlightColor else spokenInstructionBaseColor

    val continueOrFinish = if (canFinish) spokenInstructionFinishText else spokenInstructionNextText

    val resultingLines = rawText.limitLineLength(spokenMaxLineLength).lineCount

    val message = text.asPartialFormattedMini(
        percentage,
        padding = spokenPadding,
        minLines = spokenMinLines.coerceAtLeast(resultingLines),
        maxLineLength = spokenMaxLineLength
    )

    val component = spokenFormat.asMiniWithResolvers(
        Placeholder.parsed("speaker", speakerDisplayName),
        Placeholder.component("message", message),
        Placeholder.parsed("next_color", nextColor),
        Placeholder.parsed("finish_text", continueOrFinish),
        Placeholder.parsed("padding", spokenPadding)
    )

    val componentWithDarkMessages = chatHistory.composeDarkMessage(component)
    sendMessage(componentWithDarkMessages)
}