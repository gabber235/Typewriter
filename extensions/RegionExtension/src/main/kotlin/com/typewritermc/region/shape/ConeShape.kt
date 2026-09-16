package com.typewritermc.region.shape

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Max
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.utils.point.Vector
import kotlin.math.*

/**
 * Spherical cone (vision cone) aligned with the local +Z axis. Points within angle
 * [halfAngleDegrees] of +Z and within [length] of the origin are inside.
 */
@AlgebraicTypeInfo("cone_shape", Colors.PURPLE, "mdi:cone")
data class ConeShape(
    @Min(0)
    @Help("How far the cone reaches from its point.")
    @Default("5.0")
    val length: Double = 5.0,
    @Min(1)
    @Max(89)
    @Help("Half-angle of the cone in degrees. A wider angle opens the cone; 89 is nearly a half sphere.")
    @Default("30.0")
    val halfAngleDegrees: Double = 30.0,
) : Shape {
    init {
        require(length >= 0.0) { "Cone length must be non-negative, was $length" }
        require(halfAngleDegrees in 0.0..90.0) {
            "Cone half-angle must be in [0, 90] degrees, was $halfAngleDegrees"
        }
    }

    private val halfAngleRad: Double get() = Math.toRadians(halfAngleDegrees)
    private val rimRadius: Double get() = length * sin(halfAngleRad)

    override val usable: Boolean get() = length > 0.0 && halfAngleDegrees > 0.0

    override val localBounds: LocalBounds
        get() = LocalBounds(-rimRadius, -rimRadius, 0.0, rimRadius, rimRadius, length)

    override fun contains(localLoc: Vector): Boolean {
        val r = sqrt(localLoc.x * localLoc.x + localLoc.y * localLoc.y + localLoc.z * localLoc.z)
        if (r > length) return false
        if (r < Vector.EPSILON) return true
        val cosAngle = localLoc.z / r
        return cosAngle >= cos(halfAngleRad)
    }

    override fun signedDistance(localLoc: Vector): Double {
        val projection = project(localLoc)
        return if (contains(localLoc)) -projection.distance else projection.distance
    }

    /**
     * Exact because the cone is axisymmetric about +Z: the silhouette equals the Y = 0
     * slice, and the nearest cone point to a point in that plane stays in that plane.
     */
    override fun signedDistanceHorizontal(localLoc: Vector): Double =
        signedDistance(Vector(localLoc.x, 0.0, localLoc.z))

    override fun nearestOutside(localLoc: Vector): Vector = project(localLoc).point

    override fun outwardNormals(localLoc: Vector): List<Vector> = listOf(project(localLoc).normal)

    /**
     * The nearest point on the cone's boundary, its distance, and the outward normal there.
     *
     * The boundary has four features and each one owns a region of space: the spherical cap
     * closing the far end, the lateral surface running from the apex to the rim, the rim
     * circle where those two meet, and the apex itself. Which feature is nearest decides all
     * three answers, so they are computed together rather than rediscovered per method.
     * A lateral normal reported for a point past the cap would send a KeepIn barrier's push
     * along the cone's axis, away from the region, instead of back into it.
     */
    private fun project(localLoc: Vector): ConeProjection {
        val horizontal = sqrt(localLoc.x * localLoc.x + localLoc.y * localLoc.y)
        val radius = sqrt(horizontal * horizontal + localLoc.z * localLoc.z)
        if (radius < Vector.EPSILON) return ConeProjection(0.0, Vector.ZERO, Vector(0.0, 0.0, -1.0))

        // Any meridian will do on the axis: the cone is symmetric about it.
        val meridianX = if (horizontal < Vector.EPSILON) 1.0 else localLoc.x / horizontal
        val meridianY = if (horizontal < Vector.EPSILON) 0.0 else localLoc.y / horizontal

        val angle = atan2(horizontal, localLoc.z)
        val delta = angle - halfAngleRad
        val lateral = radius * cos(delta)

        if (delta <= 0.0) {
            val toCap = abs(length - radius)
            val toLateral = radius * sin(-delta)
            if (radius >= length || toCap <= toLateral) {
                val scale = length / radius
                return ConeProjection(
                    toCap,
                    Vector(localLoc.x * scale, localLoc.y * scale, localLoc.z * scale),
                    Vector(localLoc.x / radius, localLoc.y / radius, localLoc.z / radius),
                )
            }
            return lateralProjection(toLateral, lateral, meridianX, meridianY)
        }

        if (lateral <= 0.0) {
            return ConeProjection(
                radius,
                Vector.ZERO,
                Vector(localLoc.x / radius, localLoc.y / radius, localLoc.z / radius),
            )
        }

        if (lateral >= length) {
            val rim = Vector(meridianX * rimRadius, meridianY * rimRadius, length * cos(halfAngleRad))
            val toRimX = localLoc.x - rim.x
            val toRimY = localLoc.y - rim.y
            val toRimZ = localLoc.z - rim.z
            val toRim = sqrt(toRimX * toRimX + toRimY * toRimY + toRimZ * toRimZ)
            if (toRim < Vector.EPSILON) {
                return ConeProjection(0.0, rim, lateralNormal(meridianX, meridianY))
            }
            return ConeProjection(toRim, rim, Vector(toRimX / toRim, toRimY / toRim, toRimZ / toRim))
        }

        return lateralProjection(radius * sin(delta), lateral, meridianX, meridianY)
    }

    private fun lateralProjection(
        distance: Double,
        lateral: Double,
        meridianX: Double,
        meridianY: Double,
    ): ConeProjection {
        val footRadius = lateral * sin(halfAngleRad)
        val foot = Vector(meridianX * footRadius, meridianY * footRadius, lateral * cos(halfAngleRad))
        return ConeProjection(distance, foot, lateralNormal(meridianX, meridianY))
    }

    private fun lateralNormal(meridianX: Double, meridianY: Double): Vector = Vector(
        meridianX * cos(halfAngleRad),
        meridianY * cos(halfAngleRad),
        -sin(halfAngleRad),
    )

    private data class ConeProjection(val distance: Double, val point: Vector, val normal: Vector)

    /**
     * Samples the lateral surface up to where it meets the spherical cap, then the cap
     * itself, so every sample lies on the exact boundary [signedDistance] reports. The
     * cap's last latitude ring is the rim the lateral surface already ends on, so the cap
     * stops one ring short of it and no sample is emitted twice.
     */
    override fun sampleBoundary(density: Double): Sequence<Vector> = sequence {
        if (length <= 0.0 || halfAngleDegrees <= 0.0) return@sequence
        val surfaceArea = PI * rimRadius * length + 2 * PI * length * length * (1 - cos(halfAngleRad))
        val step = sampleStep(density, surfaceArea)

        val lateralEnd = length * cos(halfAngleRad)
        for (t in axisSamples(0.0, lateralEnd, step)) {
            val r = t * tan(halfAngleRad)
            if (r < Vector.EPSILON) {
                yield(Vector(0.0, 0.0, t))
                continue
            }
            // Each ring is sized on its own, not for the rim: a ring near the apex is a fraction
            // of the rim's circumference, and giving it the rim's count crowds the tip and
            // exhausts the budget.
            val ringSamples = max(4, (2 * PI * r / step).toInt())
            for (i in 0 until ringSamples) {
                val theta = 2 * PI * i / ringSamples
                yield(Vector(cos(theta) * r, sin(theta) * r, t))
            }
        }

        val phis = axisSamples(0.0, halfAngleRad, step / length)
        for (phiIndex in 0 until phis.size - 1) {
            val phi = phis[phiIndex]
            val r = length * sin(phi)
            val z = length * cos(phi)
            if (r < Vector.EPSILON) {
                yield(Vector(0.0, 0.0, z))
                continue
            }
            val ringPoints = max(4, (2 * PI * r / step).toInt())
            for (i in 0 until ringPoints) {
                val theta = 2 * PI * i / ringPoints
                yield(Vector(cos(theta) * r, sin(theta) * r, z))
            }
        }
    }.withinSampleBudget()
}
