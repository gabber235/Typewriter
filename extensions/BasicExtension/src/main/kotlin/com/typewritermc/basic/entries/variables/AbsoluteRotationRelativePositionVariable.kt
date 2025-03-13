package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.extension.annotations.WithRotation
import com.typewritermc.core.utils.point.Coordinate
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.utils.position
import kotlin.reflect.safeCast

@Entry(
    "absolute_rotation_relative_position_variable",
    "A variable that returns the position relative to the player",
    Colors.GREEN,
    "streamline:target-solid"
)
@GenericConstraint(Position::class)
@VariableData(AbsoluteRotationRelativePositionVariableData::class)
/**
 * The `AbsoluteRotationRelativePositionVariable` is a variable that returns the position relative to the player,
 * with an absolute yaw and pitch
 * The position is calculated by adding the coordinate to the player's position, except for the yaw and pitch which are
 * the ones defined in the entry
 *
 * ## How could this be used?
 * This could be used to make a death cinematic that shows at player's position after they die, from a top view perspective
 */
class AbsoluteRotationRelativePositionVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val player = context.player
        val data = context.getData<AbsoluteRotationRelativePositionVariableData>()
            ?: throw IllegalStateException("Could not find data for ${context.klass}, data: ${context.data}")

        val basePosition = player.position + data.coordinate
        val finalPosition = basePosition.withRotation(
            data.coordinate.yaw,
            data.coordinate.pitch
        )
        return context.klass.safeCast(finalPosition)
            ?: throw IllegalStateException("Could not cast position to ${context.klass}, AbsoluteRotationRelativePositionVariableData is only compatible with Position fields")
    }
}

data class AbsoluteRotationRelativePositionVariableData(
    @WithRotation
    val coordinate: Coordinate = Coordinate.ORIGIN,
)