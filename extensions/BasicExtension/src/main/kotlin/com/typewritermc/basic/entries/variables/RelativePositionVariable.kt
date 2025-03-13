package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.utils.point.Coordinate
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.utils.position
import kotlin.reflect.safeCast

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
 * You can optionally set the yaw and/or pitch to be absolute values instead of relative.
 *
 * ## How could this be used?
 * This could be used to make a death cinematic that shows at player's position after they die.
 * Using absolute rotation settings allows for precise camera angles regardless of player orientation.
 */
class RelativePositionVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val player = context.player
        val data = context.getData<RelativePositionVariableData>()
            ?: throw IllegalStateException("Could not find data for ${context.klass}, data: ${context.data}")

        val basePosition = player.position + data.coordinate

        // Determine the adjusted yaw and pitch based on the absolute flags
        val adjustedYaw = if (data.absoluteYaw) data.coordinate.yaw else player.position.yaw + data.coordinate.yaw
        val adjustedPitch = if (data.absolutePitch) data.coordinate.pitch else player.position.pitch + data.coordinate.pitch

        val finalPosition = basePosition.withRotation(adjustedYaw, adjustedPitch)

        return context.klass.safeCast(finalPosition)
            ?: throw IllegalStateException("Could not cast position to ${context.klass}, RelativePositionVariable is only compatible with Position fields")
    }
}

data class RelativePositionVariableData(
    @WithRotation
    val coordinate: Coordinate = Coordinate.ORIGIN,

    @Help("When enabled, yaw will be absolute rather than relative to the player's rotation")
    @Default("false")
    val absoluteYaw: Boolean = false,

    @Help("When enabled, pitch will be absolute rather than relative to the player's rotation")
    @Default("false")
    val absolutePitch: Boolean = false,
)