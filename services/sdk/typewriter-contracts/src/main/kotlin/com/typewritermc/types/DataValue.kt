@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.types

import com.typewritermc.authoring.ItemId
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.math.BigInteger
import kotlin.time.Instant

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
    ) : DataValue

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
        val actualType: TypeUse.Named,
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
        val endpoint: EndpointId,
        val target: LinkTarget,
    ) : DataValue
}

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
