package com.typewritermc.types

import com.typewritermc.configuration.requireValid
import skirout.editor.v1.catalog.EndpointBindingTemplate
import skirout.editor.v1.catalog.EndpointCardinality
import skirout.editor.v1.catalog.EndpointDefinition
import skirout.editor.v1.catalog.RelationContract
import skirout.editor.v1.catalog.RelationDeletePolicy
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.RelationFamilyId
import skirout.editor.v1.type_catalog.RelationId
import skirout.editor.v1.catalog.EndpointSlot as CatalogEndpointSlot

/**
 * The side of a relation a generated endpoint interface stands for, as an annotation argument of
 * [TypewriterGeneratedEndpoint]. Catalog values use the generated [CatalogEndpointSlot].
 */
enum class EndpointSlot {
    First,
    Second,
}

/** The catalog form of this annotation slot. */
val EndpointSlot.catalogSlot: CatalogEndpointSlot
    get() =
        when (this) {
            EndpointSlot.First -> CatalogEndpointSlot.FIRST
            EndpointSlot.Second -> CatalogEndpointSlot.SECOND
        }

/** The catalog form of this author facing delete policy. */
val com.typewritermc.types.RelationDeletePolicy.catalogPolicy: RelationDeletePolicy
    get() =
        when (this) {
            com.typewritermc.types.RelationDeletePolicy.RESTRICT -> RelationDeletePolicy.RESTRICT
            com.typewritermc.types.RelationDeletePolicy.CASCADE -> RelationDeletePolicy.CASCADE
            com.typewritermc.types.RelationDeletePolicy.CLEAR -> RelationDeletePolicy.CLEAR
        }

/**
 * A relation contract with its [families] in id order, the canonical form the catalog publishes. The first endpoint
 * must use the first slot and the second endpoint the second slot.
 */
fun RelationContract.Companion.of(
    id: RelationId,
    first: EndpointDefinition,
    second: EndpointDefinition,
    families: Set<RelationFamilyId> = emptySet(),
): RelationContract =
    RelationContract(id = id, first = first, second = second, families = families.sortedBy { it.value })
        .requireSlots()

/**
 * Checks the relation id, families, endpoint ids, slots, cardinalities, delete policies and resource templates of a
 * relation read from outside the runtime, such as a generated relation provider.
 */
fun RelationContract.requireValid(): RelationContract =
    apply {
        id.requireValid()
        families.forEach { it.requireValid() }
        require(families.map { it.value } == families.map { it.value }.distinct().sorted()) {
            "Relation families must be unique and in id order."
        }
        requireSlots()
        listOf(first, second).forEach { endpoint ->
            endpoint.id.requireValid()
            endpoint.resource.requireValid()
            require(endpoint.cardinality != EndpointCardinality.UNKNOWN) { "Unknown endpoint cardinality." }
            require(endpoint.onDelete != RelationDeletePolicy.UNKNOWN) { "Unknown relation delete policy." }
        }
    }

private fun RelationContract.requireSlots(): RelationContract =
    apply {
        require(first.slot == CatalogEndpointSlot.FIRST) { "First endpoint must use the first slot." }
        require(second.slot == CatalogEndpointSlot.SECOND) { "Second endpoint must use the second slot." }
    }

/** Checks the endpoint, owner, path and templates a generated endpoint bindings provider declared. */
fun EndpointBindingTemplate.requireValid(): EndpointBindingTemplate =
    apply {
        endpoint.requireValid()
        containingResource.requireValid()
        valueOwner.requireValid()
        relativePath.requireValid()
        target.requireValid()
    }

/** Reports whether this relation belongs to the resource ownership family. */
val RelationContract.ownsResources: Boolean
    get() = RelationFamilyId(value = RESOURCE_OWNERSHIP_FAMILY_ID) in families

/** Whether following first to second endpoints must never return to the start. */
val RelationContract.isAcyclic: Boolean
    get() = RelationFamilyId(value = ACYCLIC_RELATION_FAMILY_ID) in families

fun RelationId.endpointId(slot: CatalogEndpointSlot): EndpointId =
    EndpointId(
        value =
            "$value:" +
                when (slot) {
                    CatalogEndpointSlot.FIRST -> "first"
                    CatalogEndpointSlot.SECOND -> "second"
                    else -> throw IllegalArgumentException("Unknown endpoint slot.")
                },
    )
