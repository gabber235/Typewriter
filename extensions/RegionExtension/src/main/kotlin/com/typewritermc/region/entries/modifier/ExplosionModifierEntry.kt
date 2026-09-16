package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.region.flag.centerPosition
import com.typewritermc.region.flag.RegionFlagIndex
import org.bukkit.block.Block
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.BlockExplodeEvent
import org.bukkit.event.entity.EntityExplodeEvent

@Entry("region_explosion_modifier", "Decide whether explosions may break the blocks in a region", Colors.PURPLE, "mdi:bomb-off")
/**
 * Decides whether an explosion may break the blocks inside the region. Creepers, TNT, beds in the
 * nether and anything else that explodes.
 *
 * The blocks inside the region are taken out of the explosion, and the rest still break. A creeper
 * on the border of a protected town craters the field outside it and leaves the town standing.
 *
 * No player is behind an explosion, so this flag cannot apply to a region whose placement follows a
 * variable. Attaching it to one logs a warning on startup.
 *
 * ## How could this be used?
 *
 * Make a town creeper proof without turning mob griefing off for the whole server.
 */
class ExplosionModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether explosions may break the blocks inside the region.")
    @Default("false")
    val allowed: Boolean = false,
) : RegionModifierEntry

class ExplosionModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onEntityExplode(event: EntityExplodeEvent) {
        spareProtectedBlocks(event.blockList())
    }

    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onBlockExplode(event: BlockExplodeEvent) {
        spareProtectedBlocks(event.blockList())
    }

    private fun spareProtectedBlocks(blocks: MutableList<Block>) {
        blocks.removeAll { block ->
            val flag = index.resolve(
                ExplosionModifierEntry::class,
                block.centerPosition(),
                null,
            ) ?: return@removeAll false
            !flag.allowed
        }
    }
}
