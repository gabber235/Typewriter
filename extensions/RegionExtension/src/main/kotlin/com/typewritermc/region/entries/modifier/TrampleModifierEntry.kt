package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.region.flag.centerPosition
import com.typewritermc.region.flag.RegionFlagIndex
import com.typewritermc.region.flag.allows
import com.typewritermc.region.flag.responsiblePlayer
import org.bukkit.block.Block
import org.bukkit.entity.Entity
import org.bukkit.entity.Player
import org.bukkit.Material
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.Action
import org.bukkit.event.entity.EntityInteractEvent
import org.bukkit.event.player.PlayerInteractEvent

@Entry("region_trample_modifier", "Decide who may trample the farmland in a region", Colors.PURPLE, "mdi:sprout")
/**
 * Decides whether farmland and turtle eggs inside the region may be trampled by walking or jumping
 * on them. Mobs and mounted players count too, which is how a protected farm otherwise survives
 * every visitor on foot and falls to the first one on a horse.
 *
 * Trampling is a PHYSICAL interaction, which the Block Interact flag does not cover since that only
 * decides about right clicks. Without this flag, a player denied Block Interact could still trample
 * every crop in a protected farm.
 *
 * The BLOCK's location decides, not the player's.
 *
 * ## How could this be used?
 *
 * Protect a farm's crops from being trampled without locking its gates and levers too.
 */
class TrampleModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether farmland and turtle eggs inside the region may be trampled.")
    @Default("false")
    override val allowed: Var<Boolean> = ConstVar(false),
) : AllowanceModifierEntry

class TrampleModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onPhysical(event: PlayerInteractEvent) {
        if (event.action != Action.PHYSICAL) return
        val block = event.clickedBlock ?: return
        if (block.type !in TRAMPLEABLE) return
        if (isAllowed(block, event.player)) return
        event.isCancelled = true
    }

    /**
     * A player on a horse, and any mob at all, trample through this event instead. Without it a
     * protected farm survives every visitor on foot and is flattened by the first one who rides
     * in, and nothing whatsoever protects turtle eggs.
     */
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onEntityInteract(event: EntityInteractEvent) {
        val block = event.block
        if (block.type !in TRAMPLEABLE) return
        if (isAllowed(block, riderOf(event.entity) ?: responsiblePlayer(event.entity))) return
        event.isCancelled = true
    }

    /**
     * The rider before the owner: a horse's owner may be a farm's owner and half the map away,
     * while the visitor in the saddle is the one flattening the crops.
     */
    private fun riderOf(entity: Entity): Player? = entity.passengers.firstNotNullOfOrNull { it as? Player }

    private fun isAllowed(block: Block, player: Player?): Boolean =
        index.allows(TrampleModifierEntry::class, block.centerPosition(), player)

    companion object {
        private val TRAMPLEABLE = setOf(Material.FARMLAND, Material.TURTLE_EGG)
    }
}
