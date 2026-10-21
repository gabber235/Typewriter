@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.types

import com.typewritermc.authoring.ItemId
import com.typewritermc.types.skir.EndpointIdSerializer
import com.typewritermc.types.skir.NamedTypeUseSerializer
import kotlinx.serialization.KSerializer
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.descriptors.PrimitiveKind
import kotlinx.serialization.descriptors.PrimitiveSerialDescriptor
import kotlinx.serialization.descriptors.SerialDescriptor
import kotlinx.serialization.encoding.Decoder
import kotlinx.serialization.encoding.Encoder
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.NamedTypeUse
import java.math.BigInteger
import kotlin.time.Instant

/**
 * Portable authored content shared by schema checking, editing, expressions, and transport codecs.
 *
 * [Unfilled] preserves an unfinished editor value and differs from an explicit [Null]. [Named] carries the actual
 * nominal type alongside its representation payload. Collection items and map rows retain [ItemId] identities so
 * paths survive reordering. Constructing a value does not establish schema validity or completeness; admission
 * checks those properties against a catalog before native decoding or publication.
 */
@Serializable
sealed interface DataValue {
    @Serializable
    @SerialName("unfilled")
    data object Unfilled : DataValue

    @Serializable
    @SerialName("null")
    data object Null : DataValue

    @Serializable
    @SerialName("unit")
    data object Unit : DataValue

    @Serializable
    @SerialName("boolean")
    data class Boolean(
        val value: kotlin.Boolean,
    ) : DataValue

    @Serializable
    @SerialName("integer")
    data class Integer(
        @Serializable(with = BigIntegerAsStringSerializer::class)
        val value: BigInteger,
    ) : DataValue

    @Serializable
    @SerialName("float")
    data class Float(
        val value: Double,
    ) : DataValue

    @Serializable
    @SerialName("decimal")
    data class Decimal(
        val value: String,
    ) : DataValue

    @Serializable
    @SerialName("string")
    data class StringValue(
        val value: String,
    ) : DataValue

    @Serializable
    @SerialName("bytes")
    data class Bytes(
        val value: List<Byte>,
    ) : DataValue {
        constructor(value: ByteArray) : this(value.toList())

        fun toByteArray(): ByteArray = value.toByteArray()
    }

    @Serializable
    @SerialName("timestamp")
    data class Timestamp(
        val value: Instant,
    ) : DataValue

    @Serializable
    @SerialName("duration")
    data class Duration(
        val value: kotlin.time.Duration,
    ) : DataValue {
        init {
            require(value.isPortableDuration()) { "Duration values require finite, exactly representable whole milliseconds." }
        }
    }

    @Serializable
    @SerialName("enum")
    data class EnumCase(
        val key: String,
    ) : DataValue

    @Serializable
    @SerialName("record")
    data class Record(
        val fields: Map<String, DataValue>,
    ) : DataValue

    @Serializable
    @SerialName("named")
    data class Named(
        @Serializable(with = NamedTypeUseSerializer::class)
        val actualType: NamedTypeUse,
        val payload: DataValue,
    ) : DataValue

    @Serializable
    @SerialName("list")
    data class ListValue(
        val items: List<ListItem>,
    ) : DataValue

    @Serializable
    @SerialName("set")
    data class SetValue(
        val items: List<ListItem>,
    ) : DataValue

    @Serializable
    @SerialName("map")
    data class MapValue(
        val rows: List<MapRow>,
    ) : DataValue

    @Serializable
    @SerialName("link")
    data class Link(
        @Serializable(with = EndpointIdSerializer::class)
        val endpoint: EndpointId,
        val target: LinkTarget,
    ) : DataValue
}

/** Returns the structural value beneath every nominal wrapper. */
tailrec fun DataValue.unwrapNamed(): DataValue = if (this is DataValue.Named) payload.unwrapNamed() else this

@Serializable
data class ListItem(
    val id: ItemId,
    val value: DataValue,
)

@Serializable
data class MapRow(
    val id: ItemId,
    val key: DataValue,
    val value: DataValue,
)

/**
 * Serializes arbitrary precision integers as decimal strings to avoid numeric width loss.
 *
 * Malformed decimal input fails during conversion to BigInteger.
 */
object BigIntegerAsStringSerializer : KSerializer<BigInteger> {
    override val descriptor: SerialDescriptor = PrimitiveSerialDescriptor("BigInteger", PrimitiveKind.STRING)

    override fun serialize(
        encoder: Encoder,
        value: BigInteger,
    ) {
        encoder.encodeString(value.toString())
    }

    override fun deserialize(decoder: Decoder): BigInteger = decoder.decodeString().toBigInteger()
}

internal fun String.requireCanonicalDecimal(label: String) {
    require(CANONICAL_DECIMAL.matches(this)) { "$label must use canonical decimal syntax." }
}

private val CANONICAL_DECIMAL = Regex("-?(0|[1-9][0-9]*)(\\.[0-9]+)?")
