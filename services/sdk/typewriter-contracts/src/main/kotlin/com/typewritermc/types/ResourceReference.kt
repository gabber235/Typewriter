package com.typewritermc.types

import com.typewritermc.authoring.ValuePath
import kotlinx.serialization.Serializable

interface Resource

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class ReferenceContract(
    val id: String,
)

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterRelationFamily(
    val id: String,
)

@TypewriterRelationFamily(RESOURCE_OWNERSHIP_FAMILY_ID)
interface Owning

const val RESOURCE_OWNERSHIP_FAMILY_ID = "resource.ownership"

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class DeletionPolicy(
    val onDelete: RelationDeletePolicy,
)

interface One<R : Resource>

interface Many<R : Resource>

interface RelationshipEndpoint<R : Resource, T : Resource>

@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterGeneratedEndpoint(
    val relation: String,
    val slot: EndpointSlot,
    val requiresCollection: Boolean,
)

@Serializable
data class Ref<E : RelationshipEndpoint<*, *>, out T : Resource>(
    val target: ResourceId,
    val opposite: ValuePath? = null,
)

@Serializable
data class LinkTarget(
    val resource: ResourceId,
    val opposite: ValuePath?,
)

@Serializable
data class ResourceRecord<I, C>(
    val id: I,
    val content: C,
)

@JvmInline
@Serializable
@TypewriterString
value class ResourceId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Resource ids must not be blank." }
    }
}

@JvmInline
@Serializable
value class RelationFamilyId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Relation family ids must not be blank." }
    }
}

@JvmInline
@Serializable
value class RelationId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Relation ids must not be blank." }
    }
}

@Serializable
enum class RelationDeletePolicy {
    RESTRICT,
    CASCADE,
    CLEAR,
}
