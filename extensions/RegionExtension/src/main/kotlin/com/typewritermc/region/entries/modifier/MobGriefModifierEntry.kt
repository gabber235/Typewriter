package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.region.flag.centerPosition
import com.typewritermc.region.flag.RegionFlagIndex
import org.bukkit.entity.FallingBlock
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.entity.EntityChangeBlockEvent

@Entry("region_mob_grief_modifier", "Decide whether mobs may change the blocks in a region", Colors.PURPLE, "mdi:cow-off")
/**
 * Decides whether mobs may change the blocks inside the region: endermen picking blocks up, sheep
 * eating grass, zombies breaking doors.
 *
 * Explosions are a separate flag, because a creeper's crater is decided per block rather than by the
 * mob that caused it.
 *
 * No player is behind a mob, so this flag cannot apply to a region whose placement follows a
 * variable. Attaching it to one logs a warning on startup.
 *
 * ## How could this be used?
 *
 * Keep endermen from picking blocks out of a build, or protect a farm's crops from being
 * trampled.
 */
class MobGriefModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether mobs may change the blocks inside the region.")
    @Default("false")
    val allowed: Boolean = false,
) : RegionModifierEntry

class MobGriefModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW, ignoreCancelled = true)
    fun onChangeBlock(event: EntityChangeBlockEvent) {
        if (event.entity is Player) return
        // Sand and concrete powder settling fire this event too, and a plot that denies griefing
        // did not mean to stop its own builders from placing a block that has to fall first. The
        // build flag decides where a falling block may land.
        if (event.entity is FallingBlock) return
        val flag = index.resolve(
            MobGriefModifierEntry::class,
            event.block.centerPosition(),
            null,
        ) ?: return
        if (flag.allowed) return
        event.isCancelled = true
    }
}
