package com.typewritermc.basic.entries.action

import com.typewritermc.basic.entries.static.factspreset.FactsPresetEntry
import com.typewritermc.basic.entries.static.factspreset.FactsPresetStartTrigger
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.EventTrigger

/**
 * Starts a Facts Preset interaction, applying the referenced preset tree.
 *
 * Mirrors the Cinematic action entry pattern by exposing a start trigger via `eventTriggers`.
 */
@Entry(
    "facts_preset_action",
    "Start a facts preset interaction",
    Colors.YELLOW,
    "mdi:database-cog"
)
class FactsPresetActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val preset: Ref<FactsPresetEntry> = emptyRef(),
    val serialization: String = "",
) : ActionEntry {
    override val eventTriggers: List<EventTrigger>
        get() = listOf(FactsPresetStartTrigger(preset, super.eventTriggers, serialization))

    override fun ActionTrigger.execute() {}
}
