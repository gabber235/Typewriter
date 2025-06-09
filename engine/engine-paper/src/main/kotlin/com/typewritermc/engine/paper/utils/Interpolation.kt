package com.typewritermc.engine.paper.utils

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.correctYaw

/**
 * Use catmull-rom interpolation to get a point between a list of points.
 */
fun List<Position>.interpolate(percentage: Double): Position {
    val currentPart = percentage * (size - 1)
    val index = currentPart.toInt()
    val subPercentage = currentPart - index

    val previousPoint = getOrNull(index - 1) ?: this[index]
    val currentPoint = this[index]
    val nextPoint = getOrNull(index + 1) ?: currentPoint
    val nextNextPoint = getOrNull(index + 2) ?: nextPoint

    return interpolatePoints(previousPoint, currentPoint, nextPoint, nextNextPoint, subPercentage)
}

/**
 * Use catmull-rom interpolation to get a point between four points.
 */
fun interpolatePoints(
    previousPoint: Position,
    currentPoint: Position,
    nextPoint: Position,
    nextNextPoint: Position,
    percentage: Double,
): Position {
    val x = interpolatePoints(
        previousPoint.x,
        currentPoint.x,
        nextPoint.x,
        nextNextPoint.x,
        percentage,
    )
    val y = interpolatePoints(
        previousPoint.y,
        currentPoint.y,
        nextPoint.y,
        nextNextPoint.y,
        percentage,
    )
    val z = interpolatePoints(
        previousPoint.z,
        currentPoint.z,
        nextPoint.z,
        nextNextPoint.z,
        percentage,
    )

    val previousYaw = previousPoint.yaw.toDouble()
    val currentYaw = correctYaw(previousYaw, currentPoint.yaw.toDouble())
    val nextYaw = correctYaw(currentYaw, nextPoint.yaw.toDouble())
    val nextNextYaw = correctYaw(nextYaw, nextNextPoint.yaw.toDouble())
    val yaw = interpolatePoints(
        previousYaw,
        currentYaw,
        nextYaw,
        nextNextYaw,
        percentage,
    )

    val pitch = interpolatePoints(
        previousPoint.pitch.toDouble(),
        currentPoint.pitch.toDouble(),
        nextPoint.pitch.toDouble(),
        nextNextPoint.pitch.toDouble(),
        percentage,
    )

    return Position(
        currentPoint.world,
        x,
        y,
        z,
        yaw.toFloat(),
        pitch.toFloat(),
    )
}

/**
 * Use catmull-rom interpolation to get a point between four points.
 */
fun interpolatePoints(
    previousPoint: Double,
    currentPoint: Double,
    nextPoint: Double,
    nextNextPoint: Double,
    percentage: Double,
): Double {
    val square = percentage * percentage
    val cube = square * percentage

    return 0.5 * (
            (2 * currentPoint) +
                    (-previousPoint + nextPoint) * percentage +
                    (2 * previousPoint - 5 * currentPoint + 4 * nextPoint - nextNextPoint) * square +
                    (-previousPoint + 3 * currentPoint - 3 * nextPoint + nextNextPoint) * cube
            )
}


