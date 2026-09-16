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
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.BlockIgniteEvent

@Entry("region_ignite_modifier", "Decide who may light fires in a region", Colors.PURPLE, "mdi:fire")
/**
 * Decides whether the players inside the region may light fires with flint and steel or fire
 * charges.
 *
 * The only flag that covers it. Block Interact refuses the block that was clicked and the item held
 * against it, and flint and steel is neither a block nor something that attaches to one, so it goes
 * on working on a locked wall.
 *
 * A flaming arrow, an end crystal and a dispenser holding flint and steel count too. All three are
 * somebody lighting a fire with a step in between, and all three arrive with no player attached to
 * the event.
 *
 * Fire arriving on its own is the Fire Spread flag's business, not this one: fire from a neighbouring
 * block, from lava, from lightning, or the fireball of a ghast nobody is answerable for.
 *
 * The BLOCK's location decides, not the player's.
 *
 * ## How could this be used?
 *
 * Keep flint and steel out of a protected wooden build without locking its doors as well.
 */
class IgniteModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether the players inside the region may light fires.")
    @Default("false")
    override val allowed: Var<Boolean> = ConstVar(false),
) : AllowanceModifierEntry

class IgniteModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onIgnite(event: BlockIgniteEvent) {
        if (event.cause !in DELIBERATE_CAUSES) return

        // `event.player` is null for a flaming arrow and for a dispenser's flint and steel,
        // both of which are somebody lighting a fire with an extra step in between.
        val player = event.player ?: responsiblePlayer(event.ignitingEntity)
        if (index.allows(IgniteModifierEntry::class, event.block.centerPosition(), player)) return
        event.isCancelled = true
    }

    companion object {
        /** Lighting a fire on purpose, as opposed to fire arriving on its own. */
        private val DELIBERATE_CAUSES = setOf(
            BlockIgniteEvent.IgniteCause.FLINT_AND_STEEL,
            BlockIgniteEvent.IgniteCause.FIREBALL,
            BlockIgniteEvent.IgniteCause.ARROW,
            BlockIgniteEvent.IgniteCause.ENDER_CRYSTAL,
        )
    }
}
