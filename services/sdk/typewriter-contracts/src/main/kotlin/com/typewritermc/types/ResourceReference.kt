package com.typewritermc.types

import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder

/**
 * Marks domain types that may be addressed through a typed [Ref].
 *
 * The marker does not provide lookup, persistence, or a universal identity property.
 */
interface Referenceable

/** Binds immutable authored content to its stable persistence identity. */
@Serializable
data class Resource<I, C>(
    val id: I,
    val content: C,
)

/**
 * Marks one generated, synchronized relationship between two authored resource types.
 *
 * The marker exists only at the Kotlin declaration boundary. Generated catalog metadata owns runtime relation
 * identity and policy. Authored values lower [ToOne] and [ToMany] to ordinary reference shapes.
 */
interface Relation<S : Referenceable, T : Referenceable>

/** Groups independently declared relation markers for graph queries and domain rules. */
@JvmInline
@Serializable
value class RelationFamilyId(val value: String) {
    init {
        require(value.isNotBlank()) { "Relation family ids must not be blank." }
    }
}

/** Publishes a family implemented by concrete relation markers. */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterRelationFamily(val id: String)

/** Ownership has one immediate parent and no cycles across all implementing markers. */
@TypewriterRelationFamily(RESOURCE_OWNERSHIP_FAMILY_ID)
interface OwnsResource<S : Referenceable, T : Referenceable> : Relation<S, T>

const val RESOURCE_OWNERSHIP_FAMILY_ID = "resource.ownership"

/** Declares the stable identity and deletion policy of one synchronized relationship. */
@Target(AnnotationTarget.CLASS)
@Retention(AnnotationRetention.BINARY)
annotation class TypewriterRelation(
    val id: String,
    val onSourceDelete: RelationDeletePolicy = RelationDeletePolicy.RESTRICT,
    val onTargetDelete: RelationDeletePolicy = RelationDeletePolicy.RESTRICT,
)

/** Controls what deleting one endpoint does to links and resources at the opposite endpoint. */
@Serializable
enum class RelationDeletePolicy {
    RESTRICT,
    CASCADE,
    CLEAR,
}

/** Stable generated relation identity. */
@JvmInline
@Serializable
value class RelationId(
    val value: String,
) {
    init {
        require(value.matches(RELATION_ID_PATTERN)) { "Relation ids must contain exactly 32 hexadecimal characters." }
    }
}

/**
 * Declares a synchronized relation endpoint with single cardinality.
 *
 * Serialization is exactly the wrapped [Ref]. The wrapper is source metadata for code generation, not a distinct
 * authored value shape.
 */
@JvmInline
@Serializable
value class ToOne<R : Relation<*, *>, out T : Referenceable>(
    val reference: Ref<T>,
) {
    val id: ResourceId get() = reference.id
}

/**
 * Declares a synchronized relation endpoint with ordered, unique targets.
 *
 * Serialization is exactly the wrapped reference list. Each target may occur once in the field.
 */
@JvmInline
@Serializable
value class ToMany<R : Relation<*, *>, out T : Referenceable>(
    val references: List<Ref<T>>,
) : List<Ref<T>> by references {
    init {
        require(references.map(Ref<T>::id).distinct().size == references.size) {
            "A ToMany field cannot repeat a target resource."
        }
    }

    companion object {
        fun <R : Relation<*, *>, T : Referenceable> empty(): ToMany<R, T> = ToMany(emptyList())
    }
}

/** Opaque authored resource identity with no persistence or resource kind encoding. */
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

/** Creates a typed address for any referenceable authored resource. */
fun <T : Referenceable> ResourceId.ref(): Ref<T> = Ref(this)

/**
 * Carries a typed resource address without loading the referenced object.
 *
 * The generic type aids Kotlin callers but is erased from the scalar serialized reference. Receiving boundaries
 * must verify the target table and expected type; construction does not establish existence.
 */
@Serializable(with = RefSerializer::class)
data class Ref<out T : Referenceable>(
    val id: ResourceId,
)

/**
 * Encodes references as one opaque resource id.
 *
 * The generic target type is not included in the payload. Parsing failures propagate to the receiving boundary.
 */
object RefSerializer : KSerializer<Ref<*>> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("Ref", PrimitiveKind.STRING)

    override fun serialize(
        encoder: Encoder,
        value: Ref<*>,
    ) {
        encoder.encodeString(value.id.value)
    }

    override fun deserialize(decoder: Decoder): Ref<*> = Ref<Referenceable>(ResourceId(decoder.decodeString()))
}

private val RELATION_ID_PATTERN = Regex("[0-9a-fA-F]{32}")
