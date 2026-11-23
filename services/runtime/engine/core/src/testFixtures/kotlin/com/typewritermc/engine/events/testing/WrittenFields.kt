package com.typewritermc.engine.events.testing

import com.typewritermc.authoring.text
import com.typewritermc.engine.events.PublishedEntries
import com.typewritermc.engine.events.PublishedEntry
import com.typewritermc.events.EntryReader
import com.typewritermc.events.EntryScope
import com.typewritermc.formula.Var
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.ValuePath

/**
 * [entries] as one publication whose values read as written, for any entry class: an extension's own entries publish
 * this way into an [EventHarness]. The harness evaluates no formulas.
 */
fun written(vararg entries: PublishedEntry<*>): PublishedEntries = PublishedEntries(entries.toList(), WrittenFields)

/**
 * Reads an entry as written by following each path through its Kotlin properties, so it needs no table of the entry
 * classes it serves: a list item's id is its index, a map row's id is its key. A written `Var` reads as its value.
 */
private object WrittenFields : EntryReader {
    override fun read(
        scope: EntryScope<*>,
        path: ValuePath,
    ): Any? =
        when (val held = valueAt(scope, path)) {
            is Var.Value<*, *> -> held.value
            is Var.Computed<*, *> -> error("${scope.entry.name} holds a formula, which the event harness does not evaluate.")
            else -> held
        }

    override fun has(
        scope: EntryScope<*>,
        path: ValuePath,
    ): Boolean = valueAt(scope, path) != null

    override fun items(
        scope: EntryScope<*>,
        path: ValuePath,
    ): List<ItemId> =
        when (val held = valueAt(scope, path)) {
            is Collection<*> -> held.indices().map { ItemId(value = "$it") }
            is Map<*, *> -> held.keys.map { ItemId(value = "$it") }
            else -> error("${path.text} of ${scope.entry.name} holds no items.")
        }

    private fun Collection<*>.indices(): IntRange = 0 until size

    private fun valueAt(
        scope: EntryScope<*>,
        path: ValuePath,
    ): Any? {
        var value: Any? = scope.entry
        var row: Map.Entry<*, *>? = null
        for (segment in path.segments) {
            value =
                when (segment) {
                    is PathSegment.FieldWrapper -> {
                        val name = segment.value.name
                        val holder = checkNotNull(value) { "${path.text} of ${scope.entry.name} passes through nothing." }
                        holder.javaClass.getMethod("get${name.replaceFirstChar(Char::uppercaseChar)}").invoke(holder)
                    }

                    is PathSegment.ItemWrapper -> {
                        val id = segment.value.id.value
                        when (value) {
                            is Collection<*> -> value.elementAt(id.toInt())
                            is Map<*, *> -> value.entries.single { "${it.key}" == id }.also { row = it }
                            else -> error("${path.text} of ${scope.entry.name} is no collection.")
                        }
                    }

                    PathSegment.MAP_KEY -> {
                        checkNotNull(row).key
                    }

                    PathSegment.MAP_VALUE -> {
                        checkNotNull(row).value
                    }

                    else -> {
                        error("${path.text} has a segment the harness does not know.")
                    }
                }
        }
        return value
    }
}
