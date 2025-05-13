package com.typewritermc.rpgregions.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.core.utils.server
import net.islandearth.rpgregions.api.events.RegionDiscoverEvent

@Entry(
    "on_discover_rpg_region",
    "When a player discovers an RPGRegions region",
    Colors.YELLOW,
    "fa-solid:location-arrow"
)
/**
 * The `Discover Region Event` is triggered when a player discovers a region.
 *
 * ## How could this be used?
 *
 * This event could be used to trigger a message to the player when they discover a region, like a welcome.
 * Or when they discover a region, it could trigger a quest to start and start a dialogue or cinematic.
 */
class DiscoverRegionEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("Make sure that this is the region ID, not the region's display name.")
    val region: String = "",
) : EventEntry

@EntryListener(DiscoverRegionEventEntry::class)
fun onDiscoverRegions(event: RegionDiscoverEvent, query: Query<DiscoverRegionEventEntry>) {
    val player = server.getPlayer(event.player.uniqueId) ?: return
    query.findWhere { it.region == event.region.id }.triggerAllFor(player, context())
}