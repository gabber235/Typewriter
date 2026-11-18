package com.typewritermc.formula.check

import com.typewritermc.formula.TextSpan
import com.typewritermc.types.ResourceId

/** A name's range in a formula's source and the resource it names. [target] is null once a delete emptied it. */
data class StoredReference(
    val at: TextSpan,
    val target: ResourceId?,
)

/**
 * A formula as the realm stores it: its source and its references, emptied ones included. An emptied reference is
 * stored as an unfilled link, which a Kotlin [com.typewritermc.formula.Formula] cannot hold, so the checker reads this.
 */
data class StoredFormula(
    val source: String,
    val references: List<StoredReference> = emptyList(),
) {
    /** The text the reference at [span] covers. */
    fun textAt(span: TextSpan): String =
        source.substring(span.start.coerceIn(0, source.length), span.end.coerceIn(span.start.coerceIn(0, source.length), source.length))
}
