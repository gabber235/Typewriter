package com.typewritermc.core.utils.point

import org.intellij.lang.annotations.Language
import java.util.Objects
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

        if (other is Point<*>) {
            if (other.x != x) return false
            if (other.y != y) return false
            if (other.z != z) return false
        }
        return true
    }

    override fun hashCode(): Int = Objects.hash(x, y, z)
}

fun Point<*>.toVector(): Vector {
    if (this is Vector) {
        return this
    }
    return Vector(x, y, z)
}
