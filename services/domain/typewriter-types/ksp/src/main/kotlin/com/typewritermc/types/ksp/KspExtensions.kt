package com.typewritermc.types.ksp

import com.google.devtools.ksp.symbol.KSType
import com.typewritermc.types.TypeGraph

/** Converts this compile time type into a portable graph using the supplied identity policy. */
fun KSType.toTypewriterGraph(identityPolicy: KspTypeIdentityPolicy = QualifiedKotlinTypeIdentityPolicy): KspTypeConversionResult =
    KspTypeGraphConverter(identityPolicy).convert(this)

/** Returns a successful graph and throws one diagnostic exception on failure. */
fun KspTypeConversionResult.getOrThrow(): TypeGraph =
    when (this) {
        is KspTypeConversionResult.Success -> graph
        is KspTypeConversionResult.Failure -> throw KspTypeConversionException(diagnostics)
    }

/** Returns a successful graph, or null when conversion failed. */
fun KspTypeConversionResult.getOrNull(): TypeGraph? =
    when (this) {
        is KspTypeConversionResult.Success -> graph
        is KspTypeConversionResult.Failure -> null
    }

class KspTypeConversionException(
    val diagnostics: List<KspTypeDiagnostic>,
) : IllegalArgumentException(diagnostics.joinToString(separator = "\n"))
