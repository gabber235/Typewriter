package com.typewritermc.region.shape

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Min
import com.typewritermc.core.utils.point.Vector
import kotlin.math.PI
import kotlin.math.max
import kotlin.math.sqrt

@AlgebraicTypeInfo("sphere_shape", Colors.PURPLE, "mdi:sphere")
data class SphereShape(
    @Min(0)
    @Help("Sphere radius in blocks.")
    @Default("1.0")
    val radius: Double = 1.0,
) : Shape {
    init {
        require(radius >= 0.0) { "Sphere radius must be non-negative, was $radius" }
    }

    override val usable: Boolean get() = radius > 0.0

    override val localBounds: LocalBounds
        get() = LocalBounds(-radius, -radius, -radius, radius, radius, radius)

    override fun contains(localLoc: Vector): Boolean = localLoc.lengthSquared <= radius * radius

    override fun signedDistance(localLoc: Vector): Double = localLoc.length - radius

    override fun signedDistanceHorizontal(localLoc: Vector): Double =
        sqrt(localLoc.x * localLoc.x + localLoc.z * localLoc.z) - radius

    override fun nearestOutside(localLoc: Vector): Vector {
        val len = localLoc.length
        if (len < Vector.EPSILON) return Vector(radius, 0.0, 0.0)
        val scale = radius / len
        return Vector(localLoc.x * scale, localLoc.y * scale, localLoc.z * scale)
    }

    override fun outwardNormals(localLoc: Vector): List<Vector> {
        val len = localLoc.length
        if (len < Vector.EPSILON) return listOf(Vector(1.0, 0.0, 0.0))
        return listOf(Vector(localLoc.x / len, localLoc.y / len, localLoc.z / len))
    }

    override fun sampleBoundary(density: Double): Sequence<Vector> {
        if (radius <= 0.0) return sequenceOf(Vector.ZERO)
        val surfaceArea = 4.0 * PI * radius * radius
        return fibonacciSphereSamples(boundarySampleCount(surfaceArea, density), Vector(radius, radius, radius))
    }
}
