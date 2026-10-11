package com.typewritermc.types.skir

import com.typewritermc.types.DataValue
import com.typewritermc.types.TypeDefinition
import com.typewritermc.types.TypeTemplate
import com.typewritermc.types.TypeUse
import skirout.editor.v1.type_catalog.DataValue as SkirDataValue
import skirout.editor.v1.type_catalog.TypeDefinition as SkirTypeDefinition
import skirout.editor.v1.type_catalog.TypeTemplate as SkirTypeTemplate
import skirout.editor.v1.type_catalog.TypeUse as SkirTypeUse

fun TypeDefinition.toSkir(): SkirConversionResult<SkirTypeDefinition> = SkirTypeCodec.encode(this)

fun SkirTypeDefinition.toTypewriter(): SkirConversionResult<TypeDefinition> = SkirTypeCodec.decode(this)

fun TypeTemplate.toSkir(): SkirConversionResult<SkirTypeTemplate> = SkirTypeCodec.encode(this)

fun SkirTypeTemplate.toTypewriter(): SkirConversionResult<TypeTemplate> = SkirTypeCodec.decode(this)

fun TypeUse.toSkir(): SkirConversionResult<SkirTypeUse> = SkirTypeCodec.encode(this)

fun SkirTypeUse.toTypewriter(): SkirConversionResult<TypeUse> = SkirTypeCodec.decode(this)

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
