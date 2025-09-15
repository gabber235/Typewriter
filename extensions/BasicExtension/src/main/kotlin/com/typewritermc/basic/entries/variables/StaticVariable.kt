package com.typewritermc.basic.entries.variables

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.Generic
import com.typewritermc.engine.paper.entry.PlaceholderEntry
import com.typewritermc.engine.paper.entry.PlaceholderParser
import com.typewritermc.engine.paper.entry.entries.VarContext
import com.typewritermc.engine.paper.entry.entries.VariableEntry
import com.typewritermc.engine.paper.entry.placeholderParser
import com.typewritermc.engine.paper.entry.supply

@Entry(
    "static_variable",
    "A variable with a single static value",
    Colors.GREEN,
    "streamline:setting-line"
)
/**
 * The `Static Variable` entry is a variable that has a single static value.
 *
 * ## How could this be used?
 * If you have the same value for multiple entries, you can use this to avoid repeating the value and allow for easier changes.
 */
class StaticVariable(
    override val id: String = "",
    override val name: String = "",
    val value: Generic = Generic.Empty,
) : VariableEntry, PlaceholderEntry {
    override fun <T : Any> get(context: VarContext<T>): T {
        return value.get(context.klass)
            ?: throw IllegalStateException("Could not find value for static value: ${value.data} binding to ${context.klass.qualifiedName}")
    }

    override fun parser(): PlaceholderParser = placeholderParser {
        supply {
            value.get(String::class)
        }
    }
}