package com.typewritermc.region.entries.fact

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.GroupEntry
import com.typewritermc.engine.paper.entry.entries.ReadableFactEntry
import com.typewritermc.engine.paper.facts.FactData
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.region.RegionEngine
import com.typewritermc.region.data.DistanceMode
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData
import kotlin.math.roundToInt
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent

@Entry("region_boundary_distance_fact", "Signed distance from a region boundary, in centimeters", Colors.PURPLE, "mdi:ruler")
/**
 * The value is the player's signed distance from the region boundary in centimeters, so
 * the block distance times 100, rounded to an int. The value is negative inside the
 * region, positive outside, and zero on the boundary. A single fact can therefore drive
 * both inside effects (negative values) and outside effects (positive values).
 *
 * The unit is centimeters because Typewriter facts store an Int. Use the
 * `BoundaryDistanceVariable` for full precision.
 *
 * A fact holds a number and nothing else, so a region that cannot be measured at all reads
 * as zero, the same as standing exactly on the boundary. That happens when the region entry
 * is missing, when its placement variable does not resolve, or when the player is in another
 * world. Pair a criteria on this fact with the In Region fact when the difference matters.
 * The console warns at startup about a region whose shape cannot be built.
 *
 * With a region face on the ground, the inside distance is dominated by the floor
 * underfoot. Set [distanceMode] to horizontal to measure against the walls only.
 *
 * The distance is measured from where the player stands, so a `Group` does not change it. A
 * group shares one stored value between its members, and this fact has nothing stored to
 * share: summing it over a group would add up everyone's distances.
 *
 * The measurement is a single point at the player's feet, while the In Region fact and the
 * enter and leave events go by the whole body. In the roughly 0.3 block shell around the
 * boundary the two disagree, and a player the region already counts as inside can still read
 * a small positive distance here.
 *
 * ## How could this be used?
 *
 * Damage players outside the safe zone with the criteria `BoundaryDistanceFact > 0` on a
 * damage action. Require more than 5 blocks outside with `BoundaryDistanceFact > 500`.
 */
class BoundaryDistanceFact(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
    @Help("The region whose boundary distance to publish.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
    @Help("How the distance is measured. Horizontal ignores the floor and ceiling faces and measures against the region's vertical silhouette.")
    val distanceMode: DistanceMode = DistanceMode.FULL,
) : ReadableFactEntry {
    override fun readForPlayersGroup(player: Player): FactData = readSinglePlayer(player)

    override fun readSinglePlayer(player: Player): FactData {
        val engine: RegionEngine = KoinJavaComponent.get(RegionEngine::class.java)
        val tracker = engine.query(region, player) ?: return FactData(0)
        val distance = tracker.signedDistance(player.position, distanceMode) ?: return FactData(0)
        return FactData((distance * 100.0).roundToInt())
    }
}
