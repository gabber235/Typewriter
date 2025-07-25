package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.utils.point.Coordinate
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.*
import java.lang.Math.toRadians
import kotlin.math.cos
import kotlin.math.sin

@Entry(
    "origin_position_variable",
    "Rotates the position around an origin",
    Colors.GREEN,
    "solar:map-point-wave-bold"
)
@GenericConstraint(Position::class)
@GenericConstraint(Coordinate::class)
@GenericConstraint(Vector::class)
@VariableData(OriginPositionVariableData::class)
/**
 * The `OriginPositionVariable` is a variable that returns the position relative to the origin.
 *
 * The origin might have a yawn and pitch, in which case it will be assumed that everything needs to be rotated
 * around that origin.
 *
 * ## How could this be used?
 * For a cinematic where the location and rotation of the camera needs to be relative and rotated around a specific point.
 * Like an over the shoulder camera.
 */
class OriginPositionVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val player = context.player
        val data = context.getData<OriginPositionVariableData>()
            ?: throw ContextDataNotFoundException(context.klass, context.data)

        val origin = data.origin.get(player, context.interactionContext)
        val relative = data.relative.get(player, context.interactionContext)

        var rotatedVector = Vector(relative.x, relative.y, relative.z)

        if (data.rotationAxis.yaw) {
            rotatedVector = rotatedVector.rotateAroundY(origin.yaw)
        }

        if (data.rotationAxis.pitch) {
            rotatedVector = rotatedVector.rotateAroundX(origin.pitch)
        }

        val finalPosition = Position(
            origin.world,
            origin.x + rotatedVector.x,
            origin.y + rotatedVector.y,
            origin.z + rotatedVector.z,
            (if (data.rotationAxis.yaw) origin.yaw else 0f) + relative.yaw,
            (if (data.rotationAxis.pitch) origin.pitch else 0f) + relative.pitch
        )

        return context.safeCast(finalPosition)
            ?: throw IllegalStateException("Could not cast position to ${context.klass}, OriginPositionVariable is only compatible with Position/Coordinate/Vector fields")
    }

    private fun Vector.rotateAroundY(yawDegrees: Float): Vector {
        val yawRadians = toRadians(yawDegrees.toDouble())
        val cos = cos(yawRadians)
        val sin = sin(yawRadians)

        return Vector(
            x * cos - z * sin,
            y,
            x * sin + z * cos
        )
    }

    private fun Vector.rotateAroundX(pitchDegrees: Float): Vector {
        val pitchRadians = toRadians(pitchDegrees.toDouble())
        val cos = cos(pitchRadians)
        val sin = sin(pitchRadians)

        return Vector(
            x,
            y * cos - z * sin,
            y * sin + z * cos
        )
    }
}

enum class RotationAxis(val yaw: Boolean, val pitch: Boolean) {
    NONE(false, true),
    YAW(true, false),
    PITCH(false, true),
    BOTH(true, true);
}

data class OriginPositionVariableData(
    @WithRotation
    val origin: Var<Position> = ConstVar(Position.ORIGIN),
    @Default("\"YAW\"")
    val rotationAxis: RotationAxis = RotationAxis.YAW,
    @WithRotation
    val relative: Var<Coordinate> = ConstVar(Coordinate.ORIGIN),
)