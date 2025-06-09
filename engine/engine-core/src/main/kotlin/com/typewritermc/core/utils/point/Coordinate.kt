package com.typewritermc.core.utils.point

import java.util.*
import kotlin.math.atan2
import kotlin.math.sqrt

data class Coordinate(
    override val x: Double = 0.0,
    override val y: Double = 0.0,
    override val z: Double = 0.0,
    override val yaw: Float = 0f,
    override val pitch: Float = 0f,
) : Point<Coordinate>, Rotatable<Coordinate> {

    companion object {
        val ORIGIN = Coordinate(0.0, 0.0, 0.0, 0f, 0f)
    }

    override fun withX(x: Double): Coordinate = copy(x = x)

    override fun withY(y: Double): Coordinate = copy(y = y)

    override fun withZ(z: Double): Coordinate = copy(z = z)

    override fun withYaw(yaw: Float): Coordinate = copy(yaw = yaw)

    override fun withPitch(pitch: Float): Coordinate = copy(pitch = pitch)

    override fun withRotation(yaw: Float, pitch: Float): Coordinate = copy(yaw = yaw, pitch = pitch)

    override fun rotate(yaw: Float, pitch: Float): Coordinate = copy(yaw = this.yaw + yaw, pitch = this.pitch + pitch)

    override fun add(x: Double, y: Double, z: Double): Coordinate {
        return copy(x = this.x + x, y = this.y + y, z = this.z + z)
    }

    override fun sub(x: Double, y: Double, z: Double): Coordinate {
        return copy(x = this.x - x, y = this.y - y, z = this.z - z)
    }

    override fun mul(x: Double, y: Double, z: Double): Coordinate {
        return copy(x = this.x * x, y = this.y * y, z = this.z * z)
    }

    override fun div(x: Double, y: Double, z: Double): Coordinate {
        return copy(x = this.x / x, y = this.y / y, z = this.z / z)
    }

    override fun equals(other: Any?): Boolean {
        if (this === other) return true

        if (other is Point<*>) {
            if (other.x != x) return false
            if (other.y != y) return false
            if (other.z != z) return false
        }
        if (other is Rotatable<*>) {
            if (other.yaw != yaw) return false
            if (other.pitch != pitch) return false
        }
        return true
    }

    override fun hashCode(): Int = Objects.hash(x, y, z, yaw, pitch)
}

/**
 * Rotates to look at the specified point.
 *
 * @param point the point to look at
 * @return a new instance with the updated yaw and pitch angles
 */
fun <RP> RP.lookAt(point: Point<*>): RP where RP : Point<RP>, RP : Rotatable<RP> {
    val x = point.x - this.x
    val y = point.y - this.y
    val z = point.z - this.z

    val yaw = Math.toDegrees(atan2(x, z)).toFloat()
    val pitch = Math.toDegrees(atan2(y, sqrt(x.squared() + z.squared()))).toFloat()

    return this.withRotation(yaw, pitch)
}

fun <RP> RP.lerp(to: RP, amount: Double): RP where RP : Point<RP>, RP : Rotatable<RP> {
    val percent = amount.coerceIn(0.0, 1.0)
    val x = this.x + (to.x - this.x) * percent
    val y = this.y + (to.y - this.y) * percent
    val z = this.z + (to.z - this.z) * percent
    val yaw = this.yaw + (correctYaw(this.yaw, to.yaw) - this.yaw) * percent
    val pitch = this.pitch + (to.pitch - this.pitch) * percent

    return withX(x).withY(y).withZ(z).withRotation(yaw.toFloat(), pitch.toFloat())
}


fun Coordinate.toPosition(world: World) =
    Position(world, x, y, z, yaw, pitch)