package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.exceptions.ContextDataNotFoundException
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders

@Entry(
    "string_builder_variable",
    "A way to build strings from other variables",
    Colors.GREEN,
    "material-symbols:text-compare-rounded"
)
@GenericConstraint(String::class)
@VariableData(StringBuilderVariableData::class)
private class StringBuilderVariable(
    override val id: String = "",
    override val name: String = "",
    private val parts: List<StringPart> = emptyList(),
) : VariableEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        val data = context.getData<StringBuilderVariableData>()
            ?: throw ContextDataNotFoundException(context.klass, context.data, id)

        val text = data.text
        val parts = data.parts + parts

        var previousText: String
        var newText = text
        var loop = 0
        do {
            previousText = newText
            newText = parts.fold(newText) { text, part ->
                text.replace("<${part.key}>", part.value.get(context.player, context.interactionContext))
            }
        } while (previousText != newText && ++loop < 20)

        return context.cast(newText.parsePlaceholders(context.player))
    }
}

private data class StringBuilderVariableData(
    val parts: List<StringPart> = emptyList(),
    @Placeholder
    @Help("Use <key> to insert the part")
    val text: String = "",
)

private data class StringPart(
    @SnakeCase
    val key: String = "",
    val value: Var<String> = ConstVar(""),
)
