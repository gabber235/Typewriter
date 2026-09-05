package com.typewritermc.region.shape

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.utils.point.Vector
import kotlin.math.abs
import kotlin.math.max
import kotlin.math.min
import kotlin.math.sqrt

/**
 * Axis aligned cuboid centered at the local origin, with half extents along each axis.
 *
 * The region transform places the cuboid's center, not a corner. To anchor by a corner,
 * set the region's offset accordingly.
 */
@AlgebraicTypeInfo("cuboid_shape", Colors.PURPLE, "mdi:cube-outline")
data class CuboidShape(
    @Min(0)
    @Help("Distance from the center to the east and west faces. The full width is twice this.")
    @Default("1.0")
    val halfX: Double = 1.0,
    @Min(0)
    @Help("Distance from the center to the floor and ceiling. The full height is twice this.")
    @Default("1.0")
    val halfY: Double = 1.0,
    @Min(0)
    @Help("Distance from the center to the north and south faces. The full depth is twice this.")
    @Default("1.0")
    val halfZ: Double = 1.0,
) : Shape {
    init {
        require(halfX >= 0.0 && halfY >= 0.0 && halfZ >= 0.0) {
            "Cuboid half-extents must be non-negative, were ($halfX, $halfY, $halfZ)"
        }
    }

    override val usable: Boolean get() = halfX > 0.0 && halfY > 0.0 && halfZ > 0.0

    override val localBounds: LocalBounds
        get() = LocalBounds(-halfX, -halfY, -halfZ, halfX, halfY, halfZ)

    override fun contains(localLoc: Vector): Boolean =
        abs(localLoc.x) <= halfX && abs(localLoc.y) <= halfY && abs(localLoc.z) <= halfZ

    override fun signedDistance(localLoc: Vector): Double {
        val dx = abs(localLoc.x) - halfX
        val dy = abs(localLoc.y) - halfY
        val dz = abs(localLoc.z) - halfZ
        val outside = sqrt(max(dx, 0.0).sq() + max(dy, 0.0).sq() + max(dz, 0.0).sq())
        val inside = min(max(dx, max(dy, dz)), 0.0)
        return outside + inside
    }

    override fun signedDistanceHorizontal(localLoc: Vector): Double {
        val dx = abs(localLoc.x) - halfX
        val dz = abs(localLoc.z) - halfZ
        val outside = sqrt(max(dx, 0.0).sq() + max(dz, 0.0).sq())
        val inside = min(max(dx, dz), 0.0)
        return outside + inside
    }

    override fun nearestOutside(localLoc: Vector): Vector {
        return Vector(
            localLoc.x.coerceIn(-halfX, halfX),
            localLoc.y.coerceIn(-halfY, halfY),
            localLoc.z.coerceIn(-halfZ, halfZ),
        ).let { clamped ->
            if (contains(localLoc)) {
                val gx = halfX - abs(localLoc.x)
                val gy = halfY - abs(localLoc.y)
                val gz = halfZ - abs(localLoc.z)
                when (min(gx, min(gy, gz))) {
                    gx -> Vector(if (localLoc.x >= 0) halfX else -halfX, localLoc.y, localLoc.z)
                    gy -> Vector(localLoc.x, if (localLoc.y >= 0) halfY else -halfY, localLoc.z)
                    else -> Vector(localLoc.x, localLoc.y, if (localLoc.z >= 0) halfZ else -halfZ)
                }
            } else clamped
        }
    }

    override fun outwardNormals(localLoc: Vector): List<Vector> {
        // Past a corner or an edge the distance field's gradient is the direction away from the
        // closest surface point, and it is what the barrier and the push follow. Naming one face
        // normal per axis the point overshoots averages to a fixed 45 degrees instead, which
        // aims somewhere the surface is not and swings the moment the player crosses a face
        // plane. The multiple normals still describe a point standing on the corner itself.
        outsideDirection(localLoc)?.let { return listOf(it) }

        val normals = mutableListOf<Vector>()
        if (abs(abs(localLoc.x) - halfX) < EDGE_EPSILON || abs(localLoc.x) > halfX) {
            normals.add(Vector(if (localLoc.x >= 0) 1.0 else -1.0, 0.0, 0.0))
        }
        if (abs(abs(localLoc.y) - halfY) < EDGE_EPSILON || abs(localLoc.y) > halfY) {
            normals.add(Vector(0.0, if (localLoc.y >= 0) 1.0 else -1.0, 0.0))
        }
        if (abs(abs(localLoc.z) - halfZ) < EDGE_EPSILON || abs(localLoc.z) > halfZ) {
            normals.add(Vector(0.0, 0.0, if (localLoc.z >= 0) 1.0 else -1.0))
        }
        if (normals.isEmpty()) {
            val gx = halfX - abs(localLoc.x)
            val gy = halfY - abs(localLoc.y)
            val gz = halfZ - abs(localLoc.z)
            normals += when (min(gx, min(gy, gz))) {
                gx -> Vector(if (localLoc.x >= 0) 1.0 else -1.0, 0.0, 0.0)
                gy -> Vector(0.0, if (localLoc.y >= 0) 1.0 else -1.0, 0.0)
                else -> Vector(0.0, 0.0, if (localLoc.z >= 0) 1.0 else -1.0)
            }
        }
        return normals
    }

    /** The unit direction away from the closest surface point, or `null` for a point not outside. */
    private fun outsideDirection(localLoc: Vector): Vector? {
        if (signedDistance(localLoc) <= EDGE_EPSILON) return null
        val offset = localLoc - nearestOutside(localLoc)
        if (offset.length <= EDGE_EPSILON) return null
        return offset.normalize()
    }

    /**
     * Samples the six faces on evenly divided grids whose rows land exactly on the edges,
     * with every edge and corner point emitted exactly once. Duplicate free samples matter
     * for the entity boundary display, which spawns one entity per sample.
     */
    override fun sampleBoundary(density: Double): Sequence<Vector> = sequence {
        val surfaceArea = 8.0 * (halfX * halfY + halfY * halfZ + halfX * halfZ)
        val step = sampleStep(density, surfaceArea)
        val xs = axisSamples(-halfX, halfX, step)
        val ys = axisSamples(-halfY, halfY, step)
        val zs = axisSamples(-halfZ, halfZ, step)

        for (x in xs) for (z in zs) {
            yield(Vector(x, -halfY, z))
            if (halfY > 0.0) yield(Vector(x, halfY, z))
        }
        for (yIndex in 1 until ys.size - 1) {
            val y = ys[yIndex]
            for (x in xs) {
                yield(Vector(x, y, -halfZ))
                if (halfZ > 0.0) yield(Vector(x, y, halfZ))
            }
            for (zIndex in 1 until zs.size - 1) {
                val z = zs[zIndex]
                yield(Vector(-halfX, y, z))
                if (halfX > 0.0) yield(Vector(halfX, y, z))
            }
        }
    }.withinSampleBudget()

    companion object {
        private const val EDGE_EPSILON = 1e-6
    }
}

private fun Double.sq(): Double = this * this
