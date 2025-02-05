package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entries.EventEntry
import kotlinx.coroutines.runBlocking
import org.bukkit.event.player.PlayerQuitEvent

@Entry("on_player_quit", "When the player quits the server", Colors.YELLOW, "fluent:person-subtract-20-filled")
/**
 * The `Player Quit Event` event is called when a player quits the server.
 *
 * ## How could this be used?
 *
 * This could be used to reset a boss when they leave or to teleport them outside a dungeon.
 */
class PlayerQuitEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : EventEntry

@EntryListener(PlayerQuitEventEntry::class)
fun onQuit(event: PlayerQuitEvent, query: Query<PlayerQuitEventEntry>) {
    runBlocking {
        query.find().flatMap { it.eventTriggers }.toList().forceTriggerFor(event.player, context())
    }
}