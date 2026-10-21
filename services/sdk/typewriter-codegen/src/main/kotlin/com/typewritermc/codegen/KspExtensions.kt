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
import com.typewritermc.types.floatScalar
import com.typewritermc.types.integerScalar
import kotlinx.serialization.SerialName
import skirout.editor.v1.type_catalog.FloatWidth
import skirout.editor.v1.type_catalog.IntegerWidth
import skirout.editor.v1.type_catalog.ScalarKind
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
        "kotlin.Unit" -> ScalarKind.UNIT
        "kotlin.Boolean" -> ScalarKind.BOOLEAN
        "kotlin.String", "kotlin.Char" -> ScalarKind.TEXT
        "kotlin.ByteArray" -> ScalarKind.BYTES
        "kotlin.Byte" -> integerScalar(IntegerWidth.SIGNED_EIGHT)
        "kotlin.Short" -> integerScalar(IntegerWidth.SIGNED_SIXTEEN)
        "kotlin.Int" -> integerScalar(IntegerWidth.SIGNED_THIRTY_TWO)
        "kotlin.Long", "java.math.BigInteger" -> integerScalar(IntegerWidth.SIGNED_SIXTY_FOUR)
        "kotlin.UByte" -> integerScalar(IntegerWidth.UNSIGNED_EIGHT)
        "kotlin.UShort" -> integerScalar(IntegerWidth.UNSIGNED_SIXTEEN)
        "kotlin.UInt" -> integerScalar(IntegerWidth.UNSIGNED_THIRTY_TWO)
        "kotlin.ULong" -> integerScalar(IntegerWidth.UNSIGNED_SIXTY_FOUR)
        "kotlin.Float" -> floatScalar(FloatWidth.THIRTY_TWO)
        "kotlin.Double" -> floatScalar(FloatWidth.SIXTY_FOUR)
        "java.math.BigDecimal" -> ScalarKind.DECIMAL
        "kotlin.time.Instant", "java.time.Instant" -> ScalarKind.TIMESTAMP
        "kotlin.time.Duration", "java.time.Duration" -> ScalarKind.DURATION
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
