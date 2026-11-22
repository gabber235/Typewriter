package com.typewritermc.engine.events.testing

import com.typewritermc.authoring.FieldPath
import com.typewritermc.authoring.text
import com.typewritermc.engine.events.PublishedEntries
import com.typewritermc.engine.events.PublishedEntry
import com.typewritermc.events.Candidate
import com.typewritermc.events.VarReader
import com.typewritermc.formula.Var
import skirout.editor.v1.type_catalog.PathSegment

/**
 * [entries] as one publication whose `Var` fields read as written, for any entry class: an extension's own entries
 * publish this way into an [EventHarness]. The harness evaluates no formulas.
 */
fun written(vararg entries: PublishedEntry<*>): PublishedEntries = PublishedEntries(entries.toList(), WrittenFields)

/** Reads a top level `Var` field by its property, so it needs no table of the entry classes it serves. */
private object WrittenFields : VarReader {
    override fun read(
        field: FieldPath,
        candidate: Candidate<*>,
    ): Any? {
        val segment = field.path.segments.singleOrNull() as? PathSegment.FieldWrapper
        val name = checkNotNull(segment) { "${field.path.text} is no top level field." }.value.name
        val getter = candidate.entry.javaClass.getMethod("get${name.replaceFirstChar(Char::uppercaseChar)}")
        return when (val held = getter.invoke(candidate.entry)) {
            null -> null
            is Var.Value<*, *> -> held.value
            is Var.Computed<*, *> -> error("${candidate.entry.name} holds a formula, which the event harness does not evaluate.")
            else -> error("${field.path.text} of ${candidate.entry.name} is no Var field.")
        }
    }
}
