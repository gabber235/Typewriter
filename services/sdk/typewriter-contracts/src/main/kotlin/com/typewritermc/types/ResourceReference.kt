package com.typewritermc.types

import build.skir.JsonFlavor
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.KSerializer
import kotlinx.serialization.Serializable
import kotlinx.serialization.SerializationException
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonDecoder
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonEncoder
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

/**
 * An author facing link to [target]. Author types are kotlinx serializable through [TypewriterType], so the generated
 * [opposite] path is stored as its readable Skir JSON.
 */
@Serializable
data class Ref<E : RelationshipEndpoint<*, *>, out T : Resource>(
    val target: ResourceId,
    @Serializable(with = OppositePathSerializer::class)
    val opposite: ValuePath? = null,
)

/** Embeds the readable Skir JSON of a link's opposite path; decoding checks the path like every other entry point. */
@OptIn(ExperimentalSerializationApi::class)
private object OppositePathSerializer : KSerializer<ValuePath> {
    override val descriptor: SerialDescriptor = SerialDescriptor("skir.ValuePath", JsonElement.serializer().descriptor)

    override fun serialize(
        encoder: Encoder,
        value: ValuePath,
    ) {
        val json = ValuePath.serializer.toJson(value, JsonFlavor.READABLE)
        if (encoder is JsonEncoder) encoder.encodeJsonElement(json) else encoder.encodeString(json.toString())
    }

    override fun deserialize(decoder: Decoder): ValuePath {
        val json = if (decoder is JsonDecoder) decoder.decodeJsonElement() else Json.parseToJsonElement(decoder.decodeString())
        return runCatching { ValuePath.serializer.fromJson(json).requireValid() }
            .getOrElse { throw SerializationException("Stored opposite path is invalid.", it) }
    }
}

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
