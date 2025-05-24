package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.InteractionContextKey
import com.typewritermc.core.utils.Generic
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.cast
import com.typewritermc.engine.paper.entry.entries.getData

@Entry(
    "interaction_context_number_variable",
    "Allows any int or double interaction context to be coerced into the other",
    Colors.GREEN,
    "material-symbols:magic-exchange-rounded"
)
@GenericConstraint(Int::class)
@GenericConstraint(Double::class)
@VariableData(InteractionContextNumberVariableData::class)
class InteractionContextNumberVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<InteractionContextNumberVariableData>()
            ?: throw ContextDataNotFoundException(context.klass, context.data, id)

        val value =
            context.interactionContext?.get(data.key)
        if (value == null) {
            return data.default.get(context.klass) ?: context.cast(0.0)
        }

        if (value::class == context.klass) {
            return context.cast(value)
        }

        return context.cast(value)
    }
}

private data class InteractionContextNumberVariableData(
    @IgnoreContextKeyBlueprint
    val key: InteractionContextKey<*> = InteractionContextKey.Empty,
    @Help("What to display if the key is not in the context.")
    val default: Generic = Generic.Empty,
)
