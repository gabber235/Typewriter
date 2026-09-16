package com.typewritermc.region.shape

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.utils.point.Vector
import kotlin.math.PI
import kotlin.math.pow
import kotlin.math.sqrt

@AlgebraicTypeInfo("ellipsoid_shape", Colors.PURPLE, "mdi:ellipse-outline")
data class EllipsoidShape(
    @Min(0)
    @Help("Half-extent along the local X axis.")
    @Default("1.0")
    val radiusX: Double = 1.0,
    @Min(0)
    @Help("Half-extent along the local Y axis (vertical before pitch).")
    @Default("1.0")
    val radiusY: Double = 1.0,
    @Min(0)
    @Help("Half-extent along the local Z axis.")
    @Default("1.0")
    val radiusZ: Double = 1.0,
) : Shape {
    init {
        require(radiusX >= 0.0 && radiusY >= 0.0 && radiusZ >= 0.0) {
            "Ellipsoid radii must be non-negative"
        }
    }

    override val usable: Boolean get() = radiusX > 0.0 && radiusY > 0.0 && radiusZ > 0.0

    override val localBounds: LocalBounds
        get() = LocalBounds(-radiusX, -radiusY, -radiusZ, radiusX, radiusY, radiusZ)

    override fun contains(localLoc: Vector): Boolean {
        // A zero radius collapses the ellipsoid to the single point at its own origin, which is
        // what [signedDistance] measures against, so nothing but that point is inside.
        if (radiusX == 0.0 || radiusY == 0.0 || radiusZ == 0.0) return localLoc.lengthSquared == 0.0
        val nx = localLoc.x / radiusX
        val ny = localLoc.y / radiusY
        val nz = localLoc.z / radiusZ
        return nx * nx + ny * ny + nz * nz <= 1.0
    }

    /**
     * The distance to the closest point on the surface, solved exactly by
     * [EllipsoidDistance]. Consumers publish this to the user as a distance in blocks and
     * the barrier ramps its push across it, so an estimate measured against the wrong axis
     * is not good enough. On radii (20, 2, 20) such an estimate reports 20 blocks of depth
     * just off center, where the surface is 2 blocks away, and the barrier never pushes.
     */
    override fun signedDistance(localLoc: Vector): Double {
        if (radiusX == 0.0 || radiusY == 0.0 || radiusZ == 0.0) return localLoc.length
        val distance = EllipsoidDistance.distance(radiusX, radiusY, radiusZ, localLoc)
        return if (contains(localLoc)) -distance else distance
    }

    /** The same exact solve applied to the XZ silhouette ellipse. */
    override fun signedDistanceHorizontal(localLoc: Vector): Double {
        if (radiusX == 0.0 || radiusZ == 0.0) {
            return sqrt(localLoc.x * localLoc.x + localLoc.z * localLoc.z)
        }
        val distance = EllipsoidDistance.distanceToEllipse(radiusX, radiusZ, localLoc.x, localLoc.z)
        val nx = localLoc.x / radiusX
        val nz = localLoc.z / radiusZ
        return if (nx * nx + nz * nz <= 1.0) -distance else distance
    }

    override fun nearestOutside(localLoc: Vector): Vector {
        if (radiusX == 0.0 || radiusY == 0.0 || radiusZ == 0.0) return Vector.ZERO
        return EllipsoidDistance.closestPoint(radiusX, radiusY, radiusZ, localLoc)
    }

    /**
     * The surface normal at the closest point, which is where a push out of the region has
     * to aim. The gradient at the player's own position points elsewhere entirely once the
     * axes differ, and so does any fixed axis: at the center of radii (20, 2, 20) the surface
     * is 2 blocks up, not 20 blocks sideways.
     */
    override fun outwardNormals(localLoc: Vector): List<Vector> {
        if (radiusX == 0.0 || radiusY == 0.0 || radiusZ == 0.0) return listOf(Vector(1.0, 0.0, 0.0))
        val surface = nearestOutside(localLoc)
        val nx = surface.x / (radiusX * radiusX)
        val ny = surface.y / (radiusY * radiusY)
        val nz = surface.z / (radiusZ * radiusZ)
        val len = sqrt(nx * nx + ny * ny + nz * nz)
        if (len < Vector.EPSILON) return listOf(Vector(1.0, 0.0, 0.0))
        return listOf(Vector(nx / len, ny / len, nz / len))
    }

    /**
     * Knud Thomsen's approximation, within about 1% for every axis ratio. A sphere of the
     * mean radius over counts badly once the axes differ: radii (1, 1, 50) would ask for
     * 3775 samples for a surface of 494, and the entity display spawns one entity per
     * sample.
     */
    private fun surfaceArea(): Double {
        val exponent = 1.6075
        val xy = (radiusX * radiusY).pow(exponent)
        val xz = (radiusX * radiusZ).pow(exponent)
        val yz = (radiusY * radiusZ).pow(exponent)
        return 4 * PI * ((xy + xz + yz) / 3.0).pow(1.0 / exponent)
    }

    override fun sampleBoundary(density: Double): Sequence<Vector> {
        if (radiusX == 0.0 || radiusY == 0.0 || radiusZ == 0.0) return sequenceOf(Vector.ZERO)
        return fibonacciSphereSamples(
            boundarySampleCount(surfaceArea(), density),
            Vector(radiusX, radiusY, radiusZ),
        )
    }
}
