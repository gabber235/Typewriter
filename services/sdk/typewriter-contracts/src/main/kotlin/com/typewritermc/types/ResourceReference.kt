package com.typewritermc.types

import com.typewritermc.types.skir.ValuePathSerializer
import kotlinx.serialization.Serializable
import skirout.editor.v1.type_catalog.ValuePath
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId

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

/** The owner holds its owned resources: each owned resource has one owner, and ownership never loops. */
@TypewriterRelationFamily(RESOURCE_OWNERSHIP_FAMILY_ID)
interface Owning : Acyclic

const val RESOURCE_OWNERSHIP_FAMILY_ID = "resource.ownership"

/** Following first endpoint to second endpoint never returns to the start. */
@TypewriterRelationFamily(ACYCLIC_RELATION_FAMILY_ID)
interface Acyclic

const val ACYCLIC_RELATION_FAMILY_ID = "relation.acyclic"

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
    @Serializable(with = ValuePathSerializer::class)
    val opposite: ValuePath? = null,
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

/** The generated form of this author facing id, which generated values such as locations and links hold. */
fun ResourceId.toSkir(): SkirResourceId = SkirResourceId(value = value)

/** The author facing form of a generated resource id; rejects a blank id. */
fun SkirResourceId.toResourceId(): ResourceId = ResourceId(value)

@Serializable
enum class RelationDeletePolicy {
    RESTRICT,
    CASCADE,
    CLEAR,
}
