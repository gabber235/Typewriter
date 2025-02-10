package com.typewritermc.basic.entries.variables

import com.mthaler.aparser.arithmetic.Expression
import com.mthaler.aparser.arithmetic.tryEval
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.InteractionContextKey
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.logger

@Entry(
    "interaction_context_calculated_variable",
    "A variable that performs calculations using interaction context values",
    Colors.GREEN,
    "fa6-solid:calculator"
)
@GenericConstraint(Int::class)
@GenericConstraint(Double::class)
@VariableData(InteractionContextCalculatedVariableData::class)
class InteractionContextCalculatedVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<InteractionContextCalculatedVariableData>()
            ?: throw IllegalStateException("Could not find data for ${context.klass}, data: ${context.data} for entry $id")

        // First replace interaction context values
        var expression = data.expression.parsePlaceholders(context.player)

        val interactionContext = context.interactionContext
        expression = if (interactionContext == null) {
            // Use default values if no context is available
            data.keys.foldIndexed(expression) { index, acc, keyValue ->
                acc.replace("<${index + 1}>", keyValue.default.toString())
            }
        } else {
            // Replace with actual values from context
            data.keys.foldIndexed(expression) { index, acc, keyValue ->
                val value = interactionContext[keyValue.key]?.toString() ?: keyValue.default.toString()
                acc.replace("<${index + 1}>", value)
            }
        }

        if (expression.isBlank()) {
            return 0.0.cast<T>(context.klass)
        }

        // Evaluate the expression
        val value = when (val result = Expression(expression.trim()).tryEval()) {
            is com.mthaler.aparser.util.Try.Success -> result.value
            is com.mthaler.aparser.util.Try.Failure -> {
                logger.warning("Could not evaluate expression '$expression' for player ${context.player.name} for variable $id")
                return 0.0.cast<T>(context.klass)
            }
        }
        return value.cast<T>(context.klass)
    }
}

private data class InteractionContextCalculatedVariableData(
    val keys: List<CalculatedKeyValue> = emptyList(),
    @Colored
    @Placeholder
    @Help("Use <1> to insert the value from the first variable in your mathematical expression.")
    val expression: String = "",
)

private data class CalculatedKeyValue(
    val key: InteractionContextKey<*> = InteractionContextKey.Empty,
    @Help("What to use in the calculation if the key is not in the context.")
    val default: Double = 0.0,
)