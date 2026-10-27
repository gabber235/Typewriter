package com.typewritermc.entity.entries.activity

import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.distanceSquaredWeightedY
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import kotlin.math.abs

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

/**
 * Decides whether the entity may advance past the path node it is currently steering towards.
 *
 * A node counts as passed once the entity arrives within the arrival radius. Other nodes on walkable
 * ground may also be passed early within the wider pass radius, which rounds corners instead of forcing
 * the entity onto every block center. The early pass needs [isShortcutClear] to confirm the entity can
 * walk straight on to the following node, so it is not taken around a fence post or wall corner the
 * skipped node was steering around. Nodes that [requiresArrival], such as the last one, never allow the
 * shortcut, and elevation changes always require actual arrival so jumps and steps target the correct block.
 */
internal fun canAdvancePastNode(
    location: PositionProperty,
    nodeTarget: PositionProperty,
    requiresArrival: Boolean,
    maxStepHeight: Double,
    arrivalRadiusSquared: Double,
    passRadiusSquared: Double,
    isShortcutClear: () -> Boolean,
): Boolean {
    val arrived = (location.distanceSquaredWeightedY(nodeTarget, 0.8) ?: return false) <= arrivalRadiusSquared
    if (arrived) return true
    if (requiresArrival) return false

    val dx = nodeTarget.x - location.x
    val dz = nodeTarget.z - location.z
    if (dx * dx + dz * dz > passRadiusSquared) return false
    if (abs(nodeTarget.y - location.y) > maxStepHeight) return false
    return isShortcutClear()
}
