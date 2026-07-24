package com.typewritermc.core.utils.point

import org.intellij.lang.annotations.Language
import java.util.*
import kotlin.math.sqrt

data class Vector(
    override val x: Double = 0.0,
    override val y: Double = 0.0,
    override val z: Double = 0.0,
) : Point<Vector> {
    constructor(x: Int, y: Int, z: Int) : this(x.toDouble(), y.toDouble(), z.toDouble())

    companion object {
        val ZERO = Vector(0.0, 0.0, 0.0)
        val UNIT = Vector(1.0, 1.0, 1.0)

        @Language("JSON")
        const val ZERO_JSON = "{\"x\": 0.0, \"y\": 0.0, \"z\": 0.0}"

        @Language("JSON")
        const val UNIT_JSON = "{\"x\": 1.0, \"y\": 1.0, \"z\": 1.0}"
        const val EPSILON: Double = 0.000001
    }

    val lengthSquared: Double
        get() = x * x + y * y + z * z

    val length: Double
        get() = sqrt(lengthSquared)


    fun lerp(other: Vector, alpha: Double): Vector {
        return Vector(
            x = lerp(x, other.x, alpha),
            y = lerp(y, other.y, alpha),
            z = lerp(z, other.z, alpha),
        )
    }

    override fun withX(x: Double): Vector = copy(x = x)

    override fun withY(y: Double): Vector = copy(y = y)

    override fun withZ(z: Double): Vector = copy(z = z)

    override fun add(x: Double, y: Double, z: Double): Vector {
        return Vector(this.x + x, this.y + y, this.z + z)
    }

    override fun sub(x: Double, y: Double, z: Double): Vector {
        return Vector(this.x - x, this.y - y, this.z - z)
    }

    override fun mul(x: Double, y: Double, z: Double): Vector {
        return Vector(this.x * x, this.y * y, this.z * z)
    }

    override fun div(x: Double, y: Double, z: Double): Vector {
        return Vector(this.x / x, this.y / y, this.z / z)
    }

    /**
     * Computes the dot product between this vector and another vector.
     *
     * Use this to calculate projections, determine if vectors are perpendicular (result = 0),
     * or measure similarity in direction (positive = same direction, negative = opposite).
     *
     * @param other the vector to compute the dot product with
     * @return the dot product value
     */
    fun dot(other: Vector): Double {
        return x * other.x + y * other.y + z * other.z
    }

    /**
     * Computes the cross product between this vector and another vector.
     *
     * The result is perpendicular to both inputs, with a length equal to the area of the
     * parallelogram they span. Use this to build a basis around a direction, or to get the
     * normal of a plane through two vectors.
     *
     * @param other the vector to compute the cross product with
     * @return the vector perpendicular to both
     */
    fun cross(other: Vector): Vector = Vector(
        y * other.z - z * other.y,
        z * other.x - x * other.z,
        x * other.y - y * other.x,
    )

    fun normalize(): Vector {
        val length = length
        return if (length < EPSILON) {
            ZERO
        } else {
            div(length)
        }
    }

    private fun lerp(a: Double, b: Double, alpha: Double): Double {
        return a + alpha * (b - a)
    }

    fun mid(): Vector {
        return Vector(x.toInt() + 0.5, y.toInt().toDouble(), z.toInt() + 0.5)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (other !is Point<*>) return false

        return other.x == x && other.y == y && other.z == z
    }

    override fun hashCode(): Int = Objects.hash(x, y, z)
}

fun Point<*>.toVector(): Vector {
    if (this is Vector) {
        return this
    }
    return Vector(x, y, z)
}
