package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.block.BlockBreakEvent

@Entry("prevent_block_break_audience", "Stop players from breaking blocks", Colors.GREEN, "mdi:pickaxe")
/**
 * The `Prevent Block Break Audience` stops the players in the audience from breaking any block,
 * wherever they are.
 *
 * This is about the player, not about a place. To protect the blocks of one region from everyone,
 * including a player standing outside it and mining inward, use the region's own block break flag
 * instead.
 *
 * ## How could this be used?
 * Freeze a player's ability to mine during a quest, or put it under an `In Region` audience so
 * nobody digs up the town square.
 */
class PreventBlockBreakAudienceEntry(
    override val id: String = "",
    override val name: String = "",
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = PreventBlockBreakAudienceDisplay()
}

class PreventBlockBreakAudienceDisplay : AudienceDisplay() {
    override fun onPlayerAdd(player: Player) {}
    override fun onPlayerRemove(player: Player) {}

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onBreak(event: BlockBreakEvent) {
        if (event.player !in this) return
        event.isCancelled = true
    }
}
