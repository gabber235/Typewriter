package com.typewritermc.formula

import com.typewritermc.types.StandardTypes
import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation

/**
 * Every record during evaluation, code or content: its own applied type, expanded so it never names a field key, and
 * its fields by name. A Kotlin instance of a code record exists only inside a provider call, where its native binding
 * builds it.
 *
 * Equality is structural, except that a range is equal as Kotlin's `IntRange` is: every empty range equals every
 * other, so `1..0 == 2..1`, and its hash agrees.
 */
data class RecordValue(
    val type: TypeUse,
    val fields: Map<String, Any?>,
) {
    override fun equals(other: Any?): Boolean {
        if (other !is RecordValue || type != other.type) return false
        val range = intRange() ?: return fields == other.fields
        return range == other.intRange()
    }

    override fun hashCode(): Int = intRange()?.hashCode() ?: (31 * type.hashCode() + fields.hashCode())

    private fun intRange(): IntRange? {
        if ((type as? TypeUse.NamedWrapper)?.value?.definition != StandardTypes.intRange) return null
        return IntRange(fields["first"] as Int, fields["last"] as Int)
    }
}

/**
 * Any other named value during evaluation: an enum case (its case type, payload Unit) or a value class (its type and
 * inner value), so `when` and `==` see the type.
 */
data class NamedValue(
    val type: TypeUse,
    val value: Any?,
)

/**
 * A stored Var or function typed value not yet read. A formula that uses it evaluates it then, at [at], so its reads
 * land on that formula, and a failing Var nobody uses stops no reader.
 */
data class Deferred(
    val at: ValueLocation,
)
