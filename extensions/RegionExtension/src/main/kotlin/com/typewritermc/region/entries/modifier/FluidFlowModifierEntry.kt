package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.region.flag.centerPosition
import com.typewritermc.region.flag.RegionFlagIndex
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.BlockFromToEvent

@Entry("region_fluid_flow_modifier", "Decide whether water and lava may flow into a region", Colors.PURPLE, "mdi:water-off")
/**
 * Decides whether water and lava may flow into the region.
 *
 * The block the fluid flows INTO decides, so a source outside the region is stopped at its border.
 *
 * No player is behind a flowing fluid, so this flag cannot apply to a region whose placement follows
 * a variable. Attaching it to one logs a warning on startup.
 *
 * ## How could this be used?
 *
 * Keep someone from flooding a shop from the plot next door, or hold lava out of a build without
 * walling it in.
 */
class FluidFlowModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether water and lava may flow into the region.")
    @Default("false")
    val allowed: Boolean = false,
) : RegionModifierEntry

class FluidFlowModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onFlow(event: BlockFromToEvent) {
        val flag = index.resolve(
            FluidFlowModifierEntry::class,
            event.toBlock.centerPosition(),
            null,
        ) ?: return
        if (flag.allowed) return
        event.isCancelled = true
    }
}
