package com.typewritermc.basic.entries.dialogue.messengers.textdisplay

import com.typewritermc.basic.entries.dialogue.Option
import com.typewritermc.basic.entries.dialogue.OptionContextKeys
import com.typewritermc.basic.entries.dialogue.OptionTextDisplayDialogueEntry
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.utils.around
import com.typewritermc.core.utils.loopingDistance
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.dialogue.*
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.matches
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.Confirmation
import com.typewritermc.engine.paper.interaction.awaitConfirmation
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import com.typewritermc.engine.paper.utils.limitLineLength
import com.typewritermc.engine.paper.utils.lineCount
import com.typewritermc.engine.paper.utils.stripped
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import org.bukkit.event.player.PlayerRespawnEvent
import org.bukkit.event.EventHandler
import org.bukkit.event.player.PlayerItemHeldEvent
import java.time.Duration
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

class JavaOptionTextDisplayDialogueDialogueMessenger(
    player: Player,
    context: InteractionContext,
    entry: OptionTextDisplayDialogueEntry,
) : DialogueMessenger<OptionTextDisplayDialogueEntry>(player, context, entry) {
    private var confirmation: Confirmation? = null
    private var display: TextDisplayDialogueDisplay? = null
    private lateinit var typewriter: TextDisplayTypewriter
    private var typeDuration = Duration.ZERO
    private var typingDuration = Duration.ZERO
    private var totalDuration = Duration.ZERO
    private var playTime = Duration.ZERO
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

    override var animationComplete: Boolean
        get() = playTime >= totalDuration
        set(value) {
            playTime = if (value) totalDuration else Duration.ZERO
            lastShowingOptions = -1
        }

    @Synchronized
    override fun init() {
        super.init()
        usableOptions = entry.options.filter { it.criteria.matches(player, context) }
        if (usableOptions.isEmpty()) {
            state = MessengerState.FINISHED
            return
        }

        selectedIndex = 0
        val text = entry.text.get(player, context).parsePlaceholders(player)
        typewriter = TextDisplayTypewriter(text, player)
        typeDuration = entry.duration.get(player, context)
        typingDuration = typingDurationType.totalDuration(typewriter.rawText, typeDuration).coerceAtLeast(Duration.ZERO)
        updateTotalDuration()
        updateOptionLines()

        confirmation = player.awaitConfirmation {
            synchronized(this) {
                if (state != MessengerState.RUNNING || display?.isClosing == true) return@awaitConfirmation
                if (animationComplete) display?.close()
                else animationComplete = true
            }
        }
        display = TextDisplayDialogueDisplay(
            player,
            context,
            entry.origin,
            entry.orientation,
        ).also {
            it.setInstruction(optionTextDisplayInstruction.asMiniWithResolvers(player))
            it.setOptions(options(showingOptions()), visibleOptionCount(), selectedSlot(), optionLines)
            it.spawn(displayText(true)!!)
        }
    }

    @EventHandler
    @Synchronized
    private fun onPlayerItemHeld(event: PlayerItemHeldEvent) {
        if (event.player.uniqueId != player.uniqueId || state != MessengerState.RUNNING) return
        if (usableOptions.isEmpty() || display?.isClosing == true) return
        event.isCancelled = true

        val distance = loopingDistance(event.previousSlot, event.newSlot, 8)
        var newIndex = (selectedIndex + distance) % usableOptions.size
        while (newIndex < 0) newIndex += usableOptions.size
        if (newIndex == selectedIndex) return
        selectedIndex = newIndex
        refreshDisplayedOptions(true)
    }

    @Synchronized
    override fun tick(context: TickContext) {
        if (state != MessengerState.RUNNING) return

        val text = if (display?.isClosing == true) null else {
            if (display?.ready == true) playTime += context.deltaTime
            refreshOptions()
            if (state != MessengerState.RUNNING) return
            refreshDisplayedOptions()
            displayText()
        }

        display?.tick(context.deltaTime, text)
        if (display?.invalid == true) {
            state = MessengerState.CANCELLED
            return
        }
        if (display?.finished == true) state = MessengerState.FINISHED
    }

    @EventHandler
    @Synchronized
    private fun onPlayerRespawn(event: PlayerRespawnEvent) {
        if (event.player.uniqueId == player.uniqueId) state = MessengerState.CANCELLED
    }

    @Synchronized
    override fun dispose() {
        super.dispose()
        confirmation?.dispose()
        confirmation = null
        display?.dispose()
        display = null
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
        totalDuration = typingDuration + optionsDuration
    }

    private fun displayText(force: Boolean = false): Component? {
        val percentage = if (typingDuration.toMillis() <= 0) {
            1.0
        } else {
            typingDurationType.calculatePercentage(playTime, typeDuration, typewriter.rawText)
        }
        return typewriter.render(optionTextDisplayFormat, percentage, force)
    }

    private fun refreshDisplayedOptions(force: Boolean = false) {
        val showingOptions = showingOptions()
        if (!force && showingOptions == lastShowingOptions) return
        lastShowingOptions = showingOptions
        display?.setOptions(options(showingOptions), visibleOptionCount(), selectedSlot(), optionLines)
    }

    private fun selectedSlot(): Int = usableOptions.around(selectedIndex, 1, 2).indexOf(selected)

    private fun updateOptionLines() {
        optionLines = usableOptions.maxOfOrNull {
            it.text.get(player, context).parsePlaceholders(player)
                .limitLineLength(textDisplayMaxLineLength.coerceAtLeast(1)).stripped().lineCount
        } ?: 1
    }

    private fun showingOptions(): Int {
        if (playTime < typingDuration) return 0
        if (textDisplayOptionDelay <= 0) return visibleOptionCount()
        val timeAfterTyping = (playTime - typingDuration).toMillis().coerceAtLeast(0)
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
                        .limitLineLength(textDisplayMaxLineLength.coerceAtLeast(1)),
                ),
            )
        }
    }

    private fun visibleOptionCount(): Int = min(MAX_VISIBLE_OPTIONS, usableOptions.size)
}
