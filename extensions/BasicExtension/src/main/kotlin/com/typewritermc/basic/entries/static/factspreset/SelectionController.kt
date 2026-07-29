package com.typewritermc.basic.entries.static.factspreset

import com.typewritermc.core.utils.around
import com.typewritermc.core.utils.loopingDistance
import com.typewritermc.engine.paper.interaction.Confirmation
import com.typewritermc.engine.paper.interaction.awaitConfirmation
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.interaction.startBlockingMessages
import com.typewritermc.engine.paper.interaction.stopBlockingMessages
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.JoinConfiguration
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import kotlin.math.min
import kotlin.time.Duration.Companion.milliseconds

private val singleSelectionFormat: String by snippet(
    "facts.preset.selectable.format.single", """
        |<gray><st>${" ".repeat(60)}</st>
        |<white> <title>
        |
        |<options>
        |<#5d6c78>[ <grey><white>Scroll</white> to change selection and press<white> <confirmation_key> </white>to select <#5d6c78>]</#5d6c78>
        |<gray><st>${" ".repeat(60)}</st>
    """.trimMargin()
)

private val multipleSelectionFormat: String by snippet(
    "facts.preset.selectable.format.multiple", """
        |<gray><st>${" ".repeat(60)}</st>
        |<white> <title>
        |
        |<options>
        |<#5d6c78>[ <grey><white>Scroll</white> to navigate, <white><confirmation_key></white> to toggle selection <#5d6c78>]
        |<#5d6c78>[ <grey>Double-press <white><confirmation_key></white> to finish <#5d6c78>]
        |<gray><st>${" ".repeat(60)}</st>
    """.trimMargin()
)

private val upPrefix: String by snippet("facts.preset.selectable.prefix.up", "<white> ↑")
private val downPrefix: String by snippet("facts.preset.selectable.prefix.down", "<white> ↓")
private val unselectedPrefix: String by snippet("facts.preset.selectable.prefix.unselected", "  ")
private val currentPrefix: String by snippet("facts.preset.selectable.prefix.current", "<#78ff85>>>")
private val currentSelectedPrefix: String by snippet("facts.preset.selectable.prefix.current.selected", "<#78ff85>✓>")
private val selectedOnlyPrefix: String by snippet("facts.preset.selectable.prefix.selected.only", "<#78ff85>✓ ")

private val selectedOptionTemplate: String by snippet(
    "facts.preset.selectable.selected",
    " <prefix> <#5d6c78>[ <#78ff85><option_text> <#5d6c78>]\n"
)
private val unselectedOptionTemplate: String by snippet(
    "facts.preset.selectable.unselected",
    " <prefix> <#5d6c78>[ <grey><option_text> <#5d6c78>]\n"
)
private val currentOptionTemplate: String by snippet(
    "facts.preset.selectable.current",
    " <prefix> <#5d6c78>[ <white><option_text> <#5d6c78>]\n"
)
private val currentSelectedOptionTemplate: String by snippet(
    "facts.preset.selectable.current.selected",
    " <prefix> <#78ff85>[ <white><option_text> <#78ff85>]\n"
)

val DOUBLE_TAP_DELAY = 250.milliseconds

val selectableSingleTitle: String by snippet("facts.preset.selectable.title.single", "Select one option to apply:")
val selectableMultipleTitle: String by snippet("facts.preset.selectable.title.multiple", "Select multiple options to apply:")

class SelectionController(
    private val player: Player,
    private val title: String,
    private val optionsCount: Int,
    private val allowMultiple: Boolean,
    private val optionText: (Int) -> String,
    private val onComplete: (Set<Int>) -> Unit
) {
    private var confirmation: Confirmation? = null
    private var currentIndex = 0
    private val selectedIndices = mutableSetOf<Int>()
    private var lastConfirmation: Long = -1L
    
    var isComplete = false
        private set
    
    fun start() {
        if (optionsCount == 0) {
            isComplete = true
            onComplete(emptySet())
            return
        }
        
        player.startBlockingMessages()
        confirmation = player.awaitConfirmation {
            handleConfirmation()
        }
        display()
    }
    
    fun handleScroll(previousSlot: Int, newSlot: Int) {
        val diff = loopingDistance(previousSlot, newSlot, 8)
        var newIndex = (currentIndex + diff) % optionsCount
        while (newIndex < 0) newIndex += optionsCount
        currentIndex = newIndex
        display()
    }
    
    fun dispose() {
        confirmation?.dispose()
        player.stopBlockingMessages()
        player.chatHistory.resendMessages(player)
    }
    
    private fun toggleSelection(index: Int) {
        if (selectedIndices.contains(index)) {
            selectedIndices.remove(index)
        } else {
            selectedIndices.add(index)
        }
    }
    
    private fun handleConfirmation() {
        if (isComplete) return
        
        if (allowMultiple) {
            val now = System.currentTimeMillis()
            val diff = (now - lastConfirmation).milliseconds
            lastConfirmation = now
            
            if (diff < DOUBLE_TAP_DELAY) {
                if (currentIndex !in selectedIndices) {
                    toggleSelection(currentIndex)
                } else if (selectedIndices.size > 1) {
                    toggleSelection(currentIndex)
                }
                complete()
                return
            }
            
            toggleSelection(currentIndex)
            display()
        } else {
            selectedIndices.clear()
            selectedIndices.add(currentIndex)
            complete()
        }
    }
    
    private fun complete() {
        isComplete = true
        onComplete(selectedIndices.toSet())
    }
    
    private fun display() {
        val formatText = if (allowMultiple) multipleSelectionFormat else singleSelectionFormat
        val message = formatText.asMiniWithResolvers(
            player,
            Placeholder.parsed("title", title),
            Placeholder.component("options", formatOptions()),
        )
        val component = player.chatHistory.composeDarkMessage(message)
        player.sendMessage(component)
    }
    
    private fun formatOptions(): Component {
        val indices = (0 until optionsCount).toList()
        val around = indices.around(currentIndex, 1, 2)
        val lines = mutableListOf<Component>()
        val maxOptions = min(4, around.size)
        
        for (i in 0 until maxOptions) {
            val optionIndex = around[i]
            val isCurrent = optionIndex == currentIndex
            val isSelected = selectedIndices.contains(optionIndex)
            
            val prefix = when {
                isCurrent && isSelected -> currentSelectedPrefix
                isCurrent -> currentPrefix
                isSelected -> selectedOnlyPrefix
                i == 0 && currentIndex > 1 && optionsCount > 4 -> upPrefix
                i == 3 && currentIndex < optionsCount - 3 && optionsCount > 4 -> downPrefix
                else -> unselectedPrefix
            }
            
            val format = when {
                isCurrent && isSelected -> currentSelectedOptionTemplate
                isCurrent -> currentOptionTemplate
                isSelected -> selectedOptionTemplate
                else -> unselectedOptionTemplate
            }
            
            lines += format.asMiniWithResolvers(
                player,
                Placeholder.parsed("prefix", prefix),
                Placeholder.parsed("option_text", optionText(optionIndex))
            )
        }
        
        return Component.join(JoinConfiguration.noSeparators(), lines)
    }
    
    val currentSelection: Set<Int>
        get() = selectedIndices.toSet()
}