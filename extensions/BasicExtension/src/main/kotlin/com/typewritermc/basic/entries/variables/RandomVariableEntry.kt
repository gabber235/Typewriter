package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.utils.Generic
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.getData
import kotlin.random.Random

@Entry(
    "random_variable",
    "A variable that returns a random value of the given values",
    Colors.GREEN,
    "streamline:dices-entertainment-gaming-dices-solid"
)
@VariableData(RandomVariableData::class)
class RandomVariableEntry(
    override val id: String = "",
    override val name: String = "",
    val values: List<Generic> = emptyList(),
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val dataValues = context.getData<RandomVariableData>()?.values ?: emptyList()
        val randomIndex = Random.nextInt(values.size + dataValues.size)
        val genericValue = if (randomIndex < values.size) {
            values[randomIndex]
        } else {
            dataValues[randomIndex - values.size]
        }

        return genericValue.get(context.klass) ?: throw IllegalStateException("Could not find value for generic: ${genericValue.data} binding to ${context.klass.qualifiedName}")
    }
}

data class RandomVariableData(val values: List<Generic>)
