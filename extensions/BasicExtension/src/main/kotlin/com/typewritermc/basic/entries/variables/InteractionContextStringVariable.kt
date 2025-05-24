package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.InteractionContextKey
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.cast
import com.typewritermc.engine.paper.entry.entries.getData
import kotlin.reflect.cast

@Entry(
    "interaction_context_string_variable",
    "Allows any interaction context to be coerced as a string",
    Colors.GREEN,
    "material-symbols:text-compare-rounded"
)
@GenericConstraint(String::class)
@VariableData(InteractionContextStringVariableData::class)
class InteractionContextStringVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<InteractionContextStringVariableData>()
            ?: throw ContextDataNotFoundException(context.klass, context.data, id)

        val value =
            context.interactionContext?.get(data.key)?.toString() ?: data.default
        return context.cast(value)
    }
}

private data class InteractionContextStringVariableData(
    @IgnoreContextKeyBlueprint
    val key: InteractionContextKey<*> = InteractionContextKey.Empty,
    @Help("What to display if the key is not in the context.")
    val default: String = "",
)
