package com.typewritermc.region.entries.modifier

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.region.flag.centerPosition
import com.typewritermc.region.flag.RegionFlagIndex
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.block.BlockRedstoneEvent

@Entry("region_redstone_modifier", "Decide whether redstone may run in a region", Colors.PURPLE, "mdi:lightning-bolt")
/**
 * Decides whether redstone may change state inside the region.
 *
 * A redstone change is not a cancellable event, so a denied one is held at its previous current
 * instead: the wire simply never powers on. Powering down is always allowed, so a circuit that was
 * already live when the flag went up still settles instead of being stuck on forever.
 *
 * No player is behind a redstone tick, so this flag cannot apply to a region whose placement follows
 * a variable. Attaching it to one logs a warning on startup.
 *
 * ## How could this be used?
 *
 * Kill redstone inside a puzzle room so nobody can shortcut it with a contraption, or keep a lag
 * machine from running in a public plot.
 */
class RedstoneModifierEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("Whether redstone may change state inside the region.")
    @Default("false")
    val allowed: Boolean = false,
) : RegionModifierEntry

class RedstoneModifierHandler(private val index: RegionFlagIndex) : Listener {
    @EventHandler(priority = EventPriority.LOW)
    fun onRedstone(event: BlockRedstoneEvent) {
        // Powering down is always allowed. Holding the old current in both directions freezes
        // whatever was already live when the flag went up, and nothing can ever switch it off:
        // a lag machine running at the moment of a publish would run forever.
        if (event.newCurrent < event.oldCurrent) return
        val flag = index.resolve(RedstoneModifierEntry::class, event.block.centerPosition(), null) ?: return
        if (flag.allowed) return
        event.newCurrent = event.oldCurrent
    }
}
