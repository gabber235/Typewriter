package com.typewritermc.entity.entries.variable

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.utils.point.Coordinate
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entity.AudienceEntityDisplay
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.findDisplay

@Entry(
    "entity_instance_position_variable",
    "A variable that returns the position of an entity instance",
    Colors.GREEN,
    "material-symbols:person-pin-circle"
)
@GenericConstraint(Position::class)
@GenericConstraint(Coordinate::class)
@GenericConstraint(Vector::class)
@VariableData(EntityInstancePositionVariableData::class)
/**
 * The `EntityInstancePositionVariable` is a variable that returns the position of an entity instance.
 *
 * ## How could this be used?
 * This can be used in combination with the [PlayerNearLocationEventEntry] to trigger an event when a player is within a certain range of an entity.
 */
class EntityInstancePositionVariable(
    override val id: String = "",
    override val name: String = "",
    val default: Position = Position.ORIGIN,
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val player = context.player
        val data = context.getData<EntityInstancePositionVariableData>()
            ?: throw ContextDataNotFoundException(context.klass, context.data)

        val position = data.instance.findDisplay<AudienceEntityDisplay>()?.position(player.uniqueId) ?: default

        return context.safeCast(position)
            ?: throw IllegalStateException("Could not cast position to ${context.klass}, EntityInstancePositionVariable is only compatible with Position/Coordinate/Vector fields")
    }
}

data class EntityInstancePositionVariableData(
    val instance: Ref<EntityInstanceEntry> = emptyRef(),
)