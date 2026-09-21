package com.typewritermc.types.skir

import com.typewritermc.types.DataValue
import com.typewritermc.types.ResolvedTypeRef
import com.typewritermc.types.TypeCatalog
import com.typewritermc.types.TypeExpression
import skirout.editor.v1.type_catalog.ResolvedTypeRef as SkirResolvedTypeRef
import skirout.editor.v1.type_catalog.TypeCatalog as SkirTypeCatalog
import skirout.editor.v1.type_catalog.TypeExpression as SkirTypeExpression
import skirout.editor.v1.type_catalog.TypedValue as SkirTypedValue

/** Converts a Typewriter catalog to the generated Skir catalog model. */
fun TypeCatalog.toSkir(): SkirConversionResult<SkirTypeCatalog> = SkirTypeCodec.encode(this)

/** Converts a generated Skir catalog to the Typewriter catalog model. */
fun SkirTypeCatalog.toTypewriter(): SkirConversionResult<TypeCatalog> = SkirTypeCodec.decode(this)

/** Converts one Typewriter type expression to its generated Skir representation. */
fun TypeExpression.toSkir(): SkirConversionResult<SkirTypeExpression> = SkirTypeCodec.encode(this)

/** Converts one generated Skir type expression to the Typewriter representation. */
fun SkirTypeExpression.toTypewriter(): SkirConversionResult<TypeExpression> = SkirTypeCodec.decode(this)

/** Converts a resolved Typewriter reference while preserving identity, revision, and arguments. */
fun ResolvedTypeRef.toSkir(): SkirConversionResult<SkirResolvedTypeRef> = SkirTypeCodec.encode(this)

/** Converts a generated Skir reference while preserving identity, revision, and arguments. */
fun SkirResolvedTypeRef.toTypewriter(): SkirConversionResult<ResolvedTypeRef> = SkirTypeCodec.decode(this)

/** Converts a portable Typewriter value tree to a generated Skir typed value. */
fun DataValue.toSkir(): SkirConversionResult<SkirTypedValue> = SkirDataValueCodec.encode(this)

/** Converts a generated Skir typed value to a portable Typewriter value tree. */
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

/** Reports one or more diagnostics from a failed Skir conversion. */
class SkirConversionException(
    val diagnostics: List<SkirConversionDiagnostic>,
) : IllegalArgumentException(diagnostics.joinToString(separator = "\n"))
