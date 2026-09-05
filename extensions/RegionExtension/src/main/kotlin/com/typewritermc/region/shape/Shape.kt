package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.region.data.rotationMatrix
import kotlin.math.sqrt

/**
 * A local frame geometric primitive. Shapes have no notion of world position; they answer
 * geometric queries about a point already expressed in the shape's local coordinate system.
 *
 * The owning region is responsible for inverse transforming world positions before calling.
 *
 * The interface is sealed so the Typewriter editor knows the full set of concrete shape
 * variants for the inline region inspector. New shapes are added by extending this interface and tagging
 * the implementation with `@AlgebraicTypeInfo`.
 */
sealed interface Shape {
    /**
     * `false` when the fields do not describe a volume: a polygon of fewer than three points or
     * of points in a straight line, a radius or an extent left at zero. Such a shape answers
     * every query as "nothing is inside", which is the hardest kind of failure for a builder to
     * diagnose, so the engine names its definition in the console instead.
     */
    val usable: Boolean get() = true

    /**
     * The axis aligned bounding box of the shape in local coordinates. Used for cheap
     * rejection before exact queries.
     */
    val localBounds: LocalBounds

    /**
     * `true` when the local frame point is inside (or on the boundary of) the shape.
     */
    fun contains(localLoc: Vector): Boolean

    /**
     * Signed distance from the point to the shape's boundary. Negative inside, positive
     * outside, zero on the boundary.
     */
    fun signedDistance(localLoc: Vector): Double

    /**
     * Signed distance from the point to the shape's vertical silhouette, measured in the
     * local XZ plane. The local Y coordinate is ignored, so floor and ceiling faces do
     * not contribute. For a region without pitch this is the world horizontal distance;
     * with a pitched region the local XZ plane tilts along with the shape.
     */
    fun signedDistanceHorizontal(localLoc: Vector): Double

    /**
     * The closest point on the shape that lies on or outside the boundary. For a point
     * already outside, this is the closest boundary point; for an interior point, this is
     * the boundary point with the smallest outward distance.
     */
    fun nearestOutside(localLoc: Vector): Vector

    /**
     * Outward unit normals at (or relative to) the local frame point. Returns multiple
     * normals when the nearest boundary feature is a corner/edge where two or more faces
     * meet (a cuboid corner returns up to three). Smooth shapes return one.
     */
    fun outwardNormals(localLoc: Vector): List<Vector>

    /**
     * A sampling of points on the shape's boundary. Density is the number of samples per
     * unit of boundary area. Implementations interpret it best effort.
     */
    fun sampleBoundary(density: Double): Sequence<Vector>
}

/**
 * Unit direction of the average of [normals], or `null` when there is no meaningful
 * direction (no normals, or normals that cancel out). Consumers of [Shape.outwardNormals]
 * use this to turn a corner's multiple normals into a single push direction.
 */
fun averageUnitDirection(normals: List<Vector>): Vector? {
    if (normals.isEmpty()) return null

    var x = 0.0
    var y = 0.0
    var z = 0.0
    for ((normalX, normalY, normalZ) in normals) {
        x += normalX
        y += normalY
        z += normalZ
    }

    val length = sqrt(x * x + y * y + z * z)
    if (length < 1e-6) return null
    return Vector(x / length, y / length, z / length)
}

/**
 * Axis aligned bounding box in local coordinates. Inclusive on both ends.
 */
data class LocalBounds(
    val minX: Double,
    val minY: Double,
    val minZ: Double,
    val maxX: Double,
    val maxY: Double,
    val maxZ: Double,
) {
    /**
     * Returns the smallest [LocalBounds] containing the AABB after the region's stored
     * rotation: yaw about the vertical axis, pitch about the local horizontal axis, roll
     * about the local facing axis. Used for spatial pre filtering of dynamic regions
     * whose rotation resolved this tick.
     */
    fun rotated(yawDegrees: Float, pitchDegrees: Float, rollDegrees: Float = 0f): LocalBounds {
        if (yawDegrees == 0f && pitchDegrees == 0f && rollDegrees == 0f) return this

        val rotation = rotationMatrix(yawDegrees, pitchDegrees, rollDegrees)

        var newMinX = Double.POSITIVE_INFINITY
        var newMinY = Double.POSITIVE_INFINITY
        var newMinZ = Double.POSITIVE_INFINITY
        var newMaxX = Double.NEGATIVE_INFINITY
        var newMaxY = Double.NEGATIVE_INFINITY
        var newMaxZ = Double.NEGATIVE_INFINITY

        for (cornerX in 0..1) for (cornerY in 0..1) for (cornerZ in 0..1) {
            val corner = rotation * Vector(
                if (cornerX == 0) minX else maxX,
                if (cornerY == 0) minY else maxY,
                if (cornerZ == 0) minZ else maxZ,
            )

            newMinX = minOf(newMinX, corner.x)
            newMaxX = maxOf(newMaxX, corner.x)
            newMinY = minOf(newMinY, corner.y)
            newMaxY = maxOf(newMaxY, corner.y)
            newMinZ = minOf(newMinZ, corner.z)
            newMaxZ = maxOf(newMaxZ, corner.z)
        }

        return LocalBounds(newMinX, newMinY, newMinZ, newMaxX, newMaxY, newMaxZ)
    }
}
