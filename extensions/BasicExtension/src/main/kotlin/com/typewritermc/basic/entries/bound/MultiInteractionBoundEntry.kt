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
    "multi_interaction_bound",
    "An interaction bound that handles multiple interaction bounds",
    Colors.MEDIUM_PURPLE,
    "ph:layers-fill"
)
/**
 * The `Multi Interaction Bound` entry is an interaction bound that allows you to combine multiple interaction bounds.
 *
 * This is useful if you want the player to have multiple ways of interrupting the interaction.
 *
 * ## How could this be used?
 * This could be used to allow the player to cancel the interaction if they walk away or run a command.
 */
class MultiInteractionBoundEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val interactionBounds: List<Ref<InteractionBoundEntry>> = emptyList(),
) : InteractionBoundEntry {
    override fun build(player: Player): InteractionBound = MultiInteractionBound(player, interactionBounds, priority)
}

class MultiInteractionBound(
    private val player: Player,
    interactionBounds: List<Ref<InteractionBoundEntry>>,
    override val priority: Int,
) : InteractionBound {
    private val activeBounds: List<InteractionBound> = interactionBounds.mapNotNull { it.get()?.build(player) }

    override suspend fun initialize() {
        activeBounds.forEach { it.initialize() }
    }

    override suspend fun tick() {
        activeBounds.forEach { it.tick() }
    }

    override suspend fun teardown() {
        activeBounds.forEach { it.teardown() }
    }
}