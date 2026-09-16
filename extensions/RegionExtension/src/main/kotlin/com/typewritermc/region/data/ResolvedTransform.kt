package com.typewritermc.region.data

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.World
import kotlin.math.cos
import kotlin.math.sin

/**
 * The world placement of a region, resolved for one viewer.
 *
 * [worldOrigin] is the anchor point: the resolved `origin` plus the yaw rotated `offset`.
 * [yawDegrees] and [pitchDegrees] rotate the shape around that anchor, following
 * Minecraft's convention: the shape's local +Z axis maps to the world direction an entity
 * with that yaw and pitch faces. This lets placement variables be tied directly to an
 * entity's yaw/pitch. [rollDegrees] then turns the shape around that facing axis, which lets a
 * region tilt in any vertical plane, not only the one its yaw faces.
 *
 * The rotation matrix is computed once per resolve, so callers that repeatedly map
 * between world and local space do not pay for the trigonometry per conversion.
 */
data class ResolvedTransform(
    val world: World,
    val worldOrigin: Vector,
    val yawDegrees: Float,
    val pitchDegrees: Float,
    val rollDegrees: Float = 0f,
) {
    private val basis: Matrix3 = rotationMatrix(yawDegrees, pitchDegrees, rollDegrees)

    companion object {
        /**
         * Builds a transform from the placement variables. The offset is rotated by
         * yaw (its horizontal components only; Y is always vertical), then added to the
         * origin to produce the world anchor.
         */
        fun fromOriginAndOffset(
            origin: Position,
            offset: Vector,
            yawDegrees: Float,
            pitchDegrees: Float,
            rollDegrees: Float = 0f,
        ): ResolvedTransform {
            val yaw = Math.toRadians(yawDegrees.toDouble())
            val cosYaw = cos(yaw)
            val sinYaw = sin(yaw)
            val rotatedOffsetX = cosYaw * offset.x - sinYaw * offset.z
            val rotatedOffsetZ = sinYaw * offset.x + cosYaw * offset.z
            return ResolvedTransform(
                world = origin.world,
                worldOrigin = Vector(
                    origin.x + rotatedOffsetX,
                    origin.y + offset.y,
                    origin.z + rotatedOffsetZ,
                ),
                yawDegrees = yawDegrees,
                pitchDegrees = pitchDegrees,
                rollDegrees = rollDegrees,
            )
        }
    }

    /**
     * Converts a world space vector to the local frame of this transform.
     */
    fun toLocal(worldVec: Vector): Vector = basis.transposedTimes(
        Vector(
            worldVec.x - worldOrigin.x,
            worldVec.y - worldOrigin.y,
            worldVec.z - worldOrigin.z,
        ),
    )

    /**
     * Converts a local frame vector to world coordinates.
     */
    fun toWorld(localVec: Vector): Vector {
        val rotated = rotateLocalToWorld(localVec)
        return Vector(worldOrigin.x + rotated.x, worldOrigin.y + rotated.y, worldOrigin.z + rotated.z)
    }

    fun toWorldPosition(localVec: Vector): Position {
        val world = toWorld(localVec)
        return Position(this.world, world.x, world.y, world.z)
    }

    /**
     * Rotates a local frame direction (e.g. an outward normal) into world coordinates
     * without applying [worldOrigin] translation.
     */
    fun rotateLocalToWorld(localDir: Vector): Vector = basis * localDir
}
