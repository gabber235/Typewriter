package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.Generic
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.entry.matches

@Entry(
    "condition_variable",
    "A variable that returns a value based on criteria",
    Colors.GREEN,
    "streamline:filter-2-solid"
)
@VariableData(ConditionVariableData::class)
/**
 * The `ConditionVariable` is a variable that returns a value based on criteria.
 *
 * It will return the first value that matches the criteria.
 * First it will check the conditions on the specific entry, then it will check the conditions on the entry.
 *
 * ## How could this be used?
 * This could be used to make a variable that returns a value based on a certain criteria.
 */
class ConditionVariable(
    override val id: String = "",
    override val name: String = "",
    val conditions: List<Condition> = emptyList(),
    val default: Generic = Generic.Empty,
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val dataConditions = context.getData<ConditionVariableData>()?.conditions ?: emptyList()
        val allConditions = dataConditions + conditions

        for (condition in allConditions) {
            if (condition.criteria.matches(context.player, context.interactionContext ?: context())) {
                return condition.value.get(context.klass) ?: continue
            }
        }

        return default.get(context.klass)
            ?: throw IllegalStateException("Could not find value for default: ${default.data} binding to ${context.klass.qualifiedName}")
    }
}

data class ConditionVariableData(
    val conditions: List<Condition> = emptyList(),
)

data class Condition(
    val criteria: List<Criteria> = emptyList(),
    val value: Generic = Generic.Empty,
)