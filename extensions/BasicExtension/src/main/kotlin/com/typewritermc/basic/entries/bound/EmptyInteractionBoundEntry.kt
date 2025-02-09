package com.typewritermc.basic.entries.bound

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.interaction.InteractionBound
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.InteractionBoundEntry
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import org.bukkit.entity.Player

@Entry(
    "empty_interaction_bound",
    "An empty interaction bound which does nothing",
    Colors.MEDIUM_PURPLE,
    "lucide:square-dashed"
)
class EmptyInteractionBoundEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : InteractionBoundEntry {
    override val interruptTriggers: List<Ref<TriggerableEntry>> get() = emptyList()
    override fun build(player: Player): InteractionBound = EmptyInteractionBound(priority)
}

class EmptyInteractionBound(
    override val priority: Int = 0,
) : InteractionBound {
    override suspend fun initialize() {}
    override suspend fun tick() {}
    override suspend fun teardown() {}
}
