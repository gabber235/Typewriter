package com.typewritermc.basic.entries.variables

import com.mthaler.aparser.arithmetic.Expression
import com.mthaler.aparser.arithmetic.tryEval
import com.typewritermc.basic.entries.fact.RoundingMode
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.InteractionContextKey
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.cast
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
@Deprecated("Use CalculatedVariable instead")
class InteractionContextCalculatedVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<InteractionContextCalculatedVariableData>()
            ?: throw ContextDataNotFoundException(context.klass, context.data, id)

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
            return context.cast(0.0)
        }

        // Evaluate the expression
        val value = when (val result = Expression(expression.trim()).tryEval()) {
            is com.mthaler.aparser.util.Try.Success -> result.value
            is com.mthaler.aparser.util.Try.Failure -> {
                logger.warning("Could not evaluate expression '$expression' for player ${context.player.name} for variable $id")
                return context.cast(0.0)
            }
        }
        if (context.klass == Int::class) {
            return context.cast(RoundingMode.ROUND.apply(value))
        }
        return context.cast(value)
    }
}

private data class InteractionContextCalculatedVariableData(
    val keys: List<CalculatedKeyValue> = emptyList(),
    @Colored
    @Placeholder
    @LabelKey("basic.interaction_context_calculated_variable.fields.expression.label")
    @Help(key = "basic.interaction_context_calculated_variable.fields.expression.help")
    val expression: String = "",
    val roundingMode: RoundingMode = RoundingMode.ROUND,
)

private data class CalculatedKeyValue(
    val key: InteractionContextKey<*> = InteractionContextKey.Empty,
    @LabelKey("basic.interaction_context_calculated_variable.fields.default.label")
    @Help(key = "basic.interaction_context_calculated_variable.fields.default.help")
    val default: Double = 0.0,
)
