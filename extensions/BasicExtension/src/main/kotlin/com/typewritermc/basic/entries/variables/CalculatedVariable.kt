package com.typewritermc.basic.entries.variables

import com.mthaler.aparser.arithmetic.Expression
import com.mthaler.aparser.arithmetic.tryEval
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.logger
import kotlin.math.roundToInt
import kotlin.math.roundToLong
import kotlin.reflect.KClass
import kotlin.reflect.full.cast

@Entry("calculated_variable", "A variable that is calculated", Colors.GREEN, "fa6-solid:calculator")
@GenericConstraint(Int::class)
@GenericConstraint(Double::class)
@VariableData(CalculatedVariableData::class)
/**
 * The `CalculatedVariable` entry is a variable where the value is calculated.
 * You can use Placeholders and other facts for the value to change dynamically.
 *
 * ## How could this be used?
 */
class CalculatedVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<CalculatedVariableData>()
            ?: throw IllegalStateException("Could not find data for ${context.klass}, data: ${context.data} for entry $id")
        val expression = data.expression.parsePlaceholders(context.player).trim()
        if (expression.isBlank()) {
            return value(0.0, context.klass)
        }

        val value = when (val result = Expression(expression).tryEval()) {
            is com.mthaler.aparser.util.Try.Success -> result.value
            is com.mthaler.aparser.util.Try.Failure -> {
                logger.warning("Could not evaluate expression '$expression' for player ${context.player.name} for variable $id")
                return value(0.0, context.klass)
            }
        }
        return value(value, context.klass)
    }

    private fun <T : Any> value(value: Double, klass: KClass<T>): T {
        return when (klass) {
            Int::class -> klass.cast(value.roundToInt())
            Double::class -> klass.cast(value)
            Float::class -> klass.cast(value.toFloat())
            Long::class -> klass.cast(value.roundToLong())
            else -> throw IllegalStateException("Could not parse value '$value' for $klass")
        }
    }
}

data class CalculatedVariableData(
    @Placeholder
    val expression: String = "",
)