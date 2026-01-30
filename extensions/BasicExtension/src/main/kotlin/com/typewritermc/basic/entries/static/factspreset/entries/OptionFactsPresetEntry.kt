package com.typewritermc.basic.entries.static.factspreset.entries

import com.typewritermc.basic.entries.static.factspreset.*
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.formatted
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.entry.eventTriggers
import com.typewritermc.engine.paper.facts.FactsModifier
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.player.PlayerItemHeldEvent

@Entry(
    "option_facts_preset",
    "Allows you to select the one/multiple of the children to be applied",
    Colors.BLUE,
    "f7:arrow-branch",
)
class OptionFactsPresetEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<FactsPresetEntry>> = emptyList(),
    override val presets: List<FactPreset> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val multiple: Boolean = false,
) : FactsPresetEntry {
    override fun applier(
        player: Player,
        modifier: FactsModifier,
        serializer: FactsPresetSerializer
    ): FactsPresetApplier<*> {
        return OptionFactsPresetApplier(player, this, modifier, serializer)
    }
}

class OptionFactsPresetApplier(
    player: Player,
    entry: OptionFactsPresetEntry,
    modifier: FactsModifier,
    serializer: FactsPresetSerializer
) : FactsPresetApplier<OptionFactsPresetEntry>(player, entry, modifier, serializer) {

    private val controller = SelectionController(
        player = player,
        title = if (entry.multiple) selectableMultipleTitle else selectableSingleTitle,
        optionsCount = entry.children.size,
        allowMultiple = entry.multiple,
        optionText = { index -> entry.children.getOrNull(index)?.get()?.name?.formatted ?: "<gray>Unknown" },
        onComplete = { state = FactsPresetApplierState.FINISHED }
    )

    private var selectedChildIndices: Set<Int> = emptySet()

    override val appliedChildren: List<Ref<FactsPresetEntry>>
        get() = selectedChildIndices.mapNotNull { entry.children.getOrNull(it) }

    override val appliedTriggers: List<EventTrigger>
        get() = entry.triggers.eventTriggers + controller.currentSelection.flatMap { index ->
            entry.children.getOrNull(index)?.get()?.triggers?.eventTriggers ?: emptyList()
        }

    override fun init() {
        super.init()
        modifier.apply(player, entry.presets)

        val deserialization = serializer.pop()
        if (!deserialization.isNullOrBlank()) {
            selectedChildIndices = deserialization.trim().split(',').mapNotNull { it.toIntOrNull() }
                .filter { it in 0 until entry.children.size }.toSet()
            state = FactsPresetApplierState.FINISHED
            return
        }

        controller.start()
        if (controller.isComplete) {
            state = FactsPresetApplierState.FINISHED
        }
    }

    @EventHandler
    private fun onPlayerItemHeld(event: PlayerItemHeldEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        event.isCancelled = true
        controller.handleScroll(event.previousSlot, event.newSlot)
    }

    override fun dispose() {
        selectedChildIndices = controller.currentSelection
        serializer.push(selectedChildIndices.joinToString(","))
        controller.dispose()
        super.dispose()
    }
}