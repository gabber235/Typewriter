package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.basic.entries.dialogue.Option
import com.typewritermc.basic.entries.dialogue.OptionContextKeys
import com.typewritermc.basic.entries.dialogue.OptionTextDisplayDialogueEntry
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

private val optionTextDisplayTitle: String by snippet(
    "dialogue.textDisplay.option.bedrock.title",
    "<bold><speaker></bold>",
)
private val optionTextDisplayDescription: String by snippet(
    "dialogue.textDisplay.option.bedrock.description",
    "<message>\n\n",
)
private val optionTextDisplaySelect: String by snippet(
    "dialogue.textDisplay.option.bedrock.select",
    "Select Response",
)

class BedrockOptionTextDisplayDialogueDialogueMessenger(
    player: Player,
    context: InteractionContext,
    entry: OptionTextDisplayDialogueEntry,
) : DialogueMessenger<OptionTextDisplayDialogueEntry>(player, context, entry) {
    private var usableOptions: List<Option> = emptyList()
    private var selectedIndex = 0
        set(value) {
            field = value
            context[entry, OptionContextKeys.SELECTED_OPTION] = value + 1
        }
    private val selected: Option?
        get() = usableOptions.getOrNull(selectedIndex)

    override val eventTriggers: List<EventTrigger>
        get() = entry.eventTriggers + (selected?.eventTriggers ?: emptyList())

    override val modifiers: List<Modifier>
        get() = entry.modifiers + (selected?.modifiers ?: emptyList())

    override fun init() {
        super.init()
        sendForm()
    }

    private fun sendForm() {
        if (state != MessengerState.RUNNING) return
        usableOptions = entry.options.filter { it.criteria.matches(player, context) }
        if (usableOptions.isEmpty()) {
            state = MessengerState.FINISHED
            return
        }

        org.geysermc.floodgate.api.FloodgateApi.getInstance().sendForm(
            player.uniqueId,
            org.geysermc.cumulus.form.CustomForm.builder()
                .title(
                    optionTextDisplayTitle.parsePlaceholders(player).legacy(
                        Placeholder.parsed(
                            "speaker",
                            entry.speakerDisplayName.get(player, context).parsePlaceholders(player),
                        )
                    )
                )
                .label(
                    optionTextDisplayDescription.parsePlaceholders(player).legacy(
                        Placeholder.parsed("message", entry.text.get(player, context).parsePlaceholders(player))
                    )
                )
                .dropdown(
                    optionTextDisplaySelect.parsePlaceholders(player).legacy(),
                    usableOptions.map { it.text.get(player, context).parsePlaceholders(player).legacy() },
                )
                .label("\n\n\n\n")
                .closedOrInvalidResultHandler { _, _ ->
                    if (state != MessengerState.RUNNING) return@closedOrInvalidResultHandler
                    when (player.boundState) {
                        InteractionBoundState.BLOCKING -> sendForm()
                        else -> state = MessengerState.CANCELLED
                    }
                }
                .validResultHandler { response ->
                    if (state != MessengerState.RUNNING) return@validResultHandler
                    val option = usableOptions.getOrNull(response.asDropdown()) ?: return@validResultHandler
                    if (!option.criteria.matches(player, context)) {
                        sendForm()
                        return@validResultHandler
                    }
                    selectedIndex = response.asDropdown()
                    state = MessengerState.FINISHED
                }
        )
    }
}
