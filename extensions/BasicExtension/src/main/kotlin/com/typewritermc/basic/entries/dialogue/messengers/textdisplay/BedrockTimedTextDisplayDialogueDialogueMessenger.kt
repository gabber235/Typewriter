package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.basic.entries.dialogue.TimedTextDisplayDialogueEntry
import com.typewritermc.basic.entries.dialogue.messengers.sendDialogueForm
import com.typewritermc.core.interaction.InteractionBoundState
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.dialogue.typingDurationType
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.boundState
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.legacy
import com.typewritermc.engine.paper.utils.stripped
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import java.time.Duration

private val timedTextDisplayTitle: String by snippet(
    "dialogue.textDisplay.timed.bedrock.title",
    "<bold><speaker></bold>",
)
private val timedTextDisplayContent: String by snippet(
    "dialogue.textDisplay.timed.bedrock.content",
    "<message>\n\n",
)
private val timedTextDisplayButton: String by snippet(
    "dialogue.textDisplay.timed.bedrock.button",
    "Continue",
)

class BedrockTimedTextDisplayDialogueDialogueMessenger(
    player: Player,
    context: InteractionContext,
    entry: TimedTextDisplayDialogueEntry,
) : DialogueMessenger<TimedTextDisplayDialogueEntry>(player, context, entry) {
    private var playTime = Duration.ZERO
    private var totalDuration = Duration.ZERO

    override fun init() {
        super.init()
        val text = entry.text.get(player, context).parsePlaceholders(player).stripped()
        val typingDuration = typingDurationType.totalDuration(text, entry.typingDuration.get(player, context))
        totalDuration = typingDuration.coerceAtLeast(Duration.ZERO) +
            entry.waitDuration.get(player, context).coerceAtLeast(Duration.ZERO)
        sendForm()
    }

    override fun tick(context: TickContext) {
        if (state != MessengerState.RUNNING) return
        playTime += context.deltaTime
        if (playTime < totalDuration) return

        state = MessengerState.FINISHED
        org.geysermc.floodgate.api.FloodgateApi.getInstance().closeForm(player.uniqueId)
    }

    private fun sendForm() {
        if (state != MessengerState.RUNNING) return
        player.sendDialogueForm(
            timedTextDisplayTitle.parsePlaceholders(player).legacy(
                Placeholder.parsed("speaker", entry.speakerDisplayName.get(player, context).parsePlaceholders(player)),
            ),
            timedTextDisplayContent.parsePlaceholders(player).legacy(
                Placeholder.parsed("message", entry.text.get(player, context).parsePlaceholders(player)),
            ),
            timedTextDisplayButton.parsePlaceholders(player).legacy(),
            onClose = onClose@{
                if (state != MessengerState.RUNNING) return@onClose
                if (!entry.allowSkip.get(player, context)) {
                    sendForm()
                    return@onClose
                }
                when (player.boundState) {
                    InteractionBoundState.BLOCKING -> sendForm()
                    else -> state = MessengerState.CANCELLED
                }
            },
            onConfirm = onConfirm@{
                if (state != MessengerState.RUNNING) return@onConfirm
                if (entry.allowSkip.get(player, context)) state = MessengerState.FINISHED
                else sendForm()
            },
        )
    }
}
