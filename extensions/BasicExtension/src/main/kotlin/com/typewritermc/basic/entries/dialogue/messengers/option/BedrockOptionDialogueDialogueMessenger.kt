package com.typewritermc.basic.entries.dialogue.messengers.option

import com.typewritermc.basic.entries.dialogue.Option
import com.typewritermc.basic.entries.dialogue.OptionDialogueEntry
import com.typewritermc.core.interaction.InteractionBoundState
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.dialogue.DialogueMessenger
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.matches
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.boundState
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.legacy
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player

private val optionTitle: String by snippet("dialogue.option.bedrock.title", "<bold><speaker></bold>")
private val optionDescription: String by snippet("dialogue.option.bedrock.description", "<message>\n\n\n>")
private val optionSelect: String by snippet("dialogue.option.bedrock.select", "Select Response")

class BedrockOptionDialogueDialogueMessenger(player: Player, context: InteractionContext, entry: OptionDialogueEntry) :
    DialogueMessenger<OptionDialogueEntry>(player, context, entry) {

    private var selectedIndex = 0
    private val selected get() = usableOptions[selectedIndex]

    private var usableOptions: List<Option> = emptyList()

    override val eventTriggers: List<EventTrigger>
        get() = entry.eventTriggers + selected.eventTriggers

    override val modifiers: List<Modifier>
        get() = entry.modifiers + selected.modifiers


    override fun init() {
        super.init()
        sendForm()
    }

    fun sendForm() {
        usableOptions = entry.options.filter { it.criteria.matches(player, context) }
        org.geysermc.floodgate.api.FloodgateApi.getInstance().sendForm(
            player.uniqueId,
            org.geysermc.cumulus.form.CustomForm.builder()
                .title(
                    optionTitle.parsePlaceholders(player).legacy(
                        Placeholder.parsed("speaker", entry.speakerDisplayName.get(player).parsePlaceholders(player))
                    )
                )
                .label(
                    optionDescription.parsePlaceholders(player).legacy(
                        Placeholder.parsed("message", entry.text.get(player).parsePlaceholders(player))
                    )
                )
                .dropdown(
                    optionSelect.parsePlaceholders(player).legacy(),
                    usableOptions.map { it.text.get(player).parsePlaceholders(player).legacy() })
                .label("\n\n\n\n")
                .closedOrInvalidResultHandler { _, _ ->
                    when (player.boundState) {
                        InteractionBoundState.BLOCKING -> sendForm()
                        else -> state = MessengerState.CANCELLED
                    }
                }
                .validResultHandler { responds ->
                    val dropdown = responds.asDropdown()
                    selectedIndex = dropdown
                    state = MessengerState.FINISHED
                }
        )
    }

    override fun end() {
        // Do nothing as we don't need to resend the messages.
    }
}