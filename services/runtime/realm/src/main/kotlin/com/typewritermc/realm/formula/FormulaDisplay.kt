package com.typewritermc.realm.formula

import com.typewritermc.formula.TextSpan
import com.typewritermc.formula.check.StoredFormula
import com.typewritermc.formula.check.StoredReference
import com.typewritermc.formula.syntax.writtenName
import com.typewritermc.realm.authoring.RealmQuery
import com.typewritermc.realm.authoring.RealmReads
import com.typewritermc.types.toSkir
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

/**
 * The text a creator reads for the formula at [at]: derived, never stored. Layer 2 sends it in the WatchFormula
 * snapshot and maps diagnostic spans through [Displayed] as well.
 */
internal data class DisplayOf(
    val at: ValueLocation,
) : RealmQuery<String> {
    context(reads: RealmReads)
    override fun compute(): String =
        reads
            .read(FormulasOf(at.resource))
            .firstOrNull { it.at == at }
            ?.formula
            ?.displayed(at)
            ?.text
            .orEmpty()
}

/** A formula's source with each filled reference showing its target's current name, and where each reference now sits. */
internal data class Displayed(
    val text: String,
    val references: List<StoredReference>,
)

/**
 * The one mapping from source to display. A filled reference shows the name the formula at [at] sees for its target,
 * written as source writes it; an emptied one, or a target out of scope, keeps the text it covers. Spans are safe to
 * trust, because the realm wrote every stored reference.
 */
context(reads: RealmReads)
internal fun StoredFormula.displayed(at: ValueLocation): Displayed {
    val text = StringBuilder()
    val moved = mutableListOf<StoredReference>()
    var cursor = 0
    references
        .filter { it.at.start >= 0 && it.at.start < it.at.end && it.at.end <= source.length }
        .sortedBy { it.at.start }
        .forEach { reference ->
            if (reference.at.start < cursor) return@forEach
            text.append(source, cursor, reference.at.start)
            val shown = reference.target?.let { at.nameOf(it.toSkir()) }?.let(::writtenName) ?: textAt(reference.at)
            val start = text.length
            text.append(shown)
            moved += StoredReference(TextSpan(start, text.length), reference.target)
            cursor = reference.at.end
        }
    text.append(source, cursor, source.length)
    return Displayed(text.toString(), moved)
}

/** The name a formula at this location sees for [target]: the innermost scope level that lists it. Null when it is out of scope. */
context(reads: RealmReads)
private fun ValueLocation.nameOf(target: ResourceId): String? =
    reads.read(ScopeAt(this)).levels.firstNotNullOfOrNull { level ->
        level.names.entries
            .firstOrNull { target in it.value }
            ?.key
    }
