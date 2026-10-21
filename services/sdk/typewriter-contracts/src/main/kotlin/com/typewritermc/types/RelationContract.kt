package com.typewritermc.types

import com.typewritermc.configuration.RelativeFieldPattern
import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.NamedTypeTemplate
import skirout.editor.v1.type_catalog.TypeDefinitionId
import skirout.editor.v1.type_catalog.TypeTemplate

@Serializable
enum class EndpointSlot {
    First,
    Second,
}

@Serializable
enum class EndpointCardinality {
    One,
    Many,
}

data class EndpointDefinition(
    val id: EndpointId,
    val slot: EndpointSlot,
    val resource: NamedTypeTemplate,
    val cardinality: EndpointCardinality,
    val onDelete: RelationDeletePolicy,
)

data class RelationContract(
    val id: RelationId,
    val first: EndpointDefinition,
    val second: EndpointDefinition,
    val families: Set<RelationFamilyId> = emptySet(),
) {
    init {
        require(first.slot == EndpointSlot.First) { "First endpoint must use the first slot." }
        require(second.slot == EndpointSlot.Second) { "Second endpoint must use the second slot." }
    }
}

data class EndpointBindingTemplate(
    val endpoint: EndpointId,
    val containingResource: NamedTypeTemplate,
    val valueOwner: TypeDefinitionId,
    val relativePath: RelativeFieldPattern,
    val target: TypeTemplate,
    val containsCollection: Boolean,
)

/** Checks the endpoint ids and resource templates a generated relation provider declared. */
fun RelationContract.requireValid(): RelationContract =
    apply {
        listOf(first, second).forEach { endpoint ->
            endpoint.id.requireValid()
            endpoint.resource.requireValid()
        }
    }

/** Checks the endpoint, owner and templates a generated endpoint bindings provider declared. */
fun EndpointBindingTemplate.requireValid(): EndpointBindingTemplate =
    apply {
        endpoint.requireValid()
        containingResource.requireValid()
        valueOwner.requireValid()
        target.requireValid()
    }

/** Reports whether this relation belongs to the resource ownership family. */
val RelationContract.ownsResources: Boolean
    get() = RelationFamilyId(RESOURCE_OWNERSHIP_FAMILY_ID) in families

/** Whether following first to second endpoints must never return to the start. */
val RelationContract.isAcyclic: Boolean
    get() = RelationFamilyId(ACYCLIC_RELATION_FAMILY_ID) in families

fun RelationId.endpointId(slot: EndpointSlot): EndpointId = EndpointId(value = "$value:${slot.name.lowercase()}")
