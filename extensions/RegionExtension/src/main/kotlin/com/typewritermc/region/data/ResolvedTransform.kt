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
            val rotatedOffset = rotateOffset(offset, yawDegrees)
            return ResolvedTransform(
                world = origin.world,
                worldOrigin = Vector(
                    origin.x + rotatedOffset.x,
                    origin.y + rotatedOffset.y,
                    origin.z + rotatedOffset.z,
                ),
                yawDegrees = yawDegrees,
                pitchDegrees = pitchDegrees,
                rollDegrees = rollDegrees,
            )
        }

        /**
         * The placement a region definition resolves to from its placement values. The
         * runtime tracker, the in game editor and the workspace all resolve through this,
         * so what the editor draws is what the region does once published.
         *
         * With [rotateWithOrigin] the origin's own yaw and pitch are added to [yawDegrees]
         * and [pitchDegrees], which is what turns a region with the entity it is anchored to.
         */
        fun resolve(
            origin: Position,
            offset: Vector,
            yawDegrees: Float,
            pitchDegrees: Float,
            rollDegrees: Float,
            rotateWithOrigin: Boolean,
        ): ResolvedTransform {
            val yaw = if (rotateWithOrigin) yawDegrees + origin.yaw else yawDegrees
            val pitch = if (rotateWithOrigin) pitchDegrees + origin.pitch else pitchDegrees
            return fromOriginAndOffset(origin, offset, yaw, pitch, rollDegrees)
        }

        /**
         * The inverse of [resolve] for the anchor: where the origin has to sit so the region
         * resolves with its [worldOrigin] at [anchor]. The origin keeps [facingYaw] and
         * [facingPitch], which [resolve] adds to [yawDegrees] when [rotateWithOrigin] is set.
         * Editors placing a region by its visible anchor store this, so a configured offset
         * does not displace the region from where it was put.
         */
        fun originForAnchor(
            world: World,
            anchor: Vector,
            offset: Vector,
            yawDegrees: Float,
            rotateWithOrigin: Boolean,
            facingYaw: Float = 0f,
            facingPitch: Float = 0f,
        ): Position {
            val yaw = if (rotateWithOrigin) yawDegrees + facingYaw else yawDegrees
            val rotatedOffset = rotateOffset(offset, yaw)
            return Position(
                world,
                anchor.x - rotatedOffset.x,
                anchor.y - rotatedOffset.y,
                anchor.z - rotatedOffset.z,
                facingYaw,
                facingPitch,
            )
        }

        /** [offset] turned by the yaw: its horizontal components only, Y stays vertical. */
        private fun rotateOffset(offset: Vector, yawDegrees: Float): Vector {
            val yaw = Math.toRadians(yawDegrees.toDouble())
            val cosYaw = cos(yaw)
            val sinYaw = sin(yaw)
            return Vector(
                cosYaw * offset.x - sinYaw * offset.z,
                offset.y,
                sinYaw * offset.x + cosYaw * offset.z,
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
