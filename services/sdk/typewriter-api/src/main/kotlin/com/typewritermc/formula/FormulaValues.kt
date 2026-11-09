package com.typewritermc.formula

import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation
import java.math.BigDecimal

/**
 * Every record during evaluation, code or content: its own applied type, expanded so it never names a field key, and
 * its fields by name. A Kotlin instance of a code record exists only inside a provider call, where its native binding
 * builds it.
 *
 * Equality is structural, so two empty ranges with different bounds differ here; formula `==` calls them equal, as
 * Kotlin's IntRange does.
 */
data class RecordValue(
    val type: TypeUse,
    val fields: Map<String, Any?>,
)

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

/**
 * The one form a Decimal has during evaluation: no trailing zeros and never a negative scale, so `1.10`, `1.1` and
 * `1.100` are one Kotlin value and every function, `==`, `in`, `distinct` and map keys alike, agrees on them. A
 * Decimal takes this form wherever it enters a formula: a literal, a stored value, a provider result.
 */
fun BigDecimal.formulaForm(): BigDecimal = stripTrailingZeros().let { if (it.scale() < 0) it.setScale(0) else it }
