package com.typewritermc.basic.entries.variables

import com.mthaler.aparser.arithmetic.Expression
import com.mthaler.aparser.arithmetic.tryEval
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.utils.Generic
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.logger

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
private class CalculatedVariable(
    override val id: String = "",
    override val name: String = "",
    val variables: List<CalculationVariable> = emptyList(),
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<CalculatedVariableData>()
            ?: throw ContextDataNotFoundException(context.klass, context.data, id)
        val expression = data.expression.parsePlaceholders(context.player).trim()
        if (expression.isBlank()) {
            return context.cast(0.0)
        }
        val variables = data.variables + variables
        val replacedExpression = variables.fold(expression) { expression, variable ->
            val value = variable.value.get(context.player, context.interactionContext).get(Double::class) ?: 0.0
            expression.replace("<${variable.variable}>", "$value")
        }

        val value = when (val result = Expression(replacedExpression).tryEval()) {
            is com.mthaler.aparser.util.Try.Success -> result.value
            is com.mthaler.aparser.util.Try.Failure -> {
                logger.warning("Could not evaluate expression '$expression'${if (expression != replacedExpression) " -> '$replacedExpression'" else ""} for player ${context.player.name} for variable $id")
                return context.cast(0.0)
            }
        }
        return context.cast(value)
    }
}

private data class CalculationVariable(
    @SnakeCase
    val variable: String = "",
    val value: Var<Generic> = ConstVar(Generic.Empty)
)

private data class CalculatedVariableData(
    val variables: List<CalculationVariable> = emptyList(),
    @Placeholder
    @Help("Use <var> to insert a variable")
    val expression: String = "",
)
