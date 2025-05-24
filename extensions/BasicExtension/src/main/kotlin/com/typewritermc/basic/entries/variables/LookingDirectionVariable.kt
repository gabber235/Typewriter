package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.cast
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.utils.toVector
import kotlin.reflect.cast

@Entry(
    "looking_direction_variable",
    "A variable that returns the direction the player is looking at",
    Colors.GREEN,
    "mingcute:look-left-fill"
)
@GenericConstraint(Vector::class)
@VariableData(LookingDirectionVariableData::class)
class LookingDirectionVariable(
    override val id: String = "",
    override val name: String = "",
    @Default(Vector.UNIT_JSON)
    val scalar: Vector = Vector.UNIT,
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val dataScalar = context.getData<LookingDirectionVariableData>()?.scalar ?: Vector.UNIT
        val vector = this.scalar.mul(dataScalar)

        val player = context.player
        val lookDirection = player.location.direction.toVector()
        return context.cast(lookDirection * vector)
    }
}

data class LookingDirectionVariableData(
    @Default(Vector.UNIT_JSON)
    val scalar: Vector = Vector.UNIT,
)