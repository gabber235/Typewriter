package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.region.flag.RegionFlagIndex
import com.typewritermc.region.flag.allows
import com.typewritermc.region.flag.centerPosition
import org.bukkit.Material
import org.bukkit.block.DoubleChest
import org.bukkit.entity.Player
import org.bukkit.event.Event
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.Action
import org.bukkit.event.entity.EntityInteractEvent
import org.bukkit.event.inventory.InventoryMoveItemEvent
import org.bukkit.inventory.BlockInventoryHolder
import org.bukkit.inventory.Inventory
import org.bukkit.event.player.PlayerInteractEvent

@Entry(
    "region_block_interact_modifier",
    "Decide who may use the blocks in a region",
    Colors.PURPLE,
    "mdi:hand-back-right"
)
/**
 * Decides whether the blocks inside the region may be used: chests, doors, buttons, levers and
 * anything else a right click opens or toggles.
 *
 * Entities are not blocks. Rotating an item frame, stripping an armour stand or opening a chest
 * minecart is the Entity Interact flag's business.
 *
 * Denying this refuses the use of the block, and of a block held against it, since a refused click
 * otherwise falls through to placing what is in hand. You can still eat, drink or draw a bow while
 * looking at a locked door.
 *
 * Hoppers and droppers are covered too, in both directions, so a container inside the region cannot
 * be drained or filled from outside it.
 *
 * The BLOCK's location decides, not the player's.
 *
 * ## How could this be used?
 *
 * Lock a vault's chests to everyone outside the guild, or keep visitors from pulling the levers in
 * a puzzle room they have not unlocked yet.
 */
class BlockInteractModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether the blocks inside the region may be used.")
    @Default("false")
    override val allowed: Var<Boolean> = ConstVar(false),
) : AllowanceModifierEntry

class BlockInteractModifierHandler(private val index: RegionFlagIndex) : Listener {
    /**
     * Stepping on a pressure plate or a tripwire is a use of the block that no click carries, and
     * a puzzle whose levers are locked is not locked at all while its plates still fire. Farmland
     * and turtle eggs are stepped on too, and those belong to the trample flag, so they are left
     * to it rather than being decided twice.
     */
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onPhysical(event: PlayerInteractEvent) {
        if (event.action != Action.PHYSICAL) return
        val block = event.clickedBlock ?: return
        if (block.type in TRAMPLED_BLOCKS) return
        if (isAllowed(block.centerPosition(), event.player)) return
        event.isCancelled = true
    }

    /**
     * A plate fires for an arrow, a dropped item and a wandering mob through this event instead,
     * and a puzzle whose levers are locked is not locked while anyone can shoot its plates.
     */
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onEntityPhysical(event: EntityInteractEvent) {
        val block = event.block
        if (block.type in TRAMPLED_BLOCKS) return
        if (isAllowed(block.centerPosition(), event.entity as? Player)) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onInteract(event: PlayerInteractEvent) {
        if (event.action != Action.RIGHT_CLICK_BLOCK) return
        val block = event.clickedBlock ?: return
        if (isAllowed(block.centerPosition(), event.player)) return

        // Not setCancelled, which also denies the item in hand: that would stop a player eating,
        // drinking or firing a bow whenever their crosshair rested on the region.
        event.setUseInteractedBlock(Event.Result.DENY)

        // A denied block still lets the item run, and for a block in hand that means placing it
        // against the face that was just refused. Only what attaches to that face is taken away;
        // everything a player can consume or aim keeps working.
        if (event.material.isBlock || event.material in ATTACHED_TO_BLOCK) {
            event.setUseItemInHand(Event.Result.DENY)
        }
    }

    /**
     * A hopper or dropper pointed at a container in the region moves its items without anyone
     * touching it, which is the whole point of locking the container in the first place.
     */
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onItemMove(event: InventoryMoveItemEvent) {
        if (event.source.decidingPositions().any { !isAllowed(it, null) }) {
            event.isCancelled = true
            return
        }
        if (event.destination.decidingPositions().any { !isAllowed(it, null) }) event.isCancelled = true
    }

    /**
     * Every block a container occupies, by its center, which is where a click on it decides too.
     *
     * An inventory's location is the block's corner, and a boundary cutting through a chest would
     * otherwise refuse the player who right clicks it, whose click is decided by the center, and
     * allow the hopper underneath it.
     */
    private fun Inventory.decidingPositions(): List<Position> {
        // The snapshotless holder: the plain accessor copies the whole container and every item
        // in it into a fresh block state, and this runs for every hopper transfer on the server.
        val holder = getHolder(false)
        if (holder is BlockInventoryHolder) return listOf(holder.block.centerPosition())
        // A double chest is the common case that is not a BlockInventoryHolder: it holds its two
        // halves rather than a block. Both are asked, because a boundary can run between them and
        // a chest half anyone can reach into is a chest that is not protected.
        if (holder is DoubleChest) {
            val halves = listOfNotNull(holder.getLeftSide(false), holder.getRightSide(false))
                .filterIsInstance<BlockInventoryHolder>()
                .map { it.block.centerPosition() }
            if (halves.isNotEmpty()) return halves
        }
        // Everything else answers by its own location, which a container reports as the block's
        // lowest corner. Read back as a block so it decides where a click on it would.
        return listOfNotNull(location?.block?.centerPosition())
    }

    private fun isAllowed(position: Position, player: Player?): Boolean =
        index.allows(BlockInteractModifierEntry::class, position, player)

    companion object {
        /** Stepped on, but the trample flag's business rather than this one's. */
        private val TRAMPLED_BLOCKS = setOf(Material.FARMLAND, Material.TURTLE_EGG)

        /**
         * Items that hang on the face a click was just refused for. `Material.isBlock` is false
         * for every one of them, so without this a locked museum wall still takes frames and
         * paintings. What lands on the ground rather than on the clicked face, like a boat or a
         * planted seed, is the build flag's business.
         */
        private val ATTACHED_TO_BLOCK = setOf(
            Material.ITEM_FRAME,
            Material.GLOW_ITEM_FRAME,
            Material.PAINTING,
            Material.ARMOR_STAND,
            Material.END_CRYSTAL,
        )
    }
}
