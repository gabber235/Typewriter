package com.typewritermc.basic.entries.variables

import com.typewritermc.basic.entries.variables.CoordinatePart.*
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.utils.point.Coordinate
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.utils.position

@Entry(
    "relative_position_variable",
    "A variable that returns the position relative to the player",
    Colors.GREEN,
    "streamline:target-solid"
)
@GenericConstraint(Position::class)
@GenericConstraint(Coordinate::class)
@GenericConstraint(Vector::class)
@VariableData(RelativePositionVariableData::class)
/**
 * The `RelativePositionVariable` is a variable that returns the position relative to the player.
 * The position is calculated by adding the coordinate to the player's position.
 *
 * You can optionally set any coordinate part (X, Y, Z, YAW, PITCH) to use absolute values instead of relative.
 *
 * ## How could this be used?
 * This could be used to make a death cinematic that shows at player's position after they die.
 * Absolute position settings allow for exact world coordinates when needed.
 */
class RelativePositionVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val player = context.player
        val data = context.getData<RelativePositionVariableData>()
            ?: throw ContextDataNotFoundException(context.klass, context.data)

        val basePosition = player.position
        val coordinate = data.coordinate.get(player, context.interactionContext)

        val position =
            Position(
                basePosition.world,
                if (X in data.absolute) coordinate.x else basePosition.x + coordinate.x,
                if (Y in data.absolute) coordinate.y else basePosition.y + coordinate.y,
                if (Z in data.absolute) coordinate.z else basePosition.z + coordinate.z,
                if (YAW in data.absolute) coordinate.yaw else basePosition.yaw + coordinate.yaw,
                if (PITCH in data.absolute) coordinate.pitch else basePosition.pitch + coordinate.pitch
            )

        return context.safeCast(position)
            ?: throw IllegalStateException("Could not cast position to ${context.klass}, RelativePositionVariable is only compatible with Position/Coordinate/Vector fields")
    }
}

enum class CoordinatePart {
    X, Y, Z, YAW, PITCH
}

data class RelativePositionVariableData(
    @WithRotation
    val coordinate: Var<Coordinate> = ConstVar(Coordinate.ORIGIN),

    @Help("Select which parts of the position will use absolute values")
    val absolute: List<CoordinatePart> = emptyList(),
)