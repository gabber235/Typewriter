package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.InteractionContextKey
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.entries.cast
import com.typewritermc.engine.paper.entry.entries.getData
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import kotlin.reflect.cast

@Entry(
    "interaction_context_text_variable",
    "A way to build text with interaction variables",
    Colors.GREEN,
    "material-symbols:text-compare-rounded"
)
@GenericConstraint(String::class)
@VariableData(InteractionContextTextVariableData::class)
@Deprecated("Use StringBuilderVariable instead")
class InteractionContextTextVariable(
    override val id: String = "",
    override val name: String = "",
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<InteractionContextTextVariableData>()
            ?: throw ContextDataNotFoundException(context.klass, context.data, id)

        val text = data.text.parsePlaceholders(context.player)
        val keys = data.keys

        val interactionContext = context.interactionContext
        if (interactionContext == null) {
            val defaultText = keys.foldIndexed(text) { index, acc, keyValue ->
                acc.replace("<${index + 1}>", keyValue.default)
            }
            return context.cast(defaultText)
        }

        val replacedText = keys.foldIndexed(text) { index, acc, keyValue ->
            val value = interactionContext[keyValue.key]?.toString() ?: keyValue.default
            acc.replace("<${index + 1}>", value)
        }
        return context.cast(replacedText)
    }
}

private data class InteractionContextTextVariableData(
    val keys: List<TextKeyValue> = emptyList(),
    @Colored
    @Placeholder
    @Help("Use <1> to insert the text from the first variable.")
    val text: String = "",
)

private data class TextKeyValue(
    @IgnoreContextKeyBlueprint
    val key: InteractionContextKey<*> = InteractionContextKey.Empty,
    @Help("What to display if the key is not in the context.")
    val default: String = "",
)
