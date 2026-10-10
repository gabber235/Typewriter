package com.typewritermc.codegen

import com.google.devtools.ksp.KspExperimental
import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.getAnnotationsByType
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSAnnotation
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.squareup.kotlinpoet.CodeBlock
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.ScalarKind
import kotlin.reflect.KClass

/** Finds symbols using the actual annotation type so processors do not duplicate qualified names as strings. */
fun Resolver.getSymbolsWithAnnotation(annotation: KClass<out Annotation>): Sequence<KSAnnotated> =
    getSymbolsWithAnnotation(requireNotNull(annotation.qualifiedName))

/** Returns whether this declaration transitively implements the supplied Kotlin type. */
fun KSClassDeclaration.implements(type: KClass<*>): Boolean {
    val qualifiedName = requireNotNull(type.qualifiedName)
    return getAllSuperTypes().any { it.declaration.qualifiedName?.asString() == qualifiedName }
}

/** Finds the raw annotation of [type] for KSP values that need symbol resolution, such as class arguments. */
fun KSAnnotated.rawAnnotation(type: KClass<out Annotation>): KSAnnotation? {
    val qualifiedName = requireNotNull(type.qualifiedName)
    return annotations.singleOrNull {
        it.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == qualifiedName
    }
}

/** Finds one raw annotation without requiring its declaration on the processor classpath. */
fun KSAnnotated.rawAnnotation(qualifiedName: String): KSAnnotation? =
    annotations.singleOrNull {
        it.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == qualifiedName
    }

/** Returns the single typed annotation of [type], including declared default values. */
@OptIn(KspExperimental::class)
inline fun <reified T : Annotation> KSAnnotated.annotation(): T? = getAnnotationsByType(T::class).singleOrNull()

/** Reads a raw annotation argument for values that require KSP symbol resolution. */
fun KSAnnotation.argument(name: String): Any? = arguments.singleOrNull { it.name?.asString() == name }?.value

/**
 * Converts an open identifier into the stable upper camel form used by generated declaration names.
 *
 * Separators and other non alphanumeric characters are discarded, so the result is suitable for a generated
 * Kotlin declaration when the input contains human supplied names.
 */
fun String.toUpperCamelIdentifier(): String =
    split(Regex("[^A-Za-z0-9]+"))
        .filter(String::isNotEmpty)
        .joinToString("") { it.replaceFirstChar(Char::uppercase) }

/**
 * Emits deterministic KotlinPoet source for a string map.
 *
 * Sorting keys keeps generated source stable across KSP runs and makes generated diffs reflect semantic changes.
 */
fun Map<String, String>.stringMapCode(): CodeBlock {
    val builder = CodeBlock.builder().add("mapOf(\n").indent()
    toSortedMap().forEach { (key, value) -> builder.add("%S to %S,\n", key, value) }
    return builder.unindent().add(")").build()
}

/** Interprets every portable scalar alias through one shared KSP policy. */
fun KSType.portableScalarKind(): ScalarKind? =
    when (declaration.qualifiedName?.asString()) {
        "kotlin.Unit" -> ScalarKind.Unit
        "kotlin.Boolean" -> ScalarKind.Boolean
        "kotlin.String", "kotlin.Char" -> ScalarKind.Text
        "kotlin.ByteArray" -> ScalarKind.Bytes
        "kotlin.Byte" -> ScalarKind.Integer(IntegerWidth.SIGNED_8)
        "kotlin.Short" -> ScalarKind.Integer(IntegerWidth.SIGNED_16)
        "kotlin.Int" -> ScalarKind.Integer(IntegerWidth.SIGNED_32)
        "kotlin.Long", "java.math.BigInteger" -> ScalarKind.Integer(IntegerWidth.SIGNED_64)
        "kotlin.UByte" -> ScalarKind.Integer(IntegerWidth.UNSIGNED_8)
        "kotlin.UShort" -> ScalarKind.Integer(IntegerWidth.UNSIGNED_16)
        "kotlin.UInt" -> ScalarKind.Integer(IntegerWidth.UNSIGNED_32)
        "kotlin.ULong" -> ScalarKind.Integer(IntegerWidth.UNSIGNED_64)
        "kotlin.Float" -> ScalarKind.Float(FloatWidth.FLOAT_32)
        "kotlin.Double" -> ScalarKind.Float(FloatWidth.FLOAT_64)
        "java.math.BigDecimal" -> ScalarKind.Decimal
        "kotlin.time.Instant", "java.time.Instant" -> ScalarKind.Timestamp
        "kotlin.time.Duration", "java.time.Duration" -> ScalarKind.Duration
        else -> null
    }
