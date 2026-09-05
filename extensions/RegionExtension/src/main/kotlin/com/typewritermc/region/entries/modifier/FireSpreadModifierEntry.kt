package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.region.flag.centerPosition
import com.typewritermc.region.flag.RegionFlagIndex
import com.typewritermc.region.flag.responsiblePlayer
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.BlockBurnEvent
import org.bukkit.event.block.BlockIgniteEvent

@Entry("region_fire_spread_modifier", "Decide whether fire may spread in a region", Colors.PURPLE, "mdi:fire-off")
/**
 * Decides whether fire may spread to, and burn, the blocks inside the region.
 *
 * This is about fire spreading on its own, not about a player with a flint and steel. A player
 * lighting a fire is a block interact question, so use the block interact flag for that.
 *
 * No player is behind spreading fire, so this flag cannot apply to a region whose placement follows
 * a variable. Attaching it to one logs a warning on startup.
 *
 * ## How could this be used?
 *
 * Keep a wooden village from burning down after a lightning strike, without turning fire off for the
 * whole world.
 */
class FireSpreadModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether fire may spread to the blocks inside the region.")
    @Default("false")
    val allowed: Boolean = false,
) : RegionModifierEntry

class FireSpreadModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onIgnite(event: BlockIgniteEvent) {
        if (event.cause !in SPREAD_CAUSES) return
        // A fire charge thrown by a player carries the same cause as a ghast's, and an end crystal
        // a player placed the same one as a leftover from the dragon fight. When somebody is
        // answerable, the fire is deliberate and the ignite flag decides it, not this one.
        if (event.cause in SHARED_WITH_IGNITE && answerableFor(event) != null) return
        if (isAllowed(event.block.centerPosition())) return
        event.isCancelled = true
    }

    private fun answerableFor(event: BlockIgniteEvent): Player? =
        event.player ?: responsiblePlayer(event.ignitingEntity)

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onBurn(event: BlockBurnEvent) {
        if (isAllowed(event.block.centerPosition())) return
        event.isCancelled = true
    }

    private fun isAllowed(position: Position): Boolean {
        val flag = index.resolve(FireSpreadModifierEntry::class, position, null) ?: return true
        return flag.allowed
    }

    companion object {
        private val SPREAD_CAUSES = setOf(
            BlockIgniteEvent.IgniteCause.SPREAD,
            BlockIgniteEvent.IgniteCause.LAVA,
            BlockIgniteEvent.IgniteCause.LIGHTNING,
            BlockIgniteEvent.IgniteCause.EXPLOSION,
            // A ghast's fireball and an end crystal left over from the dragon fight have no player
            // behind them, so the Ignite flag never sees them and this is the only flag that can
            // keep them out.
            BlockIgniteEvent.IgniteCause.FIREBALL,
            BlockIgniteEvent.IgniteCause.ENDER_CRYSTAL,
        )

        /** The causes the ignite flag also claims, which it owns whenever a player is behind them. */
        private val SHARED_WITH_IGNITE = setOf(
            BlockIgniteEvent.IgniteCause.FIREBALL,
            BlockIgniteEvent.IgniteCause.ENDER_CRYSTAL,
        )
    }
}
