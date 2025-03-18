package com.typewritermc.basic.entries.dialogue.messengers.option

import com.typewritermc.basic.entries.dialogue.Option
import com.typewritermc.basic.entries.dialogue.OptionContextKeys
import com.typewritermc.basic.entries.dialogue.OptionDialogueEntry
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.around
import com.typewritermc.core.utils.loopingDistance
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.dialogue.*
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.matches
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.*
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.JoinConfiguration
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.player.PlayerItemHeldEvent
import java.time.Duration
import kotlin.math.min

val optionFormat: String by snippet(
    "dialogue.option.format", """
			|<gray><st>${" ".repeat(60)}</st>
			|<white> <speaker><reset>: <text>
			|
			|<options>
			|<#5d6c78>[ <grey><white>Scroll</white> to change option and press<white> <confirmation_key> </white>to select <#5d6c78>]</#5d6c78>
			|<gray><st>${" ".repeat(60)}</st>
		""".trimMargin()
)

private val selectedPrefix: String by snippet("dialogue.option.prefix.selected", "<#78ff85>>>")
private val upPrefix: String by snippet("dialogue.option.prefix.up", "<white> ↑")
private val downPrefix: String by snippet("dialogue.option.prefix.down", "<white> ↓")
private val unselectedPrefix: String by snippet("dialogue.option.prefix.unselected", "  ")

private val selectedOption: String by snippet(
    "dialogue.option.selected",
    " <prefix> <#5d6c78>[ <white><option_text> <#5d6c78>]\n"
)
private val unselectedOption: String by snippet(
    "dialogue.option.unselected",
    " <prefix> <#5d6c78>[ <grey><option_text> <#5d6c78>]\n"
)

val optionMaxLineLength: Int by snippet("dialogue.option.maxLineLength", 40)

private val delayOptionShow: Int by snippet(
    "dialogue.option.delay",
    100,
    "The delay in milliseconds between each option being shown."
)

class JavaOptionDialogueDialogueMessenger(player: Player, context: InteractionContext, entry: OptionDialogueEntry) :
    DialogueMessenger<OptionDialogueEntry>(player, context, entry) {

    private var confirmationKeyHandler: ConfirmationKeyHandler? = null

    private val typeDuration = entry.duration.get(player)

    private var selectedIndex = 0
        set(value) {
            field = value

            // 1-based index
            this.context[entry, OptionContextKeys.SELECTED_OPTION] = value + 1
        }
    private val selected get() = usableOptions.getOrNull(selectedIndex)

    private var usableOptions: List<Option> = emptyList()
    private var speakerDisplayName = ""
    private var parsedText = ""
    private var playTime = Duration.ZERO
    private var totalDuration = Duration.ZERO

    private var completedAnimation = false

    override val eventTriggers: List<EventTrigger>
        get() = entry.eventTriggers + (selected?.eventTriggers ?: emptyList())

    override val modifiers: List<Modifier>
        get() = entry.modifiers + (selected?.modifiers ?: emptyList())

    override var isCompleted: Boolean
        get() = playTime >= totalDuration
        set(value) {
            playTime = if (!value) Duration.ZERO
            else totalDuration
        }

    override fun init() {
        usableOptions =
            entry.options.filter { it.criteria.matches(player, context) }

        speakerDisplayName = entry.speakerDisplayName.get(player).parsePlaceholders(player)
        parsedText = entry.text.get(player).parsePlaceholders(player)

        val rawText = parsedText.stripped()
        val typingDuration = typingDurationType.totalDuration(rawText, typeDuration)
        val optionsShowingDuration = Duration.ofMillis(usableOptions.size * delayOptionShow.toLong())
        totalDuration = typingDuration + optionsShowingDuration

        super.init()
        confirmationKeyHandler = confirmationKey.handler(player) {
            completeOrFinish()
        }
    }

    @EventHandler
    private fun onPlayerItemHeld(event: PlayerItemHeldEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        val curSlot = event.previousSlot
        val newSlot = event.newSlot
        val dif = loopingDistance(curSlot, newSlot, 8)
        val index = selectedIndex
        event.isCancelled = true
        var newIndex = (index + dif) % usableOptions.size
        while (newIndex < 0) newIndex += usableOptions.size
        selectedIndex = newIndex
        displayMessage(playTime)
    }

    override fun tick(context: TickContext) {
        super.tick(context)
        val isFirst = playTime == Duration.ZERO
        playTime += context.deltaTime
        if (state != MessengerState.RUNNING) return

        var forceSend = false

        val newOptions =
            entry.options.filter { it.criteria.matches(player, this.context) }

        if (newOptions != usableOptions) {
            usableOptions = newOptions
            selectedIndex = 0
            forceSend = true
        }

        // When there are no options, just go to the next dialogue
        if (usableOptions.isEmpty()) {
            isCompleted = true
            state = MessengerState.FINISHED
            return
        }

        if (playTime.toTicks() % 100 > 0 && completedAnimation && !isFirst && !forceSend) {
            // Only update periodically to avoid spamming the player
            return
        }
        displayMessage(playTime)
    }

    private fun displayMessage(playTime: Duration) {
        val rawText = parsedText.stripped()

        val typePercentage =
            if (typeDuration.isZero) {
                1.0
            } else typingDurationType.calculatePercentage(playTime, typeDuration, rawText)

        val resultingLines = rawText.limitLineLength(optionMaxLineLength).lineCount
        val text = parsedText.asPartialFormattedMini(
            typePercentage,
            minLines = resultingLines,
            padding = "",
            maxLineLength = optionMaxLineLength
        )

        val message = optionFormat.asMiniWithResolvers(
            Placeholder.parsed("speaker", speakerDisplayName),
            Placeholder.component("text", text),
            Placeholder.component("options", formatOptions(rawText)),
        )

        val component = player.chatHistory.composeDarkMessage(message)
        player.sendMessage(component)
    }

    private fun formatOptions(rawText: String): Component {
        val around = usableOptions.around(selectedIndex, 1, 2)

        val lines = mutableListOf<Component>()

        val typingDuration = typingDurationType.totalDuration(rawText, typeDuration)
        val timeAfterTyping = playTime - typingDuration
        val limitedOptions = (timeAfterTyping.toMillis() / delayOptionShow).toInt().coerceAtLeast(0)

        val maxOptions = min(4, around.size)
        val showingOptions = min(maxOptions, limitedOptions)

        completedAnimation = maxOptions == showingOptions

        for (i in 0 until showingOptions) {
            val option = around[i]
            val isSelected = selected == option

            val prefix = if (isSelected) selectedPrefix
            else if (i == 0 && selectedIndex > 1 && usableOptions.size > 4) upPrefix
            else if (i == 3 && selectedIndex < usableOptions.size - 3 && usableOptions.size > 4) downPrefix
            else unselectedPrefix

            val format = if (isSelected) selectedOption else unselectedOption
            lines += format.asMiniWithResolvers(
                Placeholder.parsed("prefix", prefix),
                Placeholder.parsed("option_text", option.text.get(player).parsePlaceholders(player))
            )
        }

        for (i in showingOptions until maxOptions) {
            lines += Component.text(" \n")
        }

        return Component.join(JoinConfiguration.noSeparators(), lines)
    }

    override fun dispose() {
        super.dispose()
        confirmationKeyHandler?.dispose()
        confirmationKeyHandler = null
    }
}