package com.typewritermc.engine.paper.entry.entity

import com.typewritermc.core.utils.point.*
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.utils.toPosition
import java.util.*

data class PositionProperty(
    override val world: World,
    override val x: Double,
    override val y: Double,
    override val z: Double,
    override val yaw: Float,
    override val pitch: Float,
) : EntityProperty, Point<PositionProperty>, Rotatable<PositionProperty>, WorldHolder<PositionProperty> {
    fun distanceSqrt(other: org.bukkit.Location): Double? {
        if (world.identifier != other.world.uid.toString()) return null
        return distanceSqrt(other.toPosition())
    }

    override fun withX(x: Double) = copy(x = x)

    override fun withY(y: Double) = copy(y = y)

    override fun withZ(z: Double) = copy(z = z)

    override fun withYaw(yaw: Float) = copy(yaw = yaw)

    override fun withPitch(pitch: Float) = copy(pitch = pitch)

    override fun withRotation(yaw: Float, pitch: Float) = copy(yaw = yaw, pitch = pitch)

    override fun withWorld(world: World) = copy(world = world)

    override fun add(x: Double, y: Double, z: Double): PositionProperty {
        return copy(x = this.x + x, y = this.y + y, z = this.z + z)
    }

    override fun sub(x: Double, y: Double, z: Double) = copy(x = this.x - x, y = this.y - y, z = this.z - z)

    override fun mul(x: Double, y: Double, z: Double) = copy(x = this.x * x, y = this.y * y, z = this.z * z)

    override fun div(x: Double, y: Double, z: Double) = copy(x = this.x / x, y = this.y / y, z = this.z / z)

    fun toPosition() = Position(world, x, y, z, yaw, pitch)

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
        if (other is WorldHolder<*>) {
            if (other.world != world) return false
        }
        return true
    }

    override fun hashCode(): Int = Objects.hash(x, y, z, yaw, pitch, world)

    companion object : SinglePropertyCollectorSupplier<PositionProperty>(PositionProperty::class) {
        val ORIGIN = PositionProperty(World(""), 0.0, 0.0, 0.0, 0f, 0f)
    }
}

fun org.bukkit.Location.toProperty(): PositionProperty {
    return PositionProperty(World(world.uid.toString()), x, y, z, yaw, pitch)
}

fun Position.toProperty(): PositionProperty {
    return PositionProperty(world, x, y, z, yaw, pitch)
}

fun Coordinate.toProperty(world: World): PositionProperty {
    return PositionProperty(world, x, y, z, yaw, pitch)
}
