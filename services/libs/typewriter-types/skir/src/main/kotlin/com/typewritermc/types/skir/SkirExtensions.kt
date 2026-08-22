package com.typewritermc.types.skir

import com.typewritermc.types.DataValue
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import skirout.editor.v1.type_catalog.ResolvedTypeRef as SkirResolvedTypeRef
import skirout.editor.v1.type_catalog.TypeCatalog as SkirTypeCatalog
import skirout.editor.v1.type_catalog.TypeExpression as SkirTypeExpression
import skirout.editor.v1.type_catalog.TypedValue as SkirTypedValue

fun TypeCatalog.toSkir(): SkirConversionResult<SkirTypeCatalog> = SkirTypeCodec.encode(this)

fun SkirTypeCatalog.toTypewriter(): SkirConversionResult<TypeCatalog> = SkirTypeCodec.decode(this)

fun TypeExpression.toSkir(): SkirConversionResult<SkirTypeExpression> = SkirTypeCodec.encode(this)

fun SkirTypeExpression.toTypewriter(): SkirConversionResult<TypeExpression> = SkirTypeCodec.decode(this)

fun ResolvedTypeRef.toSkir(): SkirConversionResult<SkirResolvedTypeRef> = SkirTypeCodec.encode(this)

fun SkirResolvedTypeRef.toTypewriter(): SkirConversionResult<ResolvedTypeRef> = SkirTypeCodec.decode(this)

fun DataValue.toSkir(): SkirConversionResult<SkirTypedValue> = SkirDataValueCodec.encode(this)

fun SkirTypedValue.toTypewriter(): SkirConversionResult<DataValue> = SkirDataValueCodec.decode(this)

/** Returns a successful conversion value and throws one diagnostic exception on failure. */
fun <Value> SkirConversionResult<Value>.getOrThrow(): Value =
    when (this) {
        is SkirConversionResult.Success -> value
        is SkirConversionResult.Failure -> throw SkirConversionException(diagnostics)
    }

/** Returns a successful conversion value, or null when conversion failed. */
fun <Value> SkirConversionResult<Value>.getOrNull(): Value? =
    when (this) {
        is SkirConversionResult.Success -> value
        is SkirConversionResult.Failure -> null
    }

class SkirConversionException(
    val diagnostics: List<SkirConversionDiagnostic>,
) : IllegalArgumentException(diagnostics.joinToString(separator = "\n"))
