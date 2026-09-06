@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.types.skir

import com.typewritermc.types.DataMapEntry
import com.typewritermc.types.DataValue
import okio.ByteString.Companion.toByteString
import java.math.BigInteger
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.toJavaInstant
import kotlin.time.toKotlinInstant
import skirout.editor.v1.type_catalog.ResolvedTypeRef as SkirResolvedTypeRef
import skirout.editor.v1.type_catalog.TypedMapEntry as SkirTypedMapEntry
import skirout.editor.v1.type_catalog.TypedRecordField as SkirTypedRecordField
import skirout.editor.v1.type_catalog.TypedValue as SkirTypedValue
import skirout.kernel.v1.duration.Duration as SkirDuration

/**
 * Converts portable value trees to and from Skir typed values. Recursive conversion preserves represented
 * structure and reports unsupported variants or numeric representations through [SkirConversionResult]. It does
 * not resolve a catalog or establish that a value satisfies a domain schema.
 */
object SkirDataValueCodec {
    fun encode(value: DataValue): SkirConversionResult<SkirTypedValue> = captureSkirConversion { encodeDataValue(value) }

    fun decode(value: SkirTypedValue): SkirConversionResult<DataValue> = captureSkirConversion { decodeDataValue(value) }
}

internal fun ConversionScope.encodeDataValue(value: DataValue): SkirTypedValue =
    when (value) {
        DataValue.Unit -> {
            SkirTypedValue.UNIT
        }

        is DataValue.Boolean -> {
            SkirTypedValue.BooleanWrapper(value.value)
        }

        is DataValue.Integer -> {
            encodeInteger(value.value)
        }

        is DataValue.Float -> {
            SkirTypedValue.FloatSixtyFourWrapper(value.value)
        }

        is DataValue.Decimal -> {
            SkirTypedValue.DecimalWrapper(value.value)
        }

        is DataValue.StringValue -> {
            SkirTypedValue.StringWrapper(value.value)
        }

        is DataValue.Bytes -> {
            SkirTypedValue.BytesWrapper(value.toByteArray().toByteString())
        }

        is DataValue.Timestamp -> {
            SkirTypedValue.TimestampWrapper(value.value.toJavaInstant())
        }

        is DataValue.Duration -> {
            if (value.value.isInfinite() || value.value.inWholeMilliseconds.milliseconds != value.value) {
                fail("Skir duration values require finite millisecond precision.")
            }
            SkirTypedValue.createDuration(duration = SkirDuration(milliseconds = value.value.inWholeMilliseconds))
        }

        is DataValue.ListValue -> {
            SkirTypedValue.ListWrapper(value.values.mapIndexed { index, item -> at("list item $index") { encodeDataValue(item) } })
        }

        is DataValue.MapValue -> {
            SkirTypedValue.createMap(
                entries =
                    value.entries.mapIndexed { index, entry ->
                        SkirTypedMapEntry(
                            key = at("map key $index") { encodeDataValue(entry.key) },
                            value = at("map value $index") { encodeDataValue(entry.value) },
                        )
                    },
            )
        }

        is DataValue.Record -> {
            SkirTypedValue.createRecord(
                fields =
                    value.fields.toSortedMap().map { (name, item) ->
                        SkirTypedRecordField(name = name, value = at(name) { encodeDataValue(item) })
                    },
            )
        }

        is DataValue.Polymorphic -> {
            val reference = SkirTypeCodec.encode(value.concreteType)
            val encodedReference =
                when (reference) {
                    is SkirConversionResult.Success -> reference.value
                    is SkirConversionResult.Failure -> fail(reference.diagnostics.joinToString())
                }
            SkirTypedValue.createNamed(
                tag = encodedReference,
                payload = at("payload") { encodeDataValue(value.value) },
            )
        }
    }

internal fun ConversionScope.decodeDataValue(value: SkirTypedValue): DataValue =
    when (value) {
        SkirTypedValue.UNIT -> {
            DataValue.Unit
        }

        is SkirTypedValue.BooleanWrapper -> {
            DataValue.Boolean(value.value)
        }

        is SkirTypedValue.StringWrapper -> {
            DataValue.StringValue(value.value)
        }

        is SkirTypedValue.BytesWrapper -> {
            DataValue.Bytes(value.value.toByteArray())
        }

        is SkirTypedValue.SignedEightWrapper -> {
            integerInRange(value.value.toLong(), Byte.MIN_VALUE.toLong(), Byte.MAX_VALUE.toLong())
        }

        is SkirTypedValue.SignedSixteenWrapper -> {
            integerInRange(value.value.toLong(), Short.MIN_VALUE.toLong(), Short.MAX_VALUE.toLong())
        }

        is SkirTypedValue.SignedThirtyTwoWrapper -> {
            DataValue.Integer(value.value.toBigInteger())
        }

        is SkirTypedValue.SignedSixtyFourWrapper -> {
            DataValue.Integer(value.value.toBigInteger())
        }

        is SkirTypedValue.UnsignedEightWrapper -> {
            integerInRange(value.value.toLong(), 0, UByte.MAX_VALUE.toLong())
        }

        is SkirTypedValue.UnsignedSixteenWrapper -> {
            integerInRange(value.value.toLong(), 0, UShort.MAX_VALUE.toLong())
        }

        is SkirTypedValue.UnsignedThirtyTwoWrapper -> {
            integerInRange(value.value, 0, UInt.MAX_VALUE.toLong())
        }

        is SkirTypedValue.UnsignedSixtyFourWrapper -> {
            val integer = value.value.toBigIntegerOrNull() ?: fail("Invalid unsigned 64 bit integer payload.")
            if (integer < BigInteger.ZERO || integer > UNSIGNED_64_MAX) fail("Unsigned 64 bit integer payload is outside its range.")
            DataValue.Integer(integer)
        }

        is SkirTypedValue.FloatThirtyTwoWrapper -> {
            finiteFloat(value.value.toDouble())
        }

        is SkirTypedValue.FloatSixtyFourWrapper -> {
            finiteFloat(value.value)
        }

        is SkirTypedValue.DecimalWrapper -> {
            runCatching { DataValue.Decimal(value.value) }.getOrElse { fail("Invalid decimal payload.") }
        }

        is SkirTypedValue.TimestampWrapper -> {
            DataValue.Timestamp(value.value.toKotlinInstant())
        }

        is SkirTypedValue.DurationWrapper -> {
            DataValue.Duration(value.value.duration.milliseconds.milliseconds)
        }

        is SkirTypedValue.ListWrapper -> {
            DataValue.ListValue(value.value.mapIndexed { index, item -> at("list item $index") { decodeDataValue(item) } })
        }

        is SkirTypedValue.MapWrapper -> {
            DataValue.MapValue(
                value.value.entries.mapIndexed { index, entry ->
                    DataMapEntry(
                        key = at("map key $index") { decodeDataValue(entry.key) },
                        value = at("map value $index") { decodeDataValue(entry.value) },
                    )
                },
            )
        }

        is SkirTypedValue.RecordWrapper -> {
            DataValue.Record(value.value.fields.associate { field -> field.name to at(field.name) { decodeDataValue(field.value) } })
        }

        is SkirTypedValue.NamedWrapper -> {
            val reference = SkirTypeCodec.decode(value.value.tag)
            val decodedReference =
                when (reference) {
                    is SkirConversionResult.Success -> reference.value
                    is SkirConversionResult.Failure -> fail(reference.diagnostics.joinToString())
                }
            DataValue.Polymorphic(decodedReference, at("payload") { decodeDataValue(value.value.payload) })
        }

        else -> {
            fail("Unknown Skir typed value.")
        }
    }

private fun ConversionScope.encodeInteger(value: BigInteger): SkirTypedValue =
    when {
        value in SIGNED_64_MIN..SIGNED_64_MAX -> SkirTypedValue.SignedSixtyFourWrapper(value.toLong())
        value in BigInteger.ZERO..UNSIGNED_64_MAX -> SkirTypedValue.UnsignedSixtyFourWrapper(value.toString())
        else -> fail("Integer value is outside the Skir 64 bit range.")
    }

private fun ConversionScope.integerInRange(
    value: Long,
    minimum: Long,
    maximum: Long,
): DataValue.Integer {
    if (value !in minimum..maximum) fail("Integer payload is outside its tagged width.")
    return DataValue.Integer(value.toBigInteger())
}

private fun ConversionScope.finiteFloat(value: Double): DataValue.Float {
    if (!value.isFinite()) fail("Float payload must be finite.")
    return DataValue.Float(value)
}

private val SIGNED_64_MIN = Long.MIN_VALUE.toBigInteger()
private val SIGNED_64_MAX = Long.MAX_VALUE.toBigInteger()
private val UNSIGNED_64_MAX = BigInteger.ONE.shiftLeft(64).subtract(BigInteger.ONE)
