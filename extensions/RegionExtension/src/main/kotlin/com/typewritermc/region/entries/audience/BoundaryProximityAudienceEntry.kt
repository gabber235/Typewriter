package com.typewritermc.region.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.region.data.DistanceMode
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.handler.ProximityHandler
import com.typewritermc.region.handler.RegionHandler
import kotlin.math.abs
import org.bukkit.entity.Player

@Entry(
    "region_proximity_audience",
    "Filter players within a distance of a region boundary",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:radar"
)
/**
 * Restricts the child audience to players whose absolute distance from the region's
 * boundary is at most [distance]. Players just inside and just outside the boundary are
 * both included. To pick one side only, nest an [InRegionAudienceEntry], optionally
 * inverted, inside.
 *
 * [distance] may be bound to a variable, and the band is then measured against whatever the
 * variable says at the moment the player is classified. Around a region whose placement is
 * constant, that moment is a move: a band that shrinks while the player stands still does not
 * catch them until they take a step. Give the region a variable placement, which puts it on the
 * refresh loop, to have a band close on a player who is not moving.
 *
 * ## How could this be used?
 *
 * Show a barrier block wall only to players within 8 blocks of the safe zone boundary,
 * combined with an inverted [InRegionAudienceEntry] to only show it from the outside.
 */
class BoundaryProximityAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    @Help("The region whose boundary band to filter against.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
    @Help("Max absolute distance from the boundary (in blocks) that counts as 'in the band'.")
    @Default("5.0")
    val distance: Var<Double> = ConstVar(5.0),
    @Help("How the distance is measured. Horizontal ignores the floor and ceiling faces and measures against the region's vertical silhouette.")
    val distanceMode: DistanceMode = DistanceMode.FULL,
) : AudienceFilterEntry {
    override suspend fun display(): AudienceFilter =
        BoundaryProximityAudienceFilter(ref(), region, distance, distanceMode)
}

class BoundaryProximityAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    region: RegionData,
    private val distance: Var<Double>,
    private val distanceMode: DistanceMode,
) : RegionAudienceFilter(ref, region) {
    override fun filter(player: Player): Boolean {
        val tracker = engine.query(region, player) ?: return false
        val signed = tracker.signedDistance(player.position, distanceMode) ?: return false
        return abs(signed) <= distance.get(player)
    }

    override fun createHandler(player: Player): RegionHandler = ProximityHandler(
        owner = this,
        tracked = player.uniqueId,
        distance = distance,
        distanceMode = distanceMode,
        onEnterBand = { _, _, _ -> player.updateFilter(true); false },
        onLeaveBand = { _, _, _ -> player.updateFilter(false); false },
        // See InRegionAudienceFilter: a band the engine rolls back has to reach the filter too.
        onResync = { _, member -> player.updateFilter(member) },
    )
}
