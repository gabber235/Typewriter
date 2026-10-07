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
import com.typewritermc.region.flag.responsibleAttacker
import com.typewritermc.region.flag.responsiblePlayer
import org.bukkit.entity.Player
import org.bukkit.event.Cancellable
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.entity.EntityDamageEvent
import org.bukkit.event.hanging.HangingBreakByEntityEvent
import org.bukkit.event.hanging.HangingBreakEvent
import org.bukkit.event.vehicle.VehicleDestroyEvent

@Entry(
    "region_entity_damage_modifier",
    "Decide who may damage or destroy the entities in a region",
    Colors.PURPLE,
    "mdi:image-frame"
)
/**
 * Decides whether the entities inside the region may be damaged or destroyed.
 *
 * This covers every entity that is not a player: item frames, paintings, armour stands, boats
 * and minecarts, and mobs too. A region carrying this flag makes the mobs inside it
 * unkillable along with its decorations.
 *
 * Every source counts, not just a player's fist: an arrow, an explosion, another mob, and the
 * world itself. A protected armour stand does not burn in lava and a protected mob does not
 * fall to its death.
 *
 * These are entities, not blocks, so Block Break never protects them: a player denied it could
 * still punch an item frame off a fully protected region's wall. This flag closes that hole.
 *
 * A player hurting another player is the PvP and Mob Damage flags' business, not this one.
 *
 * The VICTIM's location decides, not the attacker's.
 *
 * This usually has a player behind it (someone punching an item frame), but not always. On a
 * region with a variable placement, which only exists per viewer, damage with nobody behind it
 * cannot resolve the region at all, and this denies it rather than letting it through.
 *
 * ## How could this be used?
 *
 * Protect the item frames and paintings in a museum, or the minecarts on a scripted rail ride, from
 * being punched apart.
 */
class EntityDamageModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether the entities inside the region may be damaged or destroyed.")
    @Default("false")
    override val allowed: Var<Boolean> = ConstVar(false),
) : AllowanceModifierEntry

class EntityDamageModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onDamage(event: EntityDamageEvent) {
        if (event.entity is Player) return
        decide(event, event.entity.location.toPosition(), event.responsibleAttacker())
    }

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onHangingBreak(event: HangingBreakEvent) {
        val remover = (event as? HangingBreakByEntityEvent)?.remover
        decide(event, event.entity.location.toPosition(), responsiblePlayer(remover))
    }

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onVehicleDestroy(event: VehicleDestroyEvent) {
        decide(event, event.vehicle.location.toPosition(), responsiblePlayer(event.attacker))
    }

    /**
     * Cancels [event] unless the flag deciding for [position] allows it.
     *
     * [player] is the player answerable for the damage, `null` when nobody is.
     */
    private fun decide(event: Cancellable, position: Position, player: Player?) {
        if (index.allows(EntityDamageModifierEntry::class, position, player)) return
        event.isCancelled = true
    }
}
