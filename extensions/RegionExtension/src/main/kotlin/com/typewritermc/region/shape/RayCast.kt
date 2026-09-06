package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import kotlin.math.abs
import kotlin.math.min

private const val RAY_STEP = 0.25
private const val RAY_MAX_DISTANCE = 192.0
private const val RAY_BISECTIONS = 12
private const val RAY_REFINEMENTS = 8
private const val PROJECTION_ITERATIONS = 3
private const val GRADIENT_EPSILON = 0.01
private const val PROJECTION_TOLERANCE = 0.05

/**
 * The first point on the shape's boundary along the local ray from [origin] in [direction] (a
 * unit vector), or `null` when the ray does not cross the boundary within [maxDistance].
 *
 * The ray is stepped at a fixed interval and the crossing bisected, rather than sphere traced.
 * A sphere trace needs a true distance field in every direction, which a rotated prism does not
 * give, so it can step through a thin wall.
 */
fun Shape.raycastBoundary(
    origin: Vector,
    direction: Vector,
    maxDistance: Double = RAY_MAX_DISTANCE,
): Vector? {
    var behind = 0.0
    var behindDistance = signedDistance(origin)
    var travelled = RAY_STEP

    while (travelled <= maxDistance) {
        val distance = signedDistance(origin + direction * travelled)
        if (distance < 0.0 != behindDistance < 0.0) {
            return bisectCrossing(origin, direction, behind, behindDistance, travelled)
        }
        // A step can enter and leave again between two samples: without the finer scan, a ray
        // grazing a sphere's silhouette or crossing a cone near its apex reads as a clean miss.
        // Only a step that came within its own length of the surface pays for the finer scan,
        // measured on both sides: inside the shape both distances are negative, and comparing
        // them signed would rescan every step of a ray cast from inside a region.
        if (min(abs(distance), abs(behindDistance)) < RAY_STEP) {
            refineCrossing(origin, direction, behind, behindDistance, travelled)?.let { return it }
        }
        behind = travelled
        behindDistance = distance
        travelled += RAY_STEP
    }
    return null
}

/**
 * Rescans one march interval at [RAY_REFINEMENTS] times the resolution, for the crossing pair
 * the coarse march stepped over. `null` when the interval really does not cross.
 */
private fun Shape.refineCrossing(
    origin: Vector,
    direction: Vector,
    start: Double,
    startDistance: Double,
    end: Double,
): Vector? {
    var low = start
    var lowDistance = startDistance
    for (step in 1..RAY_REFINEMENTS) {
        val at = start + (end - start) * step / RAY_REFINEMENTS
        val distance = signedDistance(origin + direction * at)
        if (distance < 0.0 != lowDistance < 0.0) {
            return bisectCrossing(origin, direction, low, lowDistance, at)
        }
        low = at
        lowDistance = distance
    }
    return null
}

private fun Shape.bisectCrossing(
    origin: Vector,
    direction: Vector,
    start: Double,
    startDistance: Double,
    end: Double,
): Vector {
    var low = start
    var lowDistance = startDistance
    var high = end
    repeat(RAY_BISECTIONS) {
        val middle = (low + high) / 2.0
        val distance = signedDistance(origin + direction * middle)
        if (distance < 0.0 != lowDistance < 0.0) {
            high = middle
        } else {
            low = middle
            lowDistance = distance
        }
    }
    return origin + direction * ((low + high) / 2.0)
}

/**
 * The point on the boundary nearest to [local], by Newton steps along the numeric gradient of
 * the signed distance. `null` where the gradient vanishes, like the exact center of a sphere,
 * or where the steps do not converge within [PROJECTION_TOLERANCE]: a polygon prism near its
 * corners or a cone have a signed distance that is only a bound, not an exact distance field,
 * and Newton steps on a bound can bounce around a kink instead of settling on the boundary.
 */
fun Shape.nearestBoundaryPoint(local: Vector): Vector? {
    var point = local
    repeat(PROJECTION_ITERATIONS) {
        val distance = signedDistance(point)
        val gradient = Vector(
            signedDistance(point + Vector(GRADIENT_EPSILON, 0.0, 0.0)) -
                    signedDistance(point - Vector(GRADIENT_EPSILON, 0.0, 0.0)),
            signedDistance(point + Vector(0.0, GRADIENT_EPSILON, 0.0)) -
                    signedDistance(point - Vector(0.0, GRADIENT_EPSILON, 0.0)),
            signedDistance(point + Vector(0.0, 0.0, GRADIENT_EPSILON)) -
                    signedDistance(point - Vector(0.0, 0.0, GRADIENT_EPSILON)),
        )
        val length = gradient.length
        if (length < 1e-9) return null
        point -= gradient * (distance / length)
    }
    if (abs(signedDistance(point)) > PROJECTION_TOLERANCE) return null
    return point
}
