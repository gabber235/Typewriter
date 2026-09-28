package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.region.flag.RegionFlagIndex
import com.typewritermc.region.flag.allows
import com.typewritermc.region.flag.centerPosition
import org.bukkit.Material
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.BlockBreakEvent
import org.bukkit.event.block.BlockEvent
import org.bukkit.event.block.BlockFadeEvent
import org.bukkit.event.block.LeavesDecayEvent

@Entry("region_block_break_modifier", "Decide who may break the blocks in a region", Colors.PURPLE, "mdi:pickaxe")
/**
 * Decides whether the blocks inside the region may be broken.
 *
 * The BLOCK's location decides, not the player's, so a player standing outside the region cannot
 * mine their way in.
 *
 * Blocks that vanish on their own count too: ice or snow melting, farmland drying out, and leaves
 * decaying once the logs holding them are cut.
 *
 * A region carrying this flag decides for the blocks inside it. Where regions overlap, the one with
 * the highest priority decides, so an arena inside a protected city can allow what the city forbids
 * by carrying this flag with [allowed] set.
 *
 * ## How could this be used?
 *
 * Protect a town from griefing, and give its quarry a higher priority region that allows mining
 * again.
 */
class BlockBreakModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether the blocks inside the region may be broken.")
    @Default("false")
    override val allowed: Var<Boolean> = ConstVar(false),
) : AllowanceModifierEntry

class BlockBreakModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onBreak(event: BlockBreakEvent) {
        if (index.allows(BlockBreakModifierEntry::class, event.block.centerPosition(), event.player)) return
        event.isCancelled = true
    }

    /**
     * Blocks that disappear on their own: ice and snow melting, farmland drying out, leaves
     * decaying once their logs are gone. Every one of them can be provoked from outside the
     * region, by placing a torch or by cutting the tree the canopy hangs from.
     *
     * Blocks whose fade is not a break are exempt. A fire burning out is a fade, and refusing it
     * would hold the fire there forever, damaging anyone who walks through: the flag meant to
     * preserve the build would keep the fire burning. Redstone ore uses a
     * fade to stop glowing, and eggs use one to hatch, neither of which takes anything away.
     */
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onFade(event: BlockFadeEvent) {
        if (event.block.type in SELF_CLEARING) return
        if (isAllowed(event)) return
        event.isCancelled = true
    }

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onLeavesDecay(event: LeavesDecayEvent) {
        if (isAllowed(event)) return
        event.isCancelled = true
    }

    private fun isAllowed(event: BlockEvent): Boolean =
        index.allows(BlockBreakModifierEntry::class, event.block.centerPosition(), null)

    companion object {
        /**
         * The dried ghast is looked up by name. Its constant only exists from 1.21.6 on, and a
         * direct reference stops this whole handler from loading on the older servers the
         * extension supports.
         */
        private val SELF_CLEARING = setOfNotNull(
            Material.FIRE,
            Material.SOUL_FIRE,
            Material.REDSTONE_ORE,
            Material.DEEPSLATE_REDSTONE_ORE,
            Material.TURTLE_EGG,
            Material.SNIFFER_EGG,
            Material.FROGSPAWN,
            Material.matchMaterial("DRIED_GHAST"),
        )
    }
}
