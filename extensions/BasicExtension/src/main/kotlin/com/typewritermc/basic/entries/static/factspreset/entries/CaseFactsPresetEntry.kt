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
    "case_facts_preset",
    "Allows selecting inline case definitions instead of child entries",
    Colors.BLUE,
    "ic:round-format-list-bulleted",
)
class CaseFactsPresetEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<FactsPresetEntry>> = emptyList(),
    override val presets: List<FactPreset> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val cases: List<Case> = emptyList(),
    val multiple: Boolean = false,
) : FactsPresetEntry {
    override fun applier(
        player: Player,
        modifier: FactsModifier,
        serializer: FactsPresetSerializer
    ): FactsPresetApplier<*> {
        return CaseFactsPresetApplier(player, this, modifier, serializer)
    }
}

data class Case(
    val label: String = "",
    val presets: List<FactPreset> = emptyList(),
    val triggers: List<Ref<TriggerableEntry>> = emptyList(),
)

class CaseFactsPresetApplier(
    player: Player,
    entry: CaseFactsPresetEntry,
    modifier: FactsModifier,
    serializer: FactsPresetSerializer
) : FactsPresetApplier<CaseFactsPresetEntry>(player, entry, modifier, serializer) {

    private val controller = SelectionController(
        player = player,
        title = if (entry.multiple) selectableMultipleTitle else selectableSingleTitle,
        optionsCount = entry.cases.size,
        allowMultiple = entry.multiple,
        optionText = { index -> entry.cases.getOrNull(index)?.label?.formatted ?: "<gray>Unknown" },
        onComplete = { state = FactsPresetApplierState.FINISHED }
    )

    override fun init() {
        super.init()

        val deserialization = serializer.pop()
        if (!deserialization.isNullOrBlank()) {
            val indices = deserialization.trim().split(',').mapNotNull { it.toIntOrNull() }.toSet()
            indices.forEach { index ->
                entry.cases.getOrNull(index)?.let { case ->
                    modifier.apply(player, case.presets)
                }
            }
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
        serializer.push(controller.currentSelection.joinToString(","))

        controller.currentSelection.forEach { index ->
            entry.cases.getOrNull(index)?.let { case ->
                modifier.apply(player, case.presets)
            }
        }

        controller.dispose()
        super.dispose()
    }

    override val appliedTriggers: List<EventTrigger>
        get() = entry.triggers.eventTriggers + controller.currentSelection.flatMap { index ->
            entry.cases.getOrNull(index)?.triggers?.eventTriggers ?: emptyList()
        }
}