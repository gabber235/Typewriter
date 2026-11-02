package com.typewritermc.region.content

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.shape.LocalBounds
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.shape.raycastBoundary
import kotlin.math.abs

/** A region the workspace can target: its identity and resolved geometry. */
internal data class TargetCandidate(
    val id: String,
    val transform: ResolvedTransform,
    val shape: Shape,
)

/**
 * The region under the crosshair, in two tiers. A region the eye is outside of competes
 * with the boundary the ray enters through; a region the eye is inside of competes with
 * the boundary the ray exits through. Entry hits always beat exit hits: standing inside a
 * large region, every ray leaves it through some stretch of floor or wall, and letting
 * that exit compete would make the surrounding region win every aim at a smaller one.
 *
 * Within a tier the nearest hit wins. Aiming at a wall from inside nested regions selects
 * the region that wall belongs to. `null` when the ray crosses no boundary within [range].
 */
internal fun pickTargetedRegion(
    candidates: List<TargetCandidate>,
    eye: Vector,
    direction: Vector,
    range: Double,
): String? {
    var bestEntryId: String? = null
    var bestEntryDistance = Double.MAX_VALUE
    var bestExitId: String? = null
    var bestExitDistance = Double.MAX_VALUE

    for (candidate in candidates) {
        val localEye = candidate.transform.toLocal(eye)
        val localDirection = (candidate.transform.toLocal(eye + direction) - localEye).normalize()
        // raycastBoundary steps at a fixed interval, so it costs the same whether the ray comes
        // near the region or not. The bounding box contains the shape, so a ray missing the
        // box cannot cross the boundary, and no crossing lies past where the ray leaves it.
        val reach = boundsExit(candidate.shape.localBounds, localEye, localDirection, range) ?: continue
        val hit = candidate.shape.raycastBoundary(localEye, localDirection, reach) ?: continue
        val distance = (hit - localEye).length
        if (candidate.shape.contains(localEye)) {
            if (distance < bestExitDistance) {
                bestExitDistance = distance
                bestExitId = candidate.id
            }
        } else {
            if (distance < bestEntryDistance) {
                bestEntryDistance = distance
                bestEntryId = candidate.id
            }
        }
    }
    return bestEntryId ?: bestExitId
}

/**
 * How far along the ray the shape can still be reached: where the ray leaves [bounds], capped
 * at [range], or `null` when the ray never enters them. The box is grown by [BOUNDS_SLACK] so
 * a boundary exactly on a face is not cut off by rounding.
 */
private fun boundsExit(bounds: LocalBounds, eye: Vector, direction: Vector, range: Double): Double? {
    var entry = 0.0
    var exit = range
    for (axis in 0..2) {
        val origin = axis.pick(eye)
        val step = axis.pick(direction)
        val low = axis.pick(Vector(bounds.minX, bounds.minY, bounds.minZ)) - BOUNDS_SLACK
        val high = axis.pick(Vector(bounds.maxX, bounds.maxY, bounds.maxZ)) + BOUNDS_SLACK
        if (abs(step) < 1e-9) {
            if (origin < low || origin > high) return null
            continue
        }
        val near = (low - origin) / step
        val far = (high - origin) / step
        entry = maxOf(entry, minOf(near, far))
        exit = minOf(exit, maxOf(near, far))
        if (entry > exit) return null
    }
    return exit
}

private fun Int.pick(vector: Vector): Double = when (this) {
    0 -> vector.x
    1 -> vector.y
    else -> vector.z
}

private const val BOUNDS_SLACK = 0.5
