package com.typewritermc.core.utils.point

data class Position(
    override val world: World,
    override val x: Double = 0.0,
    override val y: Double = 0.0,
    override val z: Double = 0.0,
    override val yaw: Float = 0f,
    override val pitch: Float = 0f,
) : Point<Position>, Rotatable<Position>, WorldHolder<Position> {
    companion object {
        val ORIGIN = Position(World(""), 0.0, 0.0, 0.0, 0f, 0f)
    }

    override fun withX(x: Double): Position = copy(x = x)

    override fun withY(y: Double): Position = copy(y = y)

    override fun withZ(z: Double): Position = copy(z = z)

    override fun withYaw(yaw: Float): Position = copy(yaw = yaw)

    override fun withPitch(pitch: Float): Position = copy(pitch = pitch)

    override fun withRotation(yaw: Float, pitch: Float): Position = copy(yaw = yaw, pitch = pitch)

    override fun withWorld(world: World): Position = copy(world = world)

    override fun add(x: Double, y: Double, z: Double): Position {
        return copy(x = this.x + x, y = this.y + y, z = this.z + z)
    }

    override fun sub(x: Double, y: Double, z: Double): Position {
        return copy(x = this.x - x, y = this.y - y, z = this.z - z)
    }

    override fun mul(x: Double, y: Double, z: Double): Position {
        return copy(x = this.x * x, y = this.y * y, z = this.z * z)
    }

    override fun div(x: Double, y: Double, z: Double): Position {
        return copy(x = this.x / x, y = this.y / y, z = this.z / z)
    }

    fun mid(): Position {
        return toBlockPosition().add(0.5, 0.0, 0.5).rotate(yaw, pitch)
    }
}

fun <WP1, WP2> WP1.isInRange(point: WP2, range: Double): Boolean
        where WP1 : Point<WP1>, WP1 : WorldHolder<WP1>, WP2 : Point<WP2>, WP2 : WorldHolder<WP2> {
    if (this.world != point.world) return false
    return isInRange(point.x, point.y, point.z, range)
}

fun <WP1, WP2> WP1.distanceSqrt(point: WP2): Double?
        where WP1 : Point<WP1>, WP1 : WorldHolder<WP1>, WP2 : Point<WP2>, WP2 : WorldHolder<WP2> {
    if (this.world != point.world) return null
    return distanceSquared(point)
}

fun Position.toBlockPosition(): Position {
    return Position(world, blockX.toDouble(), blockY.toDouble(), blockZ.toDouble(), 0f, 0f)
}

fun Position.formatted(format: String = "x: %.0f, y: %.0f, z: %.0f"): String {
    return format.format(x, y, z, yaw, pitch)
}