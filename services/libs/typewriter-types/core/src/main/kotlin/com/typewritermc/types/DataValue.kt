@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.types

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Instant

/** Portable typed value representation used by manifests, Realm persistence, and Skir transport. */
@Serializable
sealed interface DataValue {
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
    ) : DataValue {
        init {
            require(value.isFinite()) { "Float data values must be finite." }
        }
    }

    @Serializable
    @SerialName("decimal")
    data class Decimal(
        val value: String,
    ) : DataValue {
        init {
            value.requireCanonicalDecimal("Decimal value")
        }
    }

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
    @SerialName("list")
    data class ListValue(
        val values: List<DataValue>,
    ) : DataValue

    @Serializable
    @SerialName("map")
    data class MapValue(
        val entries: List<DataMapEntry>,
    ) : DataValue

    @Serializable
    @SerialName("record")
    data class Record(
        val fields: Map<String, DataValue>,
    ) : DataValue {
        init {
            require(fields.keys.none(String::isBlank)) { "Record value field names must not be blank." }
        }
    }

    @Serializable
    @SerialName("polymorphic")
    data class Polymorphic(
        val concreteType: ResolvedTypeRef,
        val value: DataValue,
    ) : DataValue
}

@Serializable
data class DataMapEntry(
    val key: DataValue,
    val value: DataValue,
)
