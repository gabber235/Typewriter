package com.typewritermc.basic.entries.dialogue.messengers.input

import com.typewritermc.basic.entries.dialogue.InputDialogueEntry
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.InteractionBoundState
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.boundState
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.legacy
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import org.geysermc.cumulus.form.CustomForm

private val inputTitle: String by snippet("dialogue.input.bedrock.title", "<bold><speaker></bold>")
private val inputContent: String by snippet("dialogue.input.bedrock.content", "<message>\n\n")
private val inputField: String by snippet("dialogue.input.bedrock.field", "Value")

class BedrockInputDialogueDialogueMessenger<T : Any>(
    player: Player,
    context: InteractionContext,
    entry: InputDialogueEntry,
    private val key: EntryContextKey,
    private val parser: (String) -> Result<T>,
    private val triggers: (T?) -> List<EventTrigger>,
) : DialogueMessenger<InputDialogueEntry>(player, context, entry) {

    override fun init() {
        super.init()
        sendForm()
    }

    override val eventTriggers: List<EventTrigger>
        get() {
            val value = context.get<T>(entry, key)
            return triggers(value)
        }

    private fun sendForm() {
        org.geysermc.floodgate.api.FloodgateApi.getInstance().sendForm(
            player.uniqueId,
            CustomForm.builder()
                .title(
                    inputTitle.parsePlaceholders(player).legacy(
                        Placeholder.parsed("speaker", entry.speakerDisplayName.get(player).parsePlaceholders(player))
                    )
                )
                .label(
                    inputContent.parsePlaceholders(player).legacy(
                        Placeholder.parsed("message", entry.text.get(player).parsePlaceholders(player))
                    )
                )
                .input(inputField.parsePlaceholders(player).legacy())
                .closedOrInvalidResultHandler { _, _ ->
                    when (player.boundState) {
                        InteractionBoundState.BLOCKING -> sendForm()
                        else -> state = MessengerState.CANCELLED
                    }
                }
                .validResultHandler { _, response ->
                    val input = response.asInput()
                    if (input == null) {
                        sendForm()
                        return@validResultHandler
                    }
                    val value = parser(input)
                    if (value.isFailure) {
                        sendForm()
                        return@validResultHandler
                    }
                    val data = value.getOrNull() ?: return@validResultHandler
                    context[entry, key] = data
                    state = MessengerState.FINISHED
                }
        )
    }
}