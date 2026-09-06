package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.region.flag.centerPosition
import com.typewritermc.region.flag.RegionFlagIndex
import org.bukkit.block.Block
import org.bukkit.block.BlockFace
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.BlockPistonExtendEvent
import org.bukkit.event.block.BlockPistonRetractEvent

@Entry("region_piston_modifier", "Decide whether pistons may move the blocks in a region", Colors.PURPLE, "mdi:arrow-expand-right")
/**
 * Decides whether a piston may move blocks inside the region.
 *
 * A piston moves all of its blocks or none of them, so a push that touches a single protected block
 * is stopped entirely. It applies wherever the piston itself stands, including outside the region.
 *
 * No player is behind a piston, so this flag cannot apply to a region whose placement follows a
 * variable. Attaching it to one logs a warning on startup.
 *
 * ## How could this be used?
 *
 * Stop a neighbour from pushing a wall of blocks into a protected build, or keep a redstone farm
 * from pushing blocks out of the edge of a town.
 */
class PistonModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether pistons may move blocks inside the region.")
    @Default("false")
    val allowed: Boolean = false,
) : RegionModifierEntry

class PistonModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onExtend(event: BlockPistonExtendEvent) {
        // The head takes the space in front of the piston even when there is nothing to push.
        val head = event.block.getRelative(event.direction)
        if (touchesProtectedBlock(event.blocks, event.direction, head)) event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onRetract(event: BlockPistonRetractEvent) {
        // A retraction's direction is the way its blocks travel, back towards the piston: vanilla
        // hands this event the piston's facing already reversed, unlike the extension's.
        if (touchesProtectedBlock(event.blocks, event.direction, null)) event.isCancelled = true
    }

    /**
     * Whether the move touches a protected block, either by moving one out of a region or by
     * landing one inside it.
     *
     * A block's destination has to be tested separately from where it stands: the event lists
     * the blocks at their current positions, so a piston set up one block outside the boundary
     * pushes past a check that only looks at those.
     */
    private fun touchesProtectedBlock(blocks: List<Block>, movement: BlockFace, head: Block?): Boolean {
        if (head != null && isProtected(head)) return true
        return blocks.any { isProtected(it) || isProtected(it.getRelative(movement)) }
    }

    private fun isProtected(block: Block): Boolean {
        val flag = index.resolve(PistonModifierEntry::class, block.centerPosition(), null) ?: return false
        return !flag.allowed
    }
}
