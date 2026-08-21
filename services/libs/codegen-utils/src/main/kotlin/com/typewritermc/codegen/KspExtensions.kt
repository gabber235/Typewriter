package com.typewritermc.codegen

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.processing.Resolver
import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSAnnotation
import com.google.devtools.ksp.symbol.KSClassDeclaration
import kotlin.reflect.KClass

/** Finds symbols using the actual annotation type so processors do not duplicate qualified names as strings. */
fun Resolver.getSymbolsWithAnnotation(annotation: KClass<out Annotation>): Sequence<KSAnnotated> =
    getSymbolsWithAnnotation(requireNotNull(annotation.qualifiedName))

/** Returns whether this declaration transitively implements the supplied Kotlin type. */
fun KSClassDeclaration.implements(type: KClass<*>): Boolean {
    val qualifiedName = requireNotNull(type.qualifiedName)
    return getAllSuperTypes().any { it.declaration.qualifiedName?.asString() == qualifiedName }
}

/** Finds the single annotation of [type], returning `null` when it is absent. */
fun KSAnnotated.annotation(type: KClass<out Annotation>): KSAnnotation? {
    val qualifiedName = requireNotNull(type.qualifiedName)
    return annotations.singleOrNull {
        it.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == qualifiedName
    }
}

/** Reads a named string argument without coercing values of another annotation type. */
fun KSAnnotation.stringArgument(name: String): String? = arguments.singleOrNull { it.name?.asString() == name }?.value as? String

/** Converts an open identifier into the stable upper camel form used by generated declaration names. */
fun String.toUpperCamelIdentifier(): String =
    split(Regex("[^A-Za-z0-9]+"))
        .filter(String::isNotEmpty)
        .joinToString("") { it.replaceFirstChar(Char::uppercase) }
