package com.typewritermc.region.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.AudienceFilterEntry
import com.typewritermc.engine.paper.entry.entries.Invertible
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.handler.EnterExitHandler
import com.typewritermc.region.handler.RegionHandler
import org.bukkit.entity.Player

@Entry(
    "region_inside_audience",
    "Filter players based on whether they're inside a region",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:map-marker-check"
)
/**
 * Restricts the child audience to players inside [region]. Children attach via the standard
 * [AudienceFilterEntry.children] composition.
 *
 * ## How could this be used?
 *
 * Wrap a particle audience effect so it only plays while the player is inside the safe
 * zone. Or invert it and wrap a damage tick to only hurt players outside the safe zone.
 */
class InRegionAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    @Help("The region whose membership controls the audience.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = InRegionAudienceFilter(ref(), region)
}

class InRegionAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    region: RegionData,
) : RegionAudienceFilter(ref, region) {
    override fun filter(player: Player): Boolean {
        val tracker = engine.query(region, player) ?: return false
        return tracker.isInside(player)
    }

    override fun createHandler(player: Player): RegionHandler = EnterExitHandler(
        owner = this,
        tracked = player.uniqueId,
        onEnter = { _, _, _ -> player.updateFilter(true); false },
        onLeave = { _, _, _ -> player.updateFilter(false); false },
        // The filter holds what the callbacks pushed into it, so a crossing the engine rolls back
        // has to reach it as well. Otherwise a player refused at the boundary is left in the
        // audience: the enter they were denied already switched them on, and the crossing that
        // would switch them off again never happens.
        onResync = { _, member -> player.updateFilter(member) },
    )
}
