package com.typewritermc.region.entries.modifier

import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.utils.toPosition
import com.typewritermc.region.flag.RegionFlagIndex
import com.typewritermc.region.flag.allowsDamage
import com.typewritermc.region.flag.specificDecision
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.entity.EntityDamageEvent

/**
 * Enforces the three flags that decide about a player being hurt: PvP, Mob Damage and Player
 * Damage.
 *
 * One handler for the three, because every hit weighs the specific flag against the general one
 * before it can be refused, and a listener per flag resolved both decisions per hit and then
 * reached the same answer three times.
 */
class CombatModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onDamage(event: EntityDamageEvent) {
        val victim = event.entity as? Player ?: return
        val position = victim.location.toPosition()

        val general = index.resolveDecision(PlayerDamageModifierEntry::class, position, victim) {
            it.decidesAbout(event.cause)
        }
        val specific = specificDecision(index, event, victim, position)

        val allowed = allowsDamage(
            specific = specific?.decision,
            general = general,
            allowedBySpecific = specific?.allowed ?: false,
            allowedByGeneral = general?.flag?.allowed?.get(victim) ?: false,
        ) ?: return
        if (allowed) return
        event.isCancelled = true
    }
}
