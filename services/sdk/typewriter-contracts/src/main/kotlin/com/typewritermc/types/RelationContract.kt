package com.typewritermc.types

import com.typewritermc.configuration.RelativeFieldPattern
import kotlinx.serialization.Serializable

@JvmInline
@Serializable
value class EndpointId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Endpoint ids must not be blank." }
    }
}

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

@Serializable
data class EndpointDefinition(
    val id: EndpointId,
    val slot: EndpointSlot,
    val resource: TypeTemplate.Named,
    val cardinality: EndpointCardinality,
    val onDelete: RelationDeletePolicy,
)

@Serializable
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

@Serializable
data class EndpointBindingTemplate(
    val endpoint: EndpointId,
    val containingResource: TypeTemplate.Named,
    val valueOwner: TypeDefinitionId,
    val relativePath: RelativeFieldPattern,
    val target: TypeTemplate,
    val containsCollection: Boolean,
)

fun RelationId.endpointId(slot: EndpointSlot): EndpointId = EndpointId("$value:${slot.name.lowercase()}")
