package com.typewritermc.types.skir

import com.typewritermc.types.DataValue
import skirout.editor.v1.type_catalog.DataValue as SkirDataValue

fun DataValue.toSkir(): SkirConversionResult<SkirDataValue> = SkirDataValueCodec.encode(this)

fun SkirDataValue.toTypewriter(): SkirConversionResult<DataValue> = SkirDataValueCodec.decode(this)

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
