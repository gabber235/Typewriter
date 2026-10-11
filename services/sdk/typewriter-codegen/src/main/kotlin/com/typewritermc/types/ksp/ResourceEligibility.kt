package com.typewritermc.types.ksp

import com.google.devtools.ksp.getAllSuperTypes
import com.google.devtools.ksp.symbol.KSClassDeclaration
import com.google.devtools.ksp.symbol.Modifier
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.catalog.DeclarationDiagnostic

sealed interface ResourceEligibility {
    data class Registered(
        val roots: Set<ResourceDefinitionId>,
    ) : ResourceEligibility

    data class Abstract(
        val knownRoots: Set<ResourceDefinitionId>,
    ) : ResourceEligibility

    data object Embedded : ResourceEligibility

    data class Invalid(
        val diagnostics: List<DeclarationDiagnostic>,
    ) : ResourceEligibility
}

interface ResourceDiscovery {
    val registrations: Map<TypeDefinitionId, ResourceDefinitionId>

    fun definition(declaration: KSClassDeclaration): TypeDefinitionId
}

context(discovery: ResourceDiscovery)
fun KSClassDeclaration.resourceEligibility(): ResourceEligibility {
    val resourceTypes =
        (sequenceOf(this) + getAllSuperTypes().mapNotNull { it.declaration as? KSClassDeclaration })
            .filter { declaration ->
                declaration.qualifiedName?.asString() == RESOURCE_TYPE ||
                    declaration.getAllSuperTypes().any { it.declaration.qualifiedName?.asString() == RESOURCE_TYPE }
            }.toList()
    if (resourceTypes.isEmpty()) return ResourceEligibility.Embedded
    val roots = resourceTypes.mapNotNull { discovery.registrations[discovery.definition(it)] }.toSet()
    if (Modifier.ABSTRACT in modifiers || classKind.name == "INTERFACE") {
        return ResourceEligibility.Abstract(roots)
    }
    return if (roots.isNotEmpty()) {
        ResourceEligibility.Registered(roots)
    } else {
        ResourceEligibility.Invalid(
            listOf(DeclarationDiagnostic(discovery.definition(this), "unregistered_resource_root")),
        )
    }
}

context(discovery: ResourceDiscovery)
fun KSClassDeclaration.requireResourceEndpoint(): List<DeclarationDiagnostic> =
    when (val eligibility = resourceEligibility()) {
        is ResourceEligibility.Registered, is ResourceEligibility.Abstract -> emptyList()
        ResourceEligibility.Embedded -> listOf(DeclarationDiagnostic(discovery.definition(this), "embedded_relation_endpoint"))
        is ResourceEligibility.Invalid -> eligibility.diagnostics
    }

private const val RESOURCE_TYPE = "com.typewritermc.types.Resource"
