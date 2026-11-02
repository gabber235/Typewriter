package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.utils.toPosition
import com.typewritermc.region.flag.centerPosition
import com.typewritermc.region.flag.RegionFlagIndex
import com.typewritermc.region.flag.allows
import org.bukkit.entity.FallingBlock
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.BlockFertilizeEvent
import org.bukkit.event.block.BlockFormEvent
import org.bukkit.event.block.BlockGrowEvent
import org.bukkit.event.block.BlockMultiPlaceEvent
import org.bukkit.event.block.BlockPlaceEvent
import org.bukkit.event.block.BlockSpreadEvent
import org.bukkit.event.block.EntityBlockFormEvent
import org.bukkit.event.entity.EntityChangeBlockEvent
import org.bukkit.event.entity.EntityPlaceEvent
import org.bukkit.event.hanging.HangingPlaceEvent
import org.bukkit.event.world.StructureGrowEvent

@Entry("region_block_place_modifier", "Decide who may build in a region", Colors.PURPLE, "mdi:cube-outline")
/**
 * Decides whether blocks may be placed inside the region.
 *
 * Entities placed like blocks count as well: item frames, paintings, armour stands, boats,
 * minecarts and end crystals. So do blocks that arrive without anyone placing them: a tree
 * growing into the region, vines and sculk spreading in, ice and snow forming, and sand or
 * anvils falling in from above.
 *
 * The placed BLOCK's location decides, not the player's, so a player standing outside cannot build
 * their way in.
 *
 * ## How could this be used?
 *
 * Keep a cathedral's skyline clear, or stop players from towering into an arena from outside it.
 */
class BlockPlaceModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether blocks may be placed inside the region.")
    @Default("false")
    override val allowed: Var<Boolean> = ConstVar(false),
) : AllowanceModifierEntry

class BlockPlaceModifierHandler(private val index: RegionFlagIndex) : Listener {
    /**
     * A bed, a door and a tall flower are one placement of two blocks, and only the half the
     * player clicked is the event's own block. Both halves are tested, or a player standing
     * outside could lay a bed whose head lands inside a region that denies building.
     *
     * [BlockMultiPlaceEvent] declares no handler list of its own, so it arrives here.
     */
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onPlace(event: BlockPlaceEvent) {
        val placed = (event as? BlockMultiPlaceEvent)?.replacedBlockStates?.map { it.block }
            ?: listOf(event.blockPlaced)
        if (placed.all { isAllowed(it.centerPosition(), event.player) }) return
        event.isCancelled = true
    }

    /**
     * Item frames, paintings, armour stands, boats, minecarts, end crystals and TNT minecarts
     * are placed as entities, not blocks. Without this a region that denies building can still
     * be furnished with all of them.
     *
     * The entity's own location decides. `event.block` is the block that was clicked, which is
     * one step away from where the entity lands, and every face of a region has a block just
     * outside it whose inward face aims in.
     */
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onEntityPlace(event: EntityPlaceEvent) {
        if (isAllowed(event.entity.location.toPosition(), event.player)) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onHangingPlace(event: HangingPlaceEvent) {
        if (isAllowed(event.entity.location.toPosition(), event.player)) return
        event.isCancelled = true
    }

    /**
     * Blocks that appear on their own: a tree grown from a sapling, spreading vines, grass and
     * sculk, ice and snow forming, and anything bonemealed into existence. They are placements
     * as far as a protected build is concerned, and every one of them can be started from a
     * block just outside the boundary.
     */
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onStructureGrow(event: StructureGrowEvent) {
        if (event.blocks.all { isAllowed(it.block.centerPosition(), event.player) }) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onGrow(event: BlockGrowEvent) {
        if (isAllowed(event.block.centerPosition(), null)) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onSpread(event: BlockSpreadEvent) {
        if (isAllowed(event.block.centerPosition(), null)) return
        event.isCancelled = true
    }

    // EntityBlockFormEvent declares no handler list of its own, so this covers frost walker
    // and snow golems as well as ice and snow forming on their own.
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onForm(event: BlockFormEvent) {
        val cause = (event as? EntityBlockFormEvent)?.entity as? Player
        if (isAllowed(event.block.centerPosition(), cause)) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onFertilize(event: BlockFertilizeEvent) {
        if (event.blocks.all { isAllowed(it.block.centerPosition(), event.player) }) return
        event.isCancelled = true
    }

    /**
     * Sand, gravel, anvils and concrete powder land as real blocks wherever they come to rest,
     * and the region they land in need not be the one they were dropped from.
     */
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onFallingBlockLand(event: EntityChangeBlockEvent) {
        if (event.entity !is FallingBlock) return
        if (isAllowed(event.block.centerPosition(), null)) return
        event.isCancelled = true
    }

    private fun isAllowed(position: Position, player: Player?): Boolean =
        index.allows(BlockPlaceModifierEntry::class, position, player)
}
