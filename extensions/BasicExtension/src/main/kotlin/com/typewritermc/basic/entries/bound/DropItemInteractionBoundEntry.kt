package com.typewritermc.basic.entries.bound

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.interaction.InteractionBound
import com.typewritermc.core.interaction.InteractionBoundState
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entries.EventTrigger
import com.typewritermc.engine.paper.interaction.ListenerInteractionBound
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.player.PlayerDropItemEvent

@Entry(
    "drop_item_interaction_bound",
    "An interaction bound for when the player drops an item",
    Colors.MEDIUM_PURPLE,
    "mage:box-3d-minus-fill"
)
/**
 * The `Drop Item Interaction Bound` entry is an interaction bound that reacts when a player drops an item.
 *
 * If the current state is `BLOCKING`, the item drop will be cancelled.
 * If the current state is `INTERRUPTING`, the interaction will be interrupted.
 *
 * ## How could this be used?
 * This could be used to prevent players from dropping quest or dialogue-related items during interactions.
 */
class DropItemInteractionBoundEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    override val interruptTriggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("Block drop even when in Interruption Mode.")
    val alwaysBlock: Boolean = false,
) : InteractionBoundEntry {
    override fun build(player: Player): InteractionBound =
        DropItemInteractionBound(player, priority, interruptTriggers.eventTriggers, alwaysBlock)
}

class DropItemInteractionBound(
    private val player: Player,
    override val priority: Int,
    override val interruptionTriggers: List<EventTrigger>,
    val alwaysBlock: Boolean = false,
) : ListenerInteractionBound {

    @EventHandler(priority = EventPriority.HIGHEST, ignoreCancelled = true)
    private fun onDrop(event: PlayerDropItemEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        handleEvent(event, if (alwaysBlock) InteractionBoundState.BLOCKING else null)
    }
}
