package com.typewritermc.region.data

import com.typewritermc.core.utils.point.Vector
import kotlin.math.acos
import kotlin.math.cos
import kotlin.math.sin

/**
 * A 3x3 rotation matrix, row major: the world orientation the region's three stored
 * angles (yaw, pitch, roll) describe, applied to local offsets.
 */
internal class Matrix3(
    val m00: Double, val m01: Double, val m02: Double,
    val m10: Double, val m11: Double, val m12: Double,
    val m20: Double, val m21: Double, val m22: Double,
) {
    operator fun times(v: Vector): Vector = Vector(
        m00 * v.x + m01 * v.y + m02 * v.z,
        m10 * v.x + m11 * v.y + m12 * v.z,
        m20 * v.x + m21 * v.y + m22 * v.z,
    )

    /** Applies the inverse rotation: for a rotation matrix the transpose is the inverse. */
    fun transposedTimes(v: Vector): Vector = Vector(
        m00 * v.x + m10 * v.y + m20 * v.z,
        m01 * v.x + m11 * v.y + m21 * v.z,
        m02 * v.x + m12 * v.y + m22 * v.z,
    )
}

/**
 * The rotation the three stored angles describe: Minecraft yaw about the vertical axis,
 * then pitch about the local horizontal axis, then roll about the local facing (+Z) axis.
 * With roll zero this is exactly the yaw and pitch convention the transform always had.
 */
internal fun rotationMatrix(yawDegrees: Float, pitchDegrees: Float, rollDegrees: Float): Matrix3 {
    val cy = cos(Math.toRadians(yawDegrees.toDouble()))
    val sy = sin(Math.toRadians(yawDegrees.toDouble()))
    val cp = cos(Math.toRadians(pitchDegrees.toDouble()))
    val sp = sin(Math.toRadians(pitchDegrees.toDouble()))
    val cr = cos(Math.toRadians(rollDegrees.toDouble()))
    val sr = sin(Math.toRadians(rollDegrees.toDouble()))
    return Matrix3(
        cy * cr - sy * sp * sr, -cy * sr - sy * sp * cr, -sy * cp,
        cp * sr, cp * cr, -sp,
        sy * cr + cy * sp * sr, -sy * sr + cy * sp * cr, cy * cp,
    )
}

/** How far the region leans from upright, whichever mix of pitch and roll produced it. */
internal fun tiltDegrees(pitchDegrees: Float, rollDegrees: Float): Double {
    val upY = cos(Math.toRadians(pitchDegrees.toDouble())) * cos(Math.toRadians(rollDegrees.toDouble()))
    return Math.toDegrees(acos(upY.coerceIn(-1.0, 1.0)))
}
