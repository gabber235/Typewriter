package com.typewritermc.formula

import skirout.editor.v1.type_catalog.TypeUse
import skirout.editor.v1.type_catalog.ValueLocation

/**
 * Every record during evaluation, code or content: its own applied type, expanded so it never names a field key, and
 * its fields by name. A Kotlin instance of a code record exists only inside a provider call, where its native binding
 * builds it.
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
