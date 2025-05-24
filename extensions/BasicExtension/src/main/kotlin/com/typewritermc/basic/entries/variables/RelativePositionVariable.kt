package com.typewritermc.basic.entries.variables

import com.typewritermc.basic.entries.variables.CoordinatePart.*
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.utils.point.Coordinate
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.entry.entries.safeCast
import com.typewritermc.engine.paper.utils.position

@Entry(
    "relative_position_variable",
    "A variable that returns the position relative to the player",
    Colors.GREEN,
    "streamline:target-solid"
)
@GenericConstraint(Position::class)
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

        val position =
            Position(
                basePosition.world,
                if (X in data.absolute) data.coordinate.x else basePosition.x + data.coordinate.x,
                if (Y in data.absolute) data.coordinate.y else basePosition.y + data.coordinate.y,
                if (Z in data.absolute) data.coordinate.z else basePosition.z + data.coordinate.z,
                if (YAW in data.absolute) data.coordinate.yaw else basePosition.yaw + data.coordinate.yaw,
                if (PITCH in data.absolute) data.coordinate.pitch else basePosition.pitch + data.coordinate.pitch
            )

        return context.safeCast(position)
            ?: throw IllegalStateException("Could not cast position to ${context.klass}, RelativePositionVariable is only compatible with Position fields")
    }
}

enum class CoordinatePart {
    X, Y, Z, YAW, PITCH
}

data class RelativePositionVariableData(
    @WithRotation
    val coordinate: Coordinate = Coordinate.ORIGIN,

    @Help("Select which parts of the position will use absolute values")
    val absolute: List<CoordinatePart> = emptyList(),
)