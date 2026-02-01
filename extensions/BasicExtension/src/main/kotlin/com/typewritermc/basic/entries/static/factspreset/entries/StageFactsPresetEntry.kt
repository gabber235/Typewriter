package com.typewritermc.basic.entries.static.factspreset.entries

import com.typewritermc.basic.entries.static.factspreset.*
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.around
import com.typewritermc.core.utils.formatted
import com.typewritermc.core.utils.loopingDistance
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.dialogue.ConfirmationKeyHandler
import com.typewritermc.engine.paper.entry.dialogue.TickContext
import com.typewritermc.engine.paper.entry.dialogue.confirmationKey
import com.typewritermc.engine.paper.facts.FactsModifier
import com.typewritermc.engine.paper.interaction.chatHistory
import com.typewritermc.engine.paper.interaction.startBlockingMessages
import com.typewritermc.engine.paper.interaction.stopBlockingMessages
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import com.typewritermc.engine.paper.utils.toTicks
import net.kyori.adventure.text.Component
import net.kyori.adventure.text.JoinConfiguration
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.player.PlayerItemHeldEvent
import kotlin.math.min

private val stageFormat: String by snippet(
    "facts.preset.stage.format", """
			|<gray><st>${" ".repeat(60)}</st>
			|<white> Select stage to apply (includes all previous):
			|
			|<options>
			|<#5d6c78>[ <grey><white>Scroll</white> to change stage and press<white> <confirmation_key> </white>to select <#5d6c78>]</#5d6c78>
			|<gray><st>${" ".repeat(60)}</st>
		""".trimMargin()
)

private val stageUpPrefix: String by snippet("facts.preset.stage.prefix.up", "<white> ↑")
private val stageDownPrefix: String by snippet("facts.preset.stage.prefix.down", "<white> ↓")
private val stageUnselectedPrefix: String by snippet("facts.preset.stage.prefix.unselected", "  ")
private val stageCurrentPrefix: String by snippet("facts.preset.stage.prefix.current", "<#78ff85>•>")
private val stageSelectedPrefix: String by snippet("facts.preset.stage.prefix.selected", "<#78ff85>• ")

private val stageSelectedOption: String by snippet(
    "facts.preset.stage.selected",
    " <prefix> <#5d6c78>[ <#78ff85><option_text> <#5d6c78>]\n"
)
private val stageUnselectedOption: String by snippet(
    "facts.preset.stage.unselected",
    " <prefix> <#5d6c78>[ <grey><option_text> <#5d6c78>]\n"
)
private val stageCurrentOption: String by snippet(
    "facts.preset.stage.current",
    " <prefix> <#78ff85>[ <white><option_text> <#78ff85>]\n"
)

@Entry(
    "stage_facts_preset",
    "Allows you to select the stage and applies it and all previous fact presets",
    Colors.BLUE,
    "fa7-solid:timeline",
)
class StageFactsPresetEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<FactsPresetEntry>> = emptyList(),
    override val presets: List<FactPreset> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : FactsPresetEntry {
    override fun applier(
        player: Player,
        modifier: FactsModifier,
        serializer: FactsPresetSerializer
    ): FactsPresetApplier<*> {
        return StageFactsPresetApplier(player, this, modifier, serializer)
    }
}

class StageFactsPresetApplier(
    player: Player,
    entry: StageFactsPresetEntry,
    modifier: FactsModifier,
    serializer: FactsPresetSerializer
) :
    FactsPresetApplier<StageFactsPresetEntry>(player, entry, modifier, serializer) {

    private var confirmationKeyHandler: ConfirmationKeyHandler? = null
    private var currentIndex = 0

    override val appliedChildren: List<Ref<FactsPresetEntry>>
        get() = entry.children.take(currentIndex + 1)

    override fun init() {
        super.init()
        modifier.apply(player, entry.presets)

        if (entry.children.isEmpty()) {
            state = FactsPresetApplierState.FINISHED
            return
        }

        val deserialization = serializer.pop()?.toIntOrNull()
        if (deserialization != null) {
            currentIndex = deserialization
            state = FactsPresetApplierState.FINISHED
            return
        }


        player.startBlockingMessages()

        confirmationKeyHandler = confirmationKey.handler(player) {
            handleConfirmation()
        }

        displayMessage()
    }

    private fun handleConfirmation() {
        if (state != FactsPresetApplierState.RUNNING) return
        state = FactsPresetApplierState.FINISHED
    }

    @EventHandler
    private fun onPlayerItemHeld(event: PlayerItemHeldEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        val curSlot = event.previousSlot
        val newSlot = event.newSlot
        val dif = loopingDistance(curSlot, newSlot, 8)
        val index = currentIndex
        event.isCancelled = true
        var newIndex = (index + dif) % entry.children.size
        while (newIndex < 0) newIndex += entry.children.size
        currentIndex = newIndex
        displayMessage()
    }

    override fun tick(context: TickContext) {
        super.tick(context)
        if (state != FactsPresetApplierState.RUNNING) return

        if (context.playTime.toTicks() % 100 > 0) {
            return
        }

        displayMessage()
    }

    private fun displayMessage() {
        val message = stageFormat.asMiniWithResolvers(
            Placeholder.component("options", formatOptions()),
        )

        val component = player.chatHistory.composeDarkMessage(message)
        player.sendMessage(component)
    }

    private fun formatOptions(): Component {
        val around = entry.children.around(currentIndex, 1, 2)
        val lines = mutableListOf<Component>()
        val maxOptions = min(4, around.size)

        for (i in 0 until maxOptions) {
            val option = around[i]
            val actualIndex = entry.children.indexOf(option)
            val isCurrent = actualIndex == currentIndex
            val isSelected = actualIndex <= currentIndex

            val prefix = when {
                isCurrent -> stageCurrentPrefix
                isSelected -> stageSelectedPrefix
                i == 0 && currentIndex > 1 && entry.children.size > 4 -> stageUpPrefix
                i == 3 && currentIndex < entry.children.size - 3 && entry.children.size > 4 -> stageDownPrefix
                else -> stageUnselectedPrefix
            }

            val format = when {
                isCurrent -> stageCurrentOption
                isSelected -> stageSelectedOption
                else -> stageUnselectedOption
            }

            lines += format.asMiniWithResolvers(
                Placeholder.parsed("prefix", prefix),
                Placeholder.parsed("option_text", option.get()?.name?.formatted ?: "<gray>Unknown")
            )
        }

        return Component.join(JoinConfiguration.noSeparators(), lines)
    }

    override fun dispose() {
        serializer.push("$currentIndex")
        confirmationKeyHandler?.dispose()
        player.stopBlockingMessages()
        player.chatHistory.resendMessages(player)
        super.dispose()
    }
}