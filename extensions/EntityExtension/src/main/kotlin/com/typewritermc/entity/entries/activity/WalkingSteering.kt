package com.typewritermc.entity.entries.activity

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entity.PositionProperty

private const val LEVEL_HEAD_DISTANCE_SQUARED = 0.75 * 0.75

/**
 * Computes the smoothed look rotation while walking towards [lookTarget].
 *
 * Path nodes sit at ground level, so when the target is horizontally underneath the entity
 * there is no meaningful direction to face and aiming at it would pitch the head straight
 * down at the ground. In that case the pitch eases back to level and the yaw stays.
 */
internal fun walkingLookRotation(
    location: PositionProperty,
    lookTarget: Vector,
    yawVelocity: Velocity,
    pitchVelocity: Velocity,
    smoothTime: Float = 0.2f,
): Pair<Float, Float> {
    val dx = lookTarget.x - location.x
    val dy = lookTarget.y - location.y
    val dz = lookTarget.z - location.z

    if (dx * dx + dz * dz < LEVEL_HEAD_DISTANCE_SQUARED) {
        return location.yaw to smoothDamp(location.pitch, 0f, pitchVelocity, smoothTime)
    }

    return updateLookDirection(
        LookDirection(location.yaw, location.pitch),
        LookDirection(getLookYaw(dx, dz), getLookPitch(dx, dy, dz)),
        yawVelocity,
        pitchVelocity,
        smoothTime,
    )
}
