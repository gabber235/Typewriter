package com.typewritermc.core.utils.point

import kotlin.math.cos
import kotlin.math.sin

/**
 * Interface representing a rotatable object with yaw and pitch angles.
 */
interface Rotatable<R : Rotatable<R>> {
    /**
     * The yaw angle in degrees.
     */
    val yaw: Float

    /**
     * The pitch angle in degrees.
     */
    val pitch: Float

    /**
     * Creates a new instance with the specified yaw angle.
     *
     * @param yaw the new yaw angle
     * @return a new instance with the updated yaw angle
     */
    fun withYaw(yaw: Float): R

    /**
     * Creates a new instance with the specified pitch angle.
     *
     * @param pitch the new pitch angle
     * @return a new instance with the updated pitch angle
     */
    fun withPitch(pitch: Float): R

    /**
     * Creates a new instance with the specified yaw and pitch angles.
     *
     * @param yaw the new yaw angle
     * @param pitch the new pitch angle
     * @return a new instance with the updated yaw and pitch angles
     */
    fun withRotation(yaw: Float, pitch: Float): R

    /**
     * Rotates the yaw angle by the specified amount.
     *
     * @param angle the amount to rotate the yaw angle by
     * @return a new instance with the updated yaw angle
     */
    fun rotateYaw(angle: Float) = withYaw(yaw + angle)

    /**
     * Rotates the pitch angle by the specified amount.
     *
     * @param angle the amount to rotate the pitch angle by
     * @return a new instance with the updated pitch angle
     */
    fun rotatePitch(angle: Float) = withPitch(pitch + angle)

    /**
     * Rotates both the yaw and pitch angles by the specified amounts.
     *
     * @param yaw the amount to rotate the yaw angle by
     * @param pitch the amount to rotate the pitch angle by
     * @return a new instance with the updated yaw and pitch angles
     */
    fun rotate(yaw: Float, pitch: Float) = withRotation(this.yaw + yaw, this.pitch + pitch)

    /**
     * Resets the rotation to the default values (yaw = 0, pitch = 0).
     *
     * @return a new instance with the default yaw and pitch angles
     */
    fun resetRotation(): R = withRotation(0f, 0f)

    /**
     * Gets the direction vector based on the current yaw and pitch angles.
     *
     * @return the direction vector
     */
    fun directionVector(): Vector {
        val radYaw = Math.toRadians(yaw.toDouble())
        val radPitch = Math.toRadians(pitch.toDouble())
        val x = -cos(radPitch) * sin(radYaw)
        val y = -sin(radPitch)
        val z = cos(radPitch) * cos(radYaw)
        return Vector(x, y, z)
    }
}