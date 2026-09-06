package com.typewritermc.types.ksp

import com.google.devtools.ksp.symbol.KSAnnotated
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSDeclaration
import com.google.devtools.ksp.symbol.KSPropertyDeclaration

/**
 * Maps Kotlin property names to serialized field names for generated schema and value adapters. This keeps
 * generated access aligned with serialization annotations rather than assuming source names are wire names.
 */
fun KSClassDeclaration.serializedFieldNames(): Map<String, String> =
    getAllProperties()
        .filter(KSPropertyDeclaration::isSerializedProperty)
        .associate { property ->
            property.simpleName.asString() to (property.serialName ?: property.simpleName.asString())
        }

private val KSDeclaration.serialName: String?
    get() = annotation(SERIAL_NAME_ANNOTATION)?.argument("value") as? String

private val KSPropertyDeclaration.isSerializedProperty: Boolean
    get() =
        extensionReceiver == null &&
            hasBackingField &&
            !isDelegated() &&
            !hasAnnotation(TRANSIENT_ANNOTATION)

private fun KSAnnotated.hasAnnotation(qualifiedName: String): Boolean = annotation(qualifiedName) != null

private fun KSAnnotated.annotation(qualifiedName: String) =
    annotations.firstOrNull {
        it.annotationType
            .resolve()
            .declaration.qualifiedName
            ?.asString() == qualifiedName
    }

private fun com.google.devtools.ksp.symbol.KSAnnotation.argument(name: String): Any? =
    arguments.firstOrNull { it.name?.asString() == name }?.value

private const val SERIAL_NAME_ANNOTATION = "kotlinx.serialization.SerialName"
private const val TRANSIENT_ANNOTATION = "kotlinx.serialization.Transient"
