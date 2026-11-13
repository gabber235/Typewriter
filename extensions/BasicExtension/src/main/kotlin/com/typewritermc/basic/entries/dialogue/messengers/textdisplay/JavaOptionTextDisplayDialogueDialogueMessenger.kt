package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.basic.entries.dialogue.Option
import com.typewritermc.basic.entries.dialogue.OptionContextKeys
import com.typewritermc.basic.entries.dialogue.OptionTextDisplayDialogueEntry
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.around
import com.typewritermc.core.utils.loopingDistance
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.matches
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import com.typewritermc.engine.paper.utils.limitLineLength
import com.typewritermc.engine.paper.utils.lineCount
import com.typewritermc.engine.paper.utils.stripped
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.player.PlayerItemHeldEvent
import com.typewritermc.engine.paper.entry.dialogue.MessengerState
import java.time.Duration
import java.util.concurrent.atomic.AtomicInteger
import kotlin.math.min

private val optionTextDisplayFormat: String by snippet(
    "dialogue.textDisplay.option.bodyFormat",
    "<white> <message> </white>",
)
private val selectedTextDisplayOption: String by snippet(
    "dialogue.textDisplay.option.row.selected",
    "<white><prefix> <option_text>",
)
private val unselectedTextDisplayOption: String by snippet(
    "dialogue.textDisplay.option.row.unselected",
    "<dark_gray><prefix> <gray><option_text>",
)
private val selectedTextDisplayPrefix: String by snippet("dialogue.textDisplay.option.prefix.selected", "›")
private val upTextDisplayPrefix: String by snippet("dialogue.textDisplay.option.prefix.up", "↑")
private val downTextDisplayPrefix: String by snippet("dialogue.textDisplay.option.prefix.down", "↓")
private val unselectedTextDisplayPrefix: String by snippet("dialogue.textDisplay.option.prefix.unselected", " ")
private val optionTextDisplayInstruction: String by snippet(
    "dialogue.textDisplay.option.instruction",
    "<white>Scroll to choose  •  <confirmation_key> to select</white>",
)
private val textDisplayOptionDelay: Int by snippet(
    "dialogue.textDisplay.option.delay",
    0,
    "The delay in milliseconds between each option being shown.",
)
private const val MAX_VISIBLE_OPTIONS = 4

internal class JavaOptionTextDisplayDialogueDialogueMessenger(
    player: Player,
    context: InteractionContext,
    entry: OptionTextDisplayDialogueEntry,
) : JavaTextDisplayDialogueMessenger<OptionTextDisplayDialogueEntry>(
    player, context, entry, entry.text, entry.duration, entry.origin, entry.orientation,
    optionTextDisplayFormat,
) {
    private val scrolledSlots = AtomicInteger()
    @Volatile
    private var acceptingScroll = false
    override var completionTime: Duration = Duration.ZERO
        private set
    private var usableOptions: List<Option> = emptyList()
    private val hasOptionCriteria = entry.options.any { it.criteria.isNotEmpty() }
    private var selectedIndex = 0
        set(value) {
            field = value
            context[entry, OptionContextKeys.SELECTED_OPTION] = value + 1
        }
    private val selected: Option?
        get() = usableOptions.getOrNull(selectedIndex)
    private var lastShowingOptions = -1
    private var optionLines = 1

    override val eventTriggers: List<EventTrigger>
        get() = entry.eventTriggers + (selected?.eventTriggers ?: emptyList())

    override val modifiers: List<Modifier>
        get() = entry.modifiers + (selected?.modifiers ?: emptyList())

    override fun prepareDialogue(): Boolean {
        usableOptions = entry.options.filter { it.criteria.matches(player, context) }
        if (usableOptions.isEmpty()) {
            state = MessengerState.FINISHED
            return false
        }
        selectedIndex = 0
        updateTotalDuration()
        updateOptionLines()
        acceptingScroll = true
        return true
    }

    @EventHandler
    private fun onPlayerItemHeld(event: PlayerItemHeldEvent) {
        if (event.player.uniqueId != player.uniqueId || !acceptingScroll) return
        event.isCancelled = true
        scrolledSlots.addAndGet(loopingDistance(event.previousSlot, event.newSlot, 8))
    }

    override fun prepareDisplay(display: TextDisplayDialogueDisplay) {
        display.setInstruction(optionTextDisplayInstruction.asMiniWithResolvers(player))
    }

    override fun updateDialogue() {
        refreshOptions()
        if (state != MessengerState.RUNNING) return
        val distance = scrolledSlots.getAndSet(0)
        if (distance != 0) {
            val index = (selectedIndex + distance).mod(usableOptions.size)
            if (index != selectedIndex) {
                selectedIndex = index
                lastShowingOptions = -1
            }
        }
        refreshDisplayedOptions()
    }

    override fun stopInput() {
        acceptingScroll = false
    }

    private fun refreshOptions() {
        if (!hasOptionCriteria) return
        val options = entry.options.filter { it.criteria.matches(player, context) }
        if (options == usableOptions) return
        val previousSelection = selected
        usableOptions = options
        if (usableOptions.isEmpty()) {
            state = MessengerState.FINISHED
            return
        }
        selectedIndex = usableOptions.indexOf(previousSelection).coerceAtLeast(0)
        updateTotalDuration()
        updateOptionLines()
        lastShowingOptions = -1
    }

    private fun updateTotalDuration() {
        val optionsDuration = Duration.ofMillis(
            visibleOptionCount() * textDisplayOptionDelay.coerceAtLeast(0).toLong(),
        )
        completionTime = typingDuration + optionsDuration
    }

    private fun refreshDisplayedOptions() {
        val showingOptions = showingOptions()
        if (showingOptions == lastShowingOptions) return
        lastShowingOptions = showingOptions
        display?.setOptions(options(showingOptions), visibleOptionCount(), selectedSlot(), optionLines)
    }

    private fun selectedSlot(): Int = usableOptions.around(selectedIndex, 1, 2).indexOf(selected)

    private fun updateOptionLines() {
        optionLines = usableOptions.maxOfOrNull {
            it.text.get(player, context).parsePlaceholders(player)
                .limitLineLength(textDisplayMaxLineLength).stripped().lineCount
        } ?: 1
    }

    private fun showingOptions(): Int {
        if (playedTime < typingDuration) return 0
        if (textDisplayOptionDelay <= 0) return visibleOptionCount()
        val timeAfterTyping = (playedTime - typingDuration).toMillis().coerceAtLeast(0)
        return (timeAfterTyping / textDisplayOptionDelay).toInt()
            .coerceIn(0, visibleOptionCount())
    }

    private fun options(showingOptions: Int): List<Component> {
        val options = usableOptions.around(selectedIndex, 1, 2)
        return options.take(showingOptions).mapIndexed { index, option ->
            val prefix = when {
                option == selected -> selectedTextDisplayPrefix
                index == 0 && selectedIndex > 1 && usableOptions.size > MAX_VISIBLE_OPTIONS -> upTextDisplayPrefix
                index == MAX_VISIBLE_OPTIONS - 1 &&
                    selectedIndex < usableOptions.size - 3 &&
                    usableOptions.size > MAX_VISIBLE_OPTIONS -> downTextDisplayPrefix
                else -> unselectedTextDisplayPrefix
            }
            val format = if (option == selected) selectedTextDisplayOption else unselectedTextDisplayOption
            format.asMiniWithResolvers(
                player,
                Placeholder.parsed("prefix", prefix),
                Placeholder.parsed(
                    "option_text",
                    option.text.get(player, context).parsePlaceholders(player)
                        .limitLineLength(textDisplayMaxLineLength),
                ),
            )
        }
    }

    private fun visibleOptionCount(): Int = min(MAX_VISIBLE_OPTIONS, usableOptions.size)
}
