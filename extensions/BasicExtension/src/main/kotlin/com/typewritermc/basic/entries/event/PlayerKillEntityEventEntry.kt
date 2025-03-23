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
import org.bukkit.event.entity.EntityDeathEvent
import java.util.*

@Entry("on_player_kill_entity", "When a player kills an entity", Colors.YELLOW, "fa6-solid:skull")
/**
 * The `Player Kill Entity Event` is fired when a player kills an entity. If you want to detect when a player kills another player, use the [`Player Kill Player Event`](on_player_kill_player) instead.
 *
 * ## How could this be used?
 *
 * This event could be used to detect when a player kills a boss, and give them some rewards. It could also be used to create a custom mob that drops items when killed by a player.
 */
class PlayerKillEntityEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val entityType: Optional<EntityType> = Optional.empty(),
) : EventEntry


@EntryListener(PlayerKillEntityEventEntry::class)
fun onKill(event: EntityDeathEvent, query: Query<PlayerKillEntityEventEntry>) {
    val killer = event.entity.killer ?: return

    query.findWhere { entry ->
        entry.entityType.map { it == event.entityType }.orElse(true)
    }.triggerAllFor(killer, context())
}