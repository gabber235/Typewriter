package com.typewritermc.codegen

import com.google.devtools.ksp.KspExperimental
import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.getAnnotationsByType
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSAnnotation
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSDeclaration
import com.google.devtools.ksp.symbol.KSType
import com.google.devtools.ksp.symbol.KSTypeParameter
import com.google.devtools.ksp.symbol.Modifier
import com.squareup.kotlinpoet.ClassName
import com.squareup.kotlinpoet.CodeBlock
import com.typewritermc.types.FloatWidth
import com.typewritermc.types.IntegerWidth
import com.typewritermc.types.ScalarKind
import kotlinx.serialization.SerialName
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

/** Returns whether this declaration transitively implements [type], for API types codegen cannot load. */
fun KSClassDeclaration.implements(type: ClassName): Boolean =
    getAllSuperTypes().any { it.declaration.qualifiedName?.asString() == type.canonicalName }

/**
 * Reads an enum annotation argument from source (KSClassDeclaration) or binary (KSType) metadata; null when the
 * argument is absent or not an entry of [E], so callers can report it.
 */
inline fun <reified E : Enum<E>> KSAnnotation.enumArgumentOrNull(name: String): E? {
    val entry =
        when (val value = argument(name)) {
            is KSClassDeclaration -> value.simpleName.asString()
            is KSType -> value.declaration.simpleName.asString()
            else -> return null
        }
    return enumValues<E>().singleOrNull { it.name == entry }
}

/** Returns the single typed annotation of [type], including declared default values. */
@OptIn(KspExperimental::class)
inline fun <reified T : Annotation> KSAnnotated.annotation(): T? = getAnnotationsByType(T::class).singleOrNull()

/** Reads a raw annotation argument for values that require KSP symbol resolution. */
fun KSAnnotation.argument(name: String): Any? = arguments.singleOrNull { it.name?.asString() == name }?.value

/**
 * Converts an open identifier into the stable upper camel form used by generated declaration names.
 *
 * Separators and other non alphanumeric characters are discarded. The result can be empty or start with a digit;
 * callers remain responsible for any additional Kotlin identifier constraints.
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

/** The name this declaration declares with `@SerialName`, or null without one. */
val KSDeclaration.serialName: String?
    get() = annotation<SerialName>()?.value

/** The bounds of this type parameter other than `Any`, which constrain it at compile time. */
fun KSTypeParameter.compiledBounds(): Sequence<KSType> =
    bounds.map { it.resolve() }.filter { it.declaration.qualifiedName?.asString() != "kotlin.Any" }

/** The portable scalar kind of a value class whose single property is a portable scalar, otherwise null. */
fun KSClassDeclaration.valueClassScalarKind(): ScalarKind? = valueClassStoredType()?.portableScalarKind()

/** The type of a value class's single stored property, otherwise null. */
fun KSClassDeclaration.valueClassStoredType(): KSType? {
    if (Modifier.VALUE !in modifiers && annotation<JvmInline>() == null) return null
    return primaryConstructor
        ?.parameters
        ?.singleOrNull()
        ?.type
        ?.resolve()
}
