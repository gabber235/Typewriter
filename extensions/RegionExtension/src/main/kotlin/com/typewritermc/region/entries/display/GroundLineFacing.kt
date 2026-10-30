package com.typewritermc.region.entries.display

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.AlgebraicTypeInfo
import com.typewritermc.core.utils.point.Vector
import kotlin.math.atan2

/**
 * Which way the entities on a ground line look.
 *
 * Independent of the animation, except that "along the line" means the way the entities are
 * actually travelling, so it turns around with a counter clockwise flow.
 */
sealed interface GroundLineFacing {
    /** [travelDirection] is `1` along the path's point order and `-1` against it. */
    fun yaw(point: PathPoint, travelDirection: Int): Float
}

@AlgebraicTypeInfo("outward", Colors.GREEN, "mdi:arrow-expand-horizontal")
class FaceOutward : GroundLineFacing {
    override fun yaw(point: PathPoint, travelDirection: Int): Float = yawOf(point.outward)

    override fun equals(other: Any?): Boolean = other is FaceOutward
    override fun hashCode(): Int = javaClass.hashCode()
}

@AlgebraicTypeInfo("inward", Colors.GREEN, "mdi:arrow-collapse-horizontal")
class FaceInward : GroundLineFacing {
    override fun yaw(point: PathPoint, travelDirection: Int): Float = yawOf(point.outward * -1.0)

    override fun equals(other: Any?): Boolean = other is FaceInward
    override fun hashCode(): Int = javaClass.hashCode()
}

@AlgebraicTypeInfo("along_line", Colors.GREEN, "mdi:arrow-right")
class FaceAlongLine : GroundLineFacing {
    override fun yaw(point: PathPoint, travelDirection: Int): Float =
        yawOf(point.tangent * travelDirection.toDouble())

    override fun equals(other: Any?): Boolean = other is FaceAlongLine
    override fun hashCode(): Int = javaClass.hashCode()
}

@AlgebraicTypeInfo("against_line", Colors.GREEN, "mdi:arrow-left")
class FaceAgainstLine : GroundLineFacing {
    override fun yaw(point: PathPoint, travelDirection: Int): Float =
        yawOf(point.tangent * -travelDirection.toDouble())

    override fun equals(other: Any?): Boolean = other is FaceAgainstLine
    override fun hashCode(): Int = javaClass.hashCode()
}

private fun yawOf(direction: Vector): Float {
    if (direction == Vector.ZERO) return 0f
    return Math.toDegrees(atan2(-direction.x, direction.z)).toFloat()
}
