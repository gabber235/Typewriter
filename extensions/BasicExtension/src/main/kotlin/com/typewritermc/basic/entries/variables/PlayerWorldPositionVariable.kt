package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.extension.annotations.WithRotation
import com.typewritermc.core.utils.point.Coordinate
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.toPosition
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.entry.entries.safeCast
import com.typewritermc.engine.paper.utils.position
import kotlin.reflect.safeCast

@Entry(
    "player_world_position_variable",
    "Absolute Position in the players world",
    Colors.GREEN,
    "material-symbols:person-pin-circle-rounded"
)
@GenericConstraint(Position::class)
@VariableData(PlayerWorldPositionVariableData::class)
/**
 * The `PlayerWorldPositionVariable` is a variable that returns the player's position in the world.
 *
 * ## How could this be used?
 * This could be used in dungeons where the players will be in a different world for paper,
 * but the world coordinates are the same.
 */
class PlayerWorldPositionVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val player = context.player
        val data = context.getData<PlayerWorldPositionVariableData>()
            ?: throw ContextDataNotFoundException(context.klass, context.data)
        val position = data.coordinate.toPosition(player.position.world)

        return context.safeCast(position)
            ?: throw IllegalStateException("Could not cast position to ${context.klass}, PlayerWorldPositionVariable is only compatible with Position fields")
    }
}

data class PlayerWorldPositionVariableData(
    @WithRotation
    val coordinate: Coordinate = Coordinate.ORIGIN,
)
