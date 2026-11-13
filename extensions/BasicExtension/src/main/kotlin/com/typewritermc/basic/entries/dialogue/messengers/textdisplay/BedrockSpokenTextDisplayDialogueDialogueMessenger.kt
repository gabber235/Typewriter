package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.basic.entries.dialogue.SpokenTextDisplayDialogueEntry
import com.typewritermc.basic.entries.dialogue.messengers.sendDialogueForm
import com.typewritermc.core.interaction.InteractionBoundState
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.boundState
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.legacy
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player

private val spokenTextDisplayTitle: String by snippet(
    "dialogue.textDisplay.spoken.bedrock.title",
    "<bold><speaker></bold>",
)
private val spokenTextDisplayContent: String by snippet(
    "dialogue.textDisplay.spoken.bedrock.content",
    "<message>\n\n",
)
private val spokenTextDisplayButton: String by snippet(
    "dialogue.textDisplay.spoken.bedrock.button",
    "Continue",
)

class BedrockSpokenTextDisplayDialogueDialogueMessenger(
    player: Player,
    context: InteractionContext,
    entry: SpokenTextDisplayDialogueEntry,
) : DialogueMessenger<SpokenTextDisplayDialogueEntry>(player, context, entry) {
    override fun init() {
        super.init()
        sendForm()
    }

    private fun sendForm() {
        if (state != MessengerState.RUNNING) return
        player.sendDialogueForm(
            spokenTextDisplayTitle.parsePlaceholders(player).legacy(
                Placeholder.parsed("speaker", entry.speakerDisplayName.get(player, context).parsePlaceholders(player)),
            ),
            spokenTextDisplayContent.parsePlaceholders(player).legacy(
                Placeholder.parsed("message", entry.text.get(player, context).parsePlaceholders(player)),
            ),
            spokenTextDisplayButton.parsePlaceholders(player).legacy(),
            onClose = onClose@{
                if (state != MessengerState.RUNNING) return@onClose
                when (player.boundState) {
                    InteractionBoundState.BLOCKING -> sendForm()
                    else -> state = MessengerState.CANCELLED
                }
            },
            onConfirm = {
                if (state == MessengerState.RUNNING) state = MessengerState.FINISHED
            },
        )
    }
}
