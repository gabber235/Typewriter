package com.typewritermc.types.ksp

import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.KSDeclaration
import com.google.devtools.ksp.symbol.KSPropertyDeclaration
import com.typewritermc.codegen.annotation
import kotlinx.serialization.SerialName
import kotlinx.serialization.Transient

/**
 * Maps Kotlin property names to serialized field names for generated schema and value adapters.
 *
 * The result includes stored, non delegated properties and honors [kotlinx.serialization.SerialName]. Transient,
 * extension, computed, and delegated properties are excluded because they do not belong to the serialized value.
 */
fun KSClassDeclaration.serializedFieldNames(): Map<String, String> =
    getAllProperties()
        .filter(KSPropertyDeclaration::isSerializedProperty)
        .associate { property ->
            property.simpleName.asString() to (property.serialName ?: property.simpleName.asString())
        }

private val KSDeclaration.serialName: String?
    get() = annotation<SerialName>()?.value

private val KSPropertyDeclaration.isSerializedProperty: Boolean
    get() =
        extensionReceiver == null &&
            hasBackingField &&
            !isDelegated() &&
            annotation<Transient>() == null
