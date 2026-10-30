package com.typewritermc.region.entries.variable

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.entry.entries.safeCast
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.region.RegionEngine
import com.typewritermc.region.data.DistanceMode
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData
import org.koin.java.KoinJavaComponent

@Entry("region_boundary_distance_variable", "Signed distance from a region boundary (Double)", Colors.GREEN, "mdi:ruler")
@GenericConstraint(Double::class)
@VariableData(BoundaryDistanceVariableData::class)
/**
 * Full precision counterpart of `BoundaryDistanceFact`. Returns a `Double`: negative
 * inside, positive outside, zero on the boundary. Use this in `Var<Double>` slots where
 * the centimeter scaled fact loses precision.
 *
 * A region that cannot be measured at all reads as zero, the same as standing exactly on the
 * boundary. That happens when the region entry is missing, when its placement variable does
 * not resolve, or when the player is in another world.
 *
 * ## How could this be used?
 *
 * Drive a particle radius variable from boundary distance to create a halo effect that
 * shrinks the closer the player is to the wall.
 */
class BoundaryDistanceVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val player = context.player
        val data = context.getData<BoundaryDistanceVariableData>()
            ?: throw ContextDataNotFoundException(context.klass, context.data)
        val engine: RegionEngine = KoinJavaComponent.get(RegionEngine::class.java)
        val tracker = engine.query(data.region, player)
        val distance: Double = tracker?.signedDistance(player.position, data.distanceMode) ?: 0.0
        return context.safeCast(distance)
            ?: throw IllegalStateException("Could not cast Double to ${context.klass}")
    }
}

data class BoundaryDistanceVariableData(
    @Help("The region whose boundary distance to publish.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
    @Help("How the distance is measured. Horizontal ignores the floor and ceiling faces and measures against the region's vertical silhouette.")
    val distanceMode: DistanceMode = DistanceMode.FULL,
)
