package com.typewritermc.region.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.region.data.CrossingCause
import com.typewritermc.region.data.DistanceMode
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData

@Entry("region_proximity_event", "When a player crosses the proximity band", Colors.YELLOW, "mdi:radar")
/**
 * Fires when a player crosses into or out of the band around the configured region's
 * boundary. It fires once when the player enters the band and once when they leave it.
 * Filter by [causes] to distinguish moves, teleports, and engulfs.
 *
 * Both crossings run the same triggers, and nothing on the entry tells them apart, so what they
 * do has to make sense in both directions. Use a Region Enter Event on a larger region where
 * only the approach should count. For the same reason [cancel] holds a player inside the band:
 * it refuses the crossing whichever way they were going.
 *
 * [distance] may be bound to a variable, and the band is then measured against whatever the
 * variable says at the moment the player is classified. Around a region whose placement is
 * constant, that moment is a move: a band that shrinks while the player stands still does not
 * catch them until they take a step. Give the region a variable placement, which puts it on the
 * refresh loop, to have a band close on a player who is not moving.
 *
 * ## How could this be used?
 *
 * Play a coronation tune when the player comes within 5 blocks of the king, with a small
 * sphere around the king and [distance] left at its default.
 */
class RegionProximityEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("The region whose boundary band to observe.")
    @Default(RegionDefaults.REGION_REFERENCE)
    override val region: RegionData = RegionReferenceData(),
    @Help("Width of the proximity band (absolute signed-distance to the boundary).")
    @Default("3.0")
    val distance: Var<Double> = ConstVar(3.0),
    @Help("How the distance is measured. Horizontal ignores the floor and ceiling faces and measures against the region's vertical silhouette.")
    val distanceMode: DistanceMode = DistanceMode.FULL,
    @Help("Restrict to these crossing causes. Empty list means all causes match.")
    override val causes: List<CrossingCause> = emptyList(),
    @Help("How far a player must move outside the band before the leave fires. Entering the band is never delayed.")
    override val boundaryInset: Var<Double> = ConstVar(0.0),
    override val cancel: Var<Boolean> = ConstVar(false),
) : RegionEventEntry
