package com.typewritermc.types

import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import kotlinx.serialization.json.Json

/**
 * Marks domain types that may be addressed through a typed [Ref].
 *
 * The marker does not provide lookup, persistence, or a universal identity property.
 */
interface Referenceable

/**
 * Combines a validated table name with a typed record key.
 *
 * [referenceString] preserves ordinary string keys and uses a reserved prefix plus JSON for nonstring keys.
 * Strings beginning with that prefix are escaped. Use [parse] for the inverse instead of splitting or coercing
 * keys manually.
 */
@Serializable
data class ResourceId(
    val table: String,
    val key: RecordIdKey,
) {
    init {
        require(TABLE_PATTERN.matches(table)) { "Resource tables must use lowercase snake case." }
    }

    constructor(table: String, key: String) : this(table, RecordIdKey.String(key))

    fun referenceString(): String = "$table:${key.referenceString()}"

    companion object {
        fun parse(value: String): ResourceId {
            val separator = value.indexOf(':')
            require(separator > 0) { "Resource references must contain a table and key." }
            return ResourceId(value.substring(0, separator), value.substring(separator + 1).recordIdKey())
        }
    }
}

/**
 * Carries a typed resource address without loading the referenced object.
 *
 * The generic type aids Kotlin callers but is erased from the scalar serialized reference. Receiving boundaries
 * must verify the target table and expected type; construction does not establish existence.
 */
@Serializable(with = RefSerializer::class)
@TypewriterString
data class Ref<out T : Referenceable>(
    val id: ResourceId,
) {
    constructor(table: String, key: String) : this(ResourceId(table, key))
}

/**
 * Encodes references with [ResourceId.referenceString] and reconstructs their typed key on decode.
 *
 * The generic target type is not included in the payload. Parsing failures propagate to the receiving boundary.
 */
object RefSerializer : KSerializer<Ref<*>> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("Ref", PrimitiveKind.STRING)

    override fun serialize(
        encoder: Encoder,
        value: Ref<*>,
    ) {
        encoder.encodeString(value.id.referenceString())
    }

    override fun deserialize(decoder: Decoder): Ref<*> = Ref<Referenceable>(ResourceId.parse(decoder.decodeString()))
}

/**
 * Preserves the database identity distinction between strings, numbers, UUIDs, arrays, and objects.
 *
 * Do not flatten keys with toString for persistence or transport. Composite keys contain [RecordIdValue] trees;
 * UUID keys validate syntax at construction.
 */
@Serializable
sealed interface RecordIdKey {
    @Serializable
    @SerialName("number")
    data class Number(
        val value: Long,
    ) : RecordIdKey

    @Serializable
    @SerialName("string")
    data class String(
        val value: kotlin.String,
    ) : RecordIdKey

    @Serializable
    @SerialName("uuid")
    data class Uuid(
        val value: kotlin.String,
    ) : RecordIdKey {
        init {
            require(UUID_PATTERN.matches(value)) { "Record id UUID keys must use canonical UUID syntax." }
        }
    }

    @Serializable
    @SerialName("array")
    data class Array(
        val values: List<RecordIdValue>,
    ) : RecordIdKey

    @Serializable
    @SerialName("object")
    data class Object(
        val values: Map<kotlin.String, RecordIdValue>,
    ) : RecordIdKey
}

/**
 * Represents values nested inside array and object record keys.
 *
 * It is separate from [DataValue] because database key identity has its own supported value shapes and
 * serialization contract.
 */
@Serializable
sealed interface RecordIdValue {
    @Serializable
    @SerialName("null")
    data object Null : RecordIdValue

    @Serializable
    @SerialName("boolean")
    data class Boolean(
        val value: kotlin.Boolean,
    ) : RecordIdValue

    @Serializable
    @SerialName("number")
    data class Number(
        val value: Long,
    ) : RecordIdValue

    @Serializable
    @SerialName("float")
    data class Float(
        val value: Double,
    ) : RecordIdValue

    @Serializable
    @SerialName("string")
    data class String(
        val value: kotlin.String,
    ) : RecordIdValue

    @Serializable
    @SerialName("array")
    data class Array(
        val values: List<RecordIdValue>,
    ) : RecordIdValue

    @Serializable
    @SerialName("object")
    data class Object(
        val values: Map<kotlin.String, RecordIdValue>,
    ) : RecordIdValue
}

private fun RecordIdKey.referenceString(): String =
    when (this) {
        is RecordIdKey.String -> if (value.startsWith(COMPOSITE_PREFIX)) "$COMPOSITE_PREFIX$value" else value
        else -> COMPOSITE_PREFIX + Json.encodeToString(RecordIdKey.serializer(), this)
    }

private fun String.recordIdKey(): RecordIdKey =
    when {
        startsWith(ESCAPED_COMPOSITE_PREFIX) -> RecordIdKey.String(removePrefix(COMPOSITE_PREFIX))
        startsWith(COMPOSITE_PREFIX) -> Json.decodeFromString(RecordIdKey.serializer(), removePrefix(COMPOSITE_PREFIX))
        else -> RecordIdKey.String(this)
    }

private val TABLE_PATTERN = Regex("[a-z][a-z0-9_]*")
private val UUID_PATTERN = Regex("[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}")
private const val COMPOSITE_PREFIX = "~"
private const val ESCAPED_COMPOSITE_PREFIX = "~~"
