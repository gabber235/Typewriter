package com.typewritermc.authoring

import com.typewritermc.types.Resource
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.catalog.CheckedCatalog
import kotlinx.serialization.Serializable
import kotlin.reflect.KClass

/** Stable identity for one kind of authored resource. */
@JvmInline
@Serializable
value class ResourceDefinitionId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Resource definition ids must not be blank." }
    }
}

/** Structural type family accepted by one authored resource. */
@Serializable
data class AuthoringResourceDefinition(
    val id: ResourceDefinitionId,
    val root: TypeDefinitionId,
    val navigationHandler: String = "generic",
) {
    init {
        require(navigationHandler.isNotBlank()) { "Resource navigation handlers must not be blank." }
    }
}

fun Collection<AuthoringResourceDefinition>.definitionFor(
    selection: TypeSelection,
    catalog: CheckedCatalog,
): AuthoringResourceDefinition {
    val definition =
        when (selection) {
            is TypeSelection.Complete -> selection.use.definition
            is TypeSelection.Pending -> selection.definition
        }
    val candidates = filter { it.root == definition || catalog.isNominalSubtype(definition, it.root) }
    return requireNotNull(candidates.singleOrNull()) {
        "Authored type $definition must belong to exactly one resource definition."
    }
}

/** Makes a resource family and its complete type closure part of the generated schema contribution. */
@Target(AnnotationTarget.PROPERTY)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterResourceDefinition(
    val id: String,
    val root: KClass<out Resource>,
    val navigationHandler: String = "generic",
)
