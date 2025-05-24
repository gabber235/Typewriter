package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.GenericConstraint
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.engine.paper.entry.entries.*

@Entry("fact_value_variable", "A variable that returns the value of a fact", Colors.GREEN, "solar:hashtag-square-bold")
@GenericConstraint(Int::class)
@VariableData(FactValueVariableData::class)
/**
 * The `Fact Value Variable` is a variable that returns the value of a fact.
 *
 * ## How could this be used?
 * This can be used to supply the strength of a potion effect based on the value of a fact.
 */
class FactValueVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<FactValueVariableData>() ?: return context.cast(0)
        val fact = data.fact.get() ?: return context.cast(0)
        val value = fact.readForPlayersGroup(context.player).value
        return context.cast(value)
    }
}

data class FactValueVariableData(
    val fact: Ref<ReadableFactEntry> = emptyRef(),
)