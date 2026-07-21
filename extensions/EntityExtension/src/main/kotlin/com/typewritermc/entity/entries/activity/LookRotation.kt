package com.typewritermc.entity.entries.activity

import kotlin.math.abs
import kotlin.math.atan2
import kotlin.math.max

fun normalizeYaw(yaw: Float): Float {
    return (yaw + 180) % 360 - 180
}

class Velocity(var value: Float)

fun smoothDamp(
    current: Float,
    target: Float,
    currentVelocity: Velocity,
    smoothTime: Float,
    maxSpeed: Float = Float.POSITIVE_INFINITY,
    deltaTime: Float = 1f / 20f // For 20 ticks per second
): Float {
    val smoothTime = smoothTime.coerceAtLeast(0.0001f)
    val omega = 2f / smoothTime

    val x = omega * deltaTime
    val exp = 1f / (1f + x + 0.48f * x * x + 0.235f * x * x * x)
    var change = current - target

    // Clamp maximum speed
    val maxChange = maxSpeed * smoothTime
    change = change.coerceIn(-maxChange, maxChange)
    val targetTemp = current - change

    val temp = (currentVelocity.value + omega * change) * deltaTime
    currentVelocity.value = (currentVelocity.value - omega * temp) * exp
    var output = targetTemp + (change + temp) * exp

    // Prevent overshooting
    if (target - current > 0f == output > target) {
        output = target
        currentVelocity.value = (output - target) / deltaTime
    }

    return output
}

fun getLookYaw(dx: Double, dz: Double): Float {
    val radians = atan2(dz, dx)
    val degrees = Math.toDegrees(radians).toFloat() - 90
    if (degrees < -180) return degrees + 360
    if (degrees > 180) return degrees - 360
    return degrees
}

fun getLookPitch(dx: Double, dy: Double, dz: Double): Float {
    val radians = -atan2(dy, max(abs(dx), abs(dz)))
    return Math.toDegrees(radians).toFloat()
}

data class LookDirection(
    val yaw: Float,
    val pitch: Float,
)

fun updateLookDirection(
    current: LookDirection,
    target: LookDirection,
    yawVelocity: Velocity,
    pitchVelocity: Velocity,
    smoothTime: Float = 0.2f
): Pair<Float, Float> {
    val correctedYaw = if (current.yaw - target.yaw > 180) {
        current.yaw - 360
    } else if (current.yaw - target.yaw < -180) {
        current.yaw + 360
    } else {
        current.yaw
    }

    val yaw = smoothDamp(correctedYaw, target.yaw, yawVelocity, smoothTime)
    val pitch = smoothDamp(current.pitch, target.pitch, pitchVelocity, smoothTime)

    return yaw to pitch
}
