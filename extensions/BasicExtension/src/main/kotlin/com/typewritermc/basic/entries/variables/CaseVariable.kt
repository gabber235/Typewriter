package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.utils.Generic
import com.typewritermc.engine.paper.entry.entries.*

@Entry(
    "case_variable",
    "A variable that returns a value based on a selection",
    Colors.GREEN,
    "mdi:list-status"
)
@VariableData(CaseVariableData::class)
/**
 * The `CaseVariable` is a variable that returns a value based on a selection number.
 *
 * It will return the value at the specified selection (1-based), combining cases defined in both
 * the entry and the variable data. If the selection is out of bounds, it returns the default value.
 *
 * First the cases defined in the entry and then the cases defined in the variable data are checked.
 * So if the entry has 3 cases, and the data has 2 cases, then selection 2 will return the second case of the entry's list
 * and selection 4 will return the second case of the data's list.
 *
 * ## How could this be used?
 * This could be used to select different values based on game states, levels, or player statuses
 * that are represented by numeric values.
 */
class CaseVariable(
    override val id: String = "",
    override val name: String = "",
    val cases: List<Generic> = emptyList(),
    val default: Generic = Generic.Empty,
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<CaseVariableData>()
        val dataCases = data?.cases ?: emptyList()
        val selection = data?.selection?.get(context.player, context.interactionContext) ?: 1
        val allCases = cases + dataCases

        val index = selection - 1

        if (index in allCases.indices) {
            allCases[index].get(context.klass)?.let {
                return it
            }
        }

        // If we couldn't get a valid value, fall back to the default
        return default.get(context.klass)
            ?: throw IllegalStateException("Could not convert default value: ${default.data} to ${context.klass.qualifiedName}")
    }
}

data class CaseVariableData(
    @Help("Value is 1-based")
    @Default("1")
    val selection: Var<Int> = ConstVar(1),
    val cases: List<Generic> = emptyList(),
)