package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.toPosition
import com.typewritermc.region.flag.RegionFlagIndex
import com.typewritermc.region.flag.allows
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerArmorStandManipulateEvent
import org.bukkit.event.player.PlayerInteractEntityEvent

@Entry(
    "region_entity_interact_modifier",
    "Decide who may use the entities in a region",
    Colors.PURPLE,
    "mdi:hand-pointing-up"
)
/**
 * Decides whether the entities inside the region may be used: taking the armour off an armour
 * stand, rotating an item frame, opening a chest minecart, trading with a villager, mounting a
 * horse, feeding an animal, leashing or name tagging one.
 *
 * Block Interact never sees an entity, so a museum that only denies it still has its frames
 * turned and its stands stripped. This flag covers those, and every other right click on an
 * entity with them.
 *
 * The ENTITY's location decides, not the player's.
 *
 * ## How could this be used?
 *
 * Keep visitors from emptying the armour stands in a museum, or from riding off on the stable's
 * horses.
 */
class EntityInteractModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether the entities inside the region may be used.")
    @Default("false")
    override val allowed: Var<Boolean> = ConstVar(false),
) : AllowanceModifierEntry

class EntityInteractModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onInteractEntity(event: PlayerInteractEntityEvent) {
        if (isAllowed(event.rightClicked.location.toPosition(), event.player)) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onManipulateArmorStand(event: PlayerArmorStandManipulateEvent) {
        if (isAllowed(event.rightClicked.location.toPosition(), event.player)) return
        event.isCancelled = true
    }

    private fun isAllowed(position: Position, player: Player): Boolean =
        index.allows(EntityInteractModifierEntry::class, position, player)
}
