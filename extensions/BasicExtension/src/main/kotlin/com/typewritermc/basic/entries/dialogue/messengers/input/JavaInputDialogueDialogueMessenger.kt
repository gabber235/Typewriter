package com.typewritermc.basic.entries.dialogue.messengers.input

import com.typewritermc.basic.entries.dialogue.InputDialogueEntry
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.dialogue.typingDurationType
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.*
import io.papermc.paper.event.player.AsyncChatEvent
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import java.time.Duration

val inputFormat: String by snippet(
    "dialogue.input.format", """
	|<gray><st>${" ".repeat(60)}</st>
    |
    |<gray><padding>[ <bold><speaker></bold><reset><gray> ]
    |
    |<message>
    |
    |<gray><info_padding><info_text>
	|<gray><st>${" ".repeat(60)}</st>
""".trimMargin()
)

val inputInfoText: String by snippet("dialogue.input.info", "Type answer in chat")

val inputPadding: String by snippet("dialogue.input.padding", "    ")
val inputMinLength: Int by snippet("dialogue.input.minLength", 1)
val inputMaxLineLength: Int by snippet("dialogue.input.maxLineLength", 40)

class JavaInputDialogueDialogueMessenger<T : Any>(
    player: Player,
    context: InteractionContext,
    entry: InputDialogueEntry,
    private val key: EntryContextKey,
    private val parser: (String) -> Result<T>,
    private val triggers: (T?) -> List<EventTrigger>,
) :
    DialogueMessenger<InputDialogueEntry>(player, context, entry) {

    private var speakerDisplayName = ""
    private var text = ""
    private var infoText = ""
    private var typingDuration = Duration.ZERO
    private var playedTime = Duration.ZERO

    override val eventTriggers: List<EventTrigger>
        get() {
            val value = context.get<T>(entry, key)
            return triggers(value)
        }

    override var isCompleted: Boolean
        // We don't want to be able to complete the dialogue if the player clicks on a npc.
        get() {
            if (!infoText.startsWith("<red>")) {
                infoText = "<red>$infoText"
            }
            return state == MessengerState.FINISHED
        }
        set(value) {
            playedTime = if (!value) Duration.ZERO
            else typingDuration
        }

    override fun init() {
        super.init()

        speakerDisplayName = entry.speakerDisplayName.get(player).parsePlaceholders(player)
        text = entry.text.get(player).parsePlaceholders(player)
        infoText = inputInfoText
        typingDuration = typingDurationType.totalDuration(text.stripped(), entry.duration.get(player))
    }

    @EventHandler(priority = EventPriority.LOW)
    private fun onPlayerChat(event: AsyncChatEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        event.isCancelled = true
        val message = event.message().plainText()
        val result = parser(message)
        if (result.isFailure) {
            infoText = result.exceptionOrNull()?.message ?: "<red>Invalid input"
            player.sendInputDialogue()
            return
        }

        val value = result.getOrNull() ?: return
        context[entry, key] = value
        state = MessengerState.FINISHED
    }

    private val percentage: Double
        get() = if (!typingDuration.isZero) playedTime.toMillis().toDouble() / typingDuration.toMillis() else 1.2

    override fun tick(context: TickContext) {
        if (state != MessengerState.RUNNING) return
        playedTime += context.deltaTime

        val playedTicks = playedTime.toTicks()

        // When the messages is send we don't want to keep sending the message every tick.
        // However, we only start reducing after the message has been displayed fully.
        if (percentage > 1.1) {
            // Change in highlight color
            val shouldDisplay = playedTicks % 50 == 0L
            if (!shouldDisplay) return
        }

        player.sendInputDialogue()
    }

    private fun Player.sendInputDialogue() {
        val rawText = text.stripped()
        val resultingLines = rawText.limitLineLength(inputMaxLineLength).lineCount

        val message = text.asPartialFormattedMini(
            percentage,
            padding = inputPadding,
            minLines = inputMinLength.coerceAtLeast(resultingLines),
            maxLineLength = inputMaxLineLength
        )

        val charactersLeft = (50 - infoText.stripped().length).coerceAtLeast(0)
        val charactersPadding = charactersLeft / 2

        val component = inputFormat.asMiniWithResolvers(
            Placeholder.parsed("speaker", speakerDisplayName),
            Placeholder.component("message", message),
            Placeholder.parsed("info_text", infoText),
            Placeholder.unparsed("info_padding", " ".repeat(charactersPadding)),
            Placeholder.parsed("padding", inputPadding)
        )

        val componentWithDarkMessages = chatHistory.composeDarkMessage(component)
        sendMessage(componentWithDarkMessages)
    }
}