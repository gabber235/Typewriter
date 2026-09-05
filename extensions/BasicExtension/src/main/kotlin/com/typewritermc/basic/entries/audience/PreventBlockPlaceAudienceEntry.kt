package com.typewritermc.basic.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.block.BlockPlaceEvent

@Entry("prevent_block_place_audience", "Stop players from placing blocks", Colors.GREEN, "mdi:cube-off-outline")
/**
 * The `Prevent Block Place Audience` stops the players in the audience from placing any block,
 * wherever they are.
 *
 * This is about the player, not about a place. To protect one region from everyone building in it,
 * use the region's own block place flag instead.
 *
 * ## How could this be used?
 * Stop players from towering out of an arena, or put it under an `In Region` audience so the
 * cathedral keeps its skyline.
 */
class PreventBlockPlaceAudienceEntry(
    override val id: String = "",
    override val name: String = "",
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = PreventBlockPlaceAudienceDisplay()
}

class PreventBlockPlaceAudienceDisplay : AudienceDisplay() {
    override fun onPlayerAdd(player: Player) {}
    override fun onPlayerRemove(player: Player) {}

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onPlace(event: BlockPlaceEvent) {
        if (event.player !in this) return
        event.isCancelled = true
    }
}
