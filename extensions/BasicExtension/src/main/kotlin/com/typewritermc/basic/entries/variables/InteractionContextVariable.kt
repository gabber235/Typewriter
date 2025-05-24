package com.typewritermc.basic.entries.variables

import com.google.gson.JsonElement
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.VariableData
import com.typewritermc.core.interaction.InteractionContextKey
import com.typewritermc.core.utils.Generic
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.entry.entries.safeCast
import kotlin.reflect.KClass
import kotlin.reflect.safeCast

@Entry("interaction_context_variable", "Fill in a field with some data from another entry", Colors.GREEN, "uil:capture")
@VariableData(InteractionContextVariableData::class)
/**
 * The `Interaction Context Variable` entry is a variable
 * that fills in a field with some data from another entry in the same interaction.
 *
 * This is useful to use data from another entry which got executed in the same interaction.
 *
 * ## How could this be used?
 * This could be used to spawn firework on the block the player clicked on.
 */
class InteractionContextVariable(
    override val id: String = "",
    override val name: String = "",
    val default: Generic = Generic.Empty,
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val interactionContext = context.interactionContext
            ?: return default.get(context.klass)
                ?: throw DefaultValueNotValidException(context.klass, default.data)

        val data = context.getData<InteractionContextVariableData>()
            ?: return default.get(context.klass)
                ?: throw DefaultValueNotValidException(context.klass, default.data)

        val key = data.key
        return context.safeCast(interactionContext[key])
            ?: default.get(context.klass)
            ?: throw DefaultValueNotValidException(context.klass, default.data)
    }
}

data class InteractionContextVariableData(
    val key: InteractionContextKey<*> = InteractionContextKey.Empty,
)

class DefaultValueNotValidException(klass: KClass<*>, data: JsonElement) :
    Exception("The default value for InteractionContextVariable is not valid, needs ${klass.qualifiedName} but got data $data")