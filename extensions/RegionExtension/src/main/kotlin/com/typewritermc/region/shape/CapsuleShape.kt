package com.typewritermc.region.shape

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.utils.point.Vector
import kotlin.math.*

/**
 * Capsule aligned with the local Y axis: two hemispheres of [radius] capped on a cylinder
 * of half height [halfHeight]. Total length along Y is `2 * (halfHeight + radius)`.
 */
@AlgebraicTypeInfo("capsule_shape", Colors.PURPLE, "mdi:pill")
data class CapsuleShape(
    @Min(0)
    @Help("Radius of the capsule, both of its rounded ends and of the column between them.")
    @Default("1.0")
    val radius: Double = 1.0,
    @Min(0)
    @Help("Distance from the center to where each rounded end begins, before the radius is added.")
    @Default("1.0")
    val halfHeight: Double = 1.0,
) : Shape {
    init {
        require(radius >= 0.0 && halfHeight >= 0.0) {
            "Capsule dimensions must be non-negative, were (radius=$radius, halfHeight=$halfHeight)"
        }
    }

    override val usable: Boolean get() = radius > 0.0

    override val localBounds: LocalBounds
        get() = LocalBounds(-radius, -(halfHeight + radius), -radius, radius, halfHeight + radius, radius)

    private fun spineY(y: Double): Double = y.coerceIn(-halfHeight, halfHeight)

    override fun contains(localLoc: Vector): Boolean {
        val dy = localLoc.y - spineY(localLoc.y)
        return localLoc.x * localLoc.x + dy * dy + localLoc.z * localLoc.z <= radius * radius
    }

    override fun signedDistance(localLoc: Vector): Double {
        val dy = localLoc.y - spineY(localLoc.y)
        val d = sqrt(localLoc.x * localLoc.x + dy * dy + localLoc.z * localLoc.z)
        return d - radius
    }

    override fun signedDistanceHorizontal(localLoc: Vector): Double =
        sqrt(localLoc.x * localLoc.x + localLoc.z * localLoc.z) - radius

    override fun nearestOutside(localLoc: Vector): Vector {
        val spine = spineRelative(localLoc)
        if (spine.len < Vector.EPSILON) return Vector(radius, spine.sy, 0.0)
        val scale = radius / spine.len
        return Vector(spine.dx * scale, spine.sy + spine.dy * scale, spine.dz * scale)
    }

    override fun outwardNormals(localLoc: Vector): List<Vector> {
        val spine = spineRelative(localLoc)
        if (spine.len < Vector.EPSILON) return listOf(Vector(1.0, 0.0, 0.0))
        return listOf(Vector(spine.dx / spine.len, spine.dy / spine.len, spine.dz / spine.len))
    }

    /**
     * The offset of [localLoc] from the nearest point on the capsule's spine segment,
     * together with the length of that offset.
     */
    private fun spineRelative(localLoc: Vector): SpineProjection {
        val sy = spineY(localLoc.y)
        val dx = localLoc.x
        val dy = localLoc.y - sy
        val dz = localLoc.z
        return SpineProjection(sy, dx, dy, dz, sqrt(dx * dx + dy * dy + dz * dz))
    }

    private data class SpineProjection(val sy: Double, val dx: Double, val dy: Double, val dz: Double, val len: Double)

    /**
     * Samples the cylinder wall on rings whose end rings land exactly on the hemisphere
     * seams, then each hemisphere in latitude rings. The seam rings belong to the wall, so
     * the hemispheres start past them, and the pole rings collapse to single points, so no
     * sample is emitted twice.
     */
    override fun sampleBoundary(density: Double): Sequence<Vector> = sequence {
        if (radius <= 0.0) return@sequence
        val surfaceArea = 4 * PI * radius * radius + 4 * PI * radius * halfHeight
        val step = sampleStep(density, surfaceArea)
        val ringSamples = max(8, (2 * PI * radius / step).toInt())
        for (y in axisSamples(-halfHeight, halfHeight, step)) {
            for (i in 0 until ringSamples) {
                val theta = 2 * PI * i / ringSamples
                yield(Vector(cos(theta) * radius, y, sin(theta) * radius))
            }
        }
        val slices = max(4, (ringSamples / 4))
        for (j in 1..slices) {
            val phi = (PI / 2) * j / slices
            val r = cos(phi) * radius
            val cap = sin(phi) * radius
            if (r < Vector.EPSILON) {
                yield(Vector(0.0, halfHeight + cap, 0.0))
                yield(Vector(0.0, -halfHeight - cap, 0.0))
                continue
            }
            // Each ring is sized on its own, like the cone's. Giving a ring near the pole the
            // equator's count asks for roughly PI/2 times the budget, and the truncation that
            // follows removes whole samples from one end, so both caps disappear instead of
            // thinning out.
            val capSamples = max(4, (2 * PI * r / step).toInt())
            for (i in 0 until capSamples) {
                val theta = 2 * PI * i / capSamples
                yield(Vector(cos(theta) * r, halfHeight + cap, sin(theta) * r))
                yield(Vector(cos(theta) * r, -halfHeight - cap, sin(theta) * r))
            }
        }
    }.withinSampleBudget()
}
