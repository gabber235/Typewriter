package com.typewritermc.region.shape

import com.typewritermc.core.utils.point.Vector
import kotlin.math.abs
import kotlin.math.sqrt
import kotlin.math.withSign

/**
 * The closest point on an axis aligned ellipsoid, after David Eberly's "Distance from a
 * Point to an Ellipse, an Ellipsoid, or a Hyperellipsoid". Exact inside and out.
 *
 * The two cheaper estimates fail where consumers publish the number as a distance in
 * blocks. Projecting radially onto the surface lands on the wrong point for anything but a
 * sphere. Dividing the implicit function by the magnitude of its gradient measures against
 * the long axis near the center: inside radii (20, 2, 20) it reports a point 0.001 blocks
 * off center as 20 blocks deep, where the surface is 2 blocks away, and jumps 18 blocks
 * across a millionth of a block at the center itself.
 *
 * Every routine here takes radii sorted descending and coordinates already made
 * non negative, which is what lets the degenerate cases be enumerated at all.
 */
internal object EllipsoidDistance {
    /** Enough halvings to drive the bracket below the spacing of a double. */
    private const val MAX_BISECTIONS = 149

    /** How far off the smallest axis' plane a coordinate has to be for the bisection to resolve it. */
    private const val FLAT_PLANE_RATIO = 1e-12

    /** Distance from [point] to the surface of the ellipsoid with the given radii. */
    fun distance(radiusX: Double, radiusY: Double, radiusZ: Double, point: Vector): Double =
        solveOriented(radiusX, radiusY, radiusZ, point, DoubleArray(3))

    /** The point on the surface closest to [point]. */
    fun closestPoint(radiusX: Double, radiusY: Double, radiusZ: Double, point: Vector): Vector {
        val closest = DoubleArray(3)
        solveOriented(radiusX, radiusY, radiusZ, point, closest)
        return Vector(
            closest[0].withSign(point.x),
            closest[1].withSign(point.y),
            closest[2].withSign(point.z),
        )
    }

    /** Distance from ([x], [z]) to the outline of the ellipse with the given radii. */
    fun distanceToEllipse(radiusX: Double, radiusZ: Double, x: Double, z: Double): Double {
        val scratch = DoubleArray(3)
        return if (radiusX >= radiusZ) {
            solveEllipse(radiusX, radiusZ, abs(x), abs(z), scratch, 0, 1)
        } else {
            solveEllipse(radiusZ, radiusX, abs(z), abs(x), scratch, 0, 1)
        }
    }

    /**
     * Sorts the axes descending, mirrors the point into the first octant, and writes the
     * closest point back in that sorted frame.
     */
    private fun solveOriented(
        radiusX: Double,
        radiusY: Double,
        radiusZ: Double,
        point: Vector,
        closest: DoubleArray,
    ): Double {
        var first = 0
        var second = 1
        var third = 2
        fun radius(axis: Int) = when (axis) {
            0 -> radiusX
            1 -> radiusY
            else -> radiusZ
        }

        fun coordinate(axis: Int) = when (axis) {
            0 -> abs(point.x)
            1 -> abs(point.y)
            else -> abs(point.z)
        }

        if (radius(first) < radius(second)) {
            val swap = first; first = second; second = swap
        }
        if (radius(second) < radius(third)) {
            val swap = second; second = third; third = swap
        }
        if (radius(first) < radius(second)) {
            val swap = first; first = second; second = swap
        }

        val sorted = DoubleArray(3)
        val distance = solveEllipsoid(
            radius(first), radius(second), radius(third),
            coordinate(first), coordinate(second), coordinate(third),
            sorted,
        )
        closest[first] = sorted[0]
        closest[second] = sorted[1]
        closest[third] = sorted[2]
        return distance
    }

    private fun solveEllipsoid(
        e0: Double,
        e1: Double,
        e2: Double,
        y0: Double,
        y1: Double,
        y2: Double,
        closest: DoubleArray,
    ): Double {
        // Not `y2 > 0.0`: the bisection brackets the root at `y2 / e2 - 1`, so a coordinate this
        // close to the plane of the smallest axis leaves a bracket one rounding error wide. The
        // root that comes back is noise, and the distance built from it can even place the
        // closest point off the surface. Such a point is on the plane for every practical
        // purpose, and the solve below answers it exactly.
        if (y2 > e2 * FLAT_PLANE_RATIO) {
            if (y1 <= 0.0) {
                if (y0 <= 0.0) {
                    closest[0] = 0.0
                    closest[1] = 0.0
                    closest[2] = e2
                    return abs(y2 - e2)
                }
                closest[1] = 0.0
                return solveEllipse(e0, e2, y0, y2, closest, 0, 2)
            }
            if (y0 <= 0.0) {
                closest[0] = 0.0
                return solveEllipse(e1, e2, y1, y2, closest, 1, 2)
            }

            val z0 = y0 / e0
            val z1 = y1 / e1
            val z2 = y2 / e2
            val outside = z0 * z0 + z1 * z1 + z2 * z2 - 1.0
            if (outside == 0.0) {
                closest[0] = y0
                closest[1] = y1
                closest[2] = y2
                return 0.0
            }
            val r0 = (e0 / e2) * (e0 / e2)
            val r1 = (e1 / e2) * (e1 / e2)
            val root = ellipsoidRoot(r0, r1, z0, z1, z2, outside)
            // A point a rounding error off the smallest axis' plane collapses the bracket onto
            // its lower end, and these divisions would answer infinity, which reaches a barrier
            // as a NaN push. Such a point is on that plane for every practical purpose, so it
            // falls through to the solve that treats it as one.
            if (root + r0 > 0.0 && root + r1 > 0.0 && root + 1.0 > 0.0) {
                closest[0] = r0 * y0 / (root + r0)
                closest[1] = r1 * y1 / (root + r1)
                closest[2] = y2 / (root + 1.0)
                return length(closest[0] - y0, closest[1] - y1, closest[2] - y2)
            }
        }

        // On the plane of the smallest axis the closest point usually lifts off it, and the
        // usual root does not see that, so the lift is solved directly.
        val denominator0 = e0 * e0 - e2 * e2
        val denominator1 = e1 * e1 - e2 * e2
        val numerator0 = e0 * y0
        val numerator1 = e1 * y1
        if (numerator0 < denominator0 && numerator1 < denominator1) {
            val ratio0 = numerator0 / denominator0
            val ratio1 = numerator1 / denominator1
            val remainder = 1.0 - ratio0 * ratio0 - ratio1 * ratio1
            if (remainder > 0.0) {
                closest[0] = e0 * ratio0
                closest[1] = e1 * ratio1
                closest[2] = e2 * sqrt(remainder)
                return length(closest[0] - y0, closest[1] - y1, closest[2])
            }
        }
        closest[2] = 0.0
        return solveEllipse(e0, e1, y0, y1, closest, 0, 1)
    }

    private fun solveEllipse(
        e0: Double,
        e1: Double,
        y0: Double,
        y1: Double,
        closest: DoubleArray,
        axis0: Int,
        axis1: Int,
    ): Double {
        if (y1 > 0.0) {
            if (y0 <= 0.0) {
                closest[axis0] = 0.0
                closest[axis1] = e1
                return abs(y1 - e1)
            }

            val z0 = y0 / e0
            val z1 = y1 / e1
            val outside = z0 * z0 + z1 * z1 - 1.0
            if (outside == 0.0) {
                closest[axis0] = y0
                closest[axis1] = y1
                return 0.0
            }
            val r0 = (e0 / e1) * (e0 / e1)
            val root = ellipseRoot(r0, z0, z1, outside)
            // As in the ellipsoid solve above: a collapsed bracket would divide by zero here,
            // and the point belongs on the smaller axis' line anyway.
            if (root + r0 > 0.0 && root + 1.0 > 0.0) {
                closest[axis0] = r0 * y0 / (root + r0)
                closest[axis1] = y1 / (root + 1.0)
                return length(closest[axis0] - y0, closest[axis1] - y1)
            }
        }

        val denominator = e0 * e0 - e1 * e1
        val numerator = e0 * y0
        if (numerator < denominator) {
            val ratio = numerator / denominator
            closest[axis0] = e0 * ratio
            closest[axis1] = e1 * sqrt(1.0 - ratio * ratio)
            return length(closest[axis0] - y0, closest[axis1])
        }
        closest[axis0] = e0
        closest[axis1] = 0.0
        return abs(y0 - e0)
    }

    /**
     * Bisects for the Lagrange multiplier of the closest point, in units of the smallest
     * radius squared. The bracket starts at the multiplier that would put the closest point
     * on the smallest axis, which is what keeps an interior point from converging on the
     * far side of the long axis.
     */
    private fun ellipsoidRoot(r0: Double, r1: Double, z0: Double, z1: Double, z2: Double, outside: Double): Double {
        val n0 = r0 * z0
        val n1 = r1 * z1
        var low = z2 - 1.0
        var high = if (outside < 0.0) 0.0 else length(n0, n1, z2) - 1.0
        var root = 0.0
        repeat(MAX_BISECTIONS) {
            root = (low + high) / 2.0
            if (root == low || root == high) return root
            val ratio0 = n0 / (root + r0)
            val ratio1 = n1 / (root + r1)
            val ratio2 = z2 / (root + 1.0)
            val value = ratio0 * ratio0 + ratio1 * ratio1 + ratio2 * ratio2 - 1.0
            when {
                value > 0.0 -> low = root
                value < 0.0 -> high = root
                else -> return root
            }
        }
        return root
    }

    private fun ellipseRoot(r0: Double, z0: Double, z1: Double, outside: Double): Double {
        val n0 = r0 * z0
        var low = z1 - 1.0
        var high = if (outside < 0.0) 0.0 else length(n0, z1) - 1.0
        var root = 0.0
        repeat(MAX_BISECTIONS) {
            root = (low + high) / 2.0
            if (root == low || root == high) return root
            val ratio0 = n0 / (root + r0)
            val ratio1 = z1 / (root + 1.0)
            val value = ratio0 * ratio0 + ratio1 * ratio1 - 1.0
            when {
                value > 0.0 -> low = root
                value < 0.0 -> high = root
                else -> return root
            }
        }
        return root
    }

    private fun length(a: Double, b: Double): Double = sqrt(a * a + b * b)

    private fun length(a: Double, b: Double, c: Double): Double = sqrt(a * a + b * b + c * c)
}
