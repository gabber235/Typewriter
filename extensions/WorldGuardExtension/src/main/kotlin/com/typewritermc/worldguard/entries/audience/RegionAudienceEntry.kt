package com.typewritermc.worldguard.entries.audience

import com.sk89q.worldedit.bukkit.BukkitAdapter
import com.sk89q.worldguard.WorldGuard
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.AudienceFilterEntry
import com.typewritermc.engine.paper.entry.entries.Invertible
import com.typewritermc.worldguard.events.RegionsEnterEvent
import com.typewritermc.worldguard.events.RegionsExitEvent
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler

@Entry(
    "region_audience",
    "Filter players based on if they are in a region",
    Colors.MEDIUM_SEA_GREEN,
    "gis:location-man"
)
/**
 * The `Region Audience` is used to filter players based on if they are in a specific WorldGuard region.
 *
 * ## How could this be used?
 * To show players information when they enter a specific region.
 * For example, when a player enters a town, you could show them information about the town.
 */
class RegionAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    val region: String = "",
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter {
        return RegionAudienceFilter(ref(), region)
    }
}

class RegionAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    private val region: String,
) : AudienceFilter(ref) {

    @EventHandler
    fun onRegionEnter(event: RegionsEnterEvent) {
        if (!canConsider(event.player)) return
        if (event.regions.none { it.id == region }) return
        event.player.updateFilter(true)
    }

    @EventHandler
    fun onRegionLeave(event: RegionsExitEvent) {
        if (!canConsider(event.player)) return
        if (event.regions.none { it.id == region }) return
        event.player.updateFilter(false)
    }

    override fun filter(player: Player): Boolean {
        val regionContainer = WorldGuard.getInstance().platform.regionContainer
        val regionManager = regionContainer.get(BukkitAdapter.adapt(player.world))
        val regions = regionManager?.getApplicableRegions(BukkitAdapter.asBlockVector(player.location))
            ?: return false

        return regions.regions.any { it.id == region }
    }
}