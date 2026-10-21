package com.typewritermc.types.skir

fun <Value> SkirConversionResult<Value>.getOrThrow(): Value =
    when (this) {
        is SkirConversionResult.Success -> value
        is SkirConversionResult.Failure -> throw SkirConversionException(diagnostics)
    }

fun <Value> SkirConversionResult<Value>.getOrNull(): Value? =
    when (this) {
        is SkirConversionResult.Success -> value
        is SkirConversionResult.Failure -> null
    }

class SkirConversionException(
    val diagnostics: List<SkirConversionDiagnostic>,
) : IllegalArgumentException(diagnostics.joinToString(separator = "\n"))
