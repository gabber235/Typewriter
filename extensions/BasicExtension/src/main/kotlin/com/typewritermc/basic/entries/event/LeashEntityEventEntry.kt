package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.triggerAllFor
import org.bukkit.entity.EntityType
import org.bukkit.event.entity.PlayerLeashEntityEvent
import java.util.*

@Entry("leash_entity_event", "When a player leashes an entity", Colors.YELLOW, "fa6-solid:link")
/**
 * The `Leash Entity Event` is fired when a player leashes an entity.
 *
 * ## How could this be used?
 *
 * This event could be used to detect when a player leashes a specific type of entity, and trigger custom behaviors or rewards.
 * For example, you could create a quest that requires players to leash certain animals.
 */
class LeashEntityEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val entityType: Optional<EntityType> = Optional.empty(),
) : EventEntry


@EntryListener(LeashEntityEventEntry::class)
fun onLeash(event: PlayerLeashEntityEvent, query: Query<LeashEntityEventEntry>) {
    val player = event.player

    query.findWhere { entry ->
        entry.entityType.map { it == event.entity.type }.orElse(true)
    }.triggerAllFor(player, context())
}