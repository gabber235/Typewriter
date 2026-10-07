package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import kotlin.math.PI
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

/**
 * Fibonacci sphere distribution of [count] points on the unit sphere. Each point is scaled
 * componentwise by [scale]. A scale of `(r, r, r)` samples a sphere and `(rx, ry, rz)`
 * samples an ellipsoid.
 */
internal fun fibonacciSphereSamples(count: Int, scale: Vector): Sequence<Vector> = sequence {
    if (count <= 0) {
        yield(Vector.ZERO)
        return@sequence
    }
    val golden = PI * (3.0 - sqrt(5.0))
    val denom = (count - 1).coerceAtLeast(1).toDouble()
    for (i in 0 until count) {
        val y = 1.0 - (i.toDouble() / denom) * 2.0
        val r = sqrt(1.0 - y * y)
        val theta = golden * i
        yield(Vector(cos(theta) * r * scale.x, y * scale.y, sin(theta) * r * scale.z))
    }
}
