@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.types

import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Instant

/** Creates the portable representation of this Boolean value. */
fun Boolean.toDataValue(): DataValue.Boolean = DataValue.Boolean(this)

/** Creates the portable representation of this integer value. */
fun Byte.toDataValue(): DataValue.Integer = toLong().toDataValue()

/** Creates the portable representation of this integer value. */
fun Short.toDataValue(): DataValue.Integer = toLong().toDataValue()

/** Creates the portable representation of this integer value. */
fun Int.toDataValue(): DataValue.Integer = toLong().toDataValue()

/** Creates the portable representation of this integer value. */
fun Long.toDataValue(): DataValue.Integer = DataValue.Integer(BigInteger.valueOf(this))

/** Creates the portable representation of this unsigned integer value. */
fun UInt.toDataValue(): DataValue.Integer = DataValue.Integer(toString().toBigInteger())

/** Creates the portable representation of this unsigned integer value. */
fun ULong.toDataValue(): DataValue.Integer = DataValue.Integer(toString().toBigInteger())

/** Creates the portable representation of this arbitrary precision integer value. */
fun BigInteger.toDataValue(): DataValue.Integer = DataValue.Integer(this)

/** Creates the portable representation of this floating point value. */
fun Float.toDataValue(): DataValue.Float = toDouble().toDataValue()

/** Creates the portable representation of this floating point value. */
fun Double.toDataValue(): DataValue.Float = DataValue.Float(this)

/** Creates the portable representation of this string value. */
fun String.toDataValue(): DataValue.StringValue = DataValue.StringValue(this)

/** Creates the portable representation of these bytes. */
fun ByteArray.toDataValue(): DataValue.Bytes = DataValue.Bytes(this)

/** Creates the portable timestamp representation of this instant. */
fun Instant.toDataValue(): DataValue.Timestamp = DataValue.Timestamp(this)

/** Creates the portable duration representation of this duration. */
fun Duration.toDataValue(): DataValue.Duration = DataValue.Duration(this)

/** Creates a portable list from already converted values. */
fun Iterable<DataValue>.toDataValue(): DataValue.ListValue = DataValue.ListValue(toList())

/** Creates a portable record whose keys become field names. */
fun Map<String, DataValue>.toRecordValue(): DataValue.Record = DataValue.Record(this)

/** Creates a portable map while preserving entry order. */
fun Iterable<Pair<DataValue, DataValue>>.toMapValue(): DataValue.MapValue =
    DataValue.MapValue(map { (key, value) -> DataMapEntry(key, value) })

/** Returns this value as the requested portable variant, or null when it has another variant. */
inline fun <reified Value : DataValue> DataValue.valueOrNull(): Value? = this as? Value

/** Returns this value as the requested portable variant and rejects a mismatched variant. */
inline fun <reified Value : DataValue> DataValue.requireValue(): Value =
    requireNotNull(valueOrNull<Value>()) {
        "Expected ${Value::class.simpleName}, but found ${this::class.simpleName}."
    }

val DataValue.booleanOrNull: Boolean?
    get() = (this as? DataValue.Boolean)?.value

val DataValue.integerOrNull: BigInteger?
    get() = (this as? DataValue.Integer)?.value

val DataValue.floatOrNull: Double?
    get() = (this as? DataValue.Float)?.value

val DataValue.decimalOrNull: String?
    get() = (this as? DataValue.Decimal)?.value

val DataValue.stringOrNull: String?
    get() = (this as? DataValue.StringValue)?.value

val DataValue.bytesOrNull: ByteArray?
    get() = (this as? DataValue.Bytes)?.toByteArray()

val DataValue.instantOrNull: Instant?
    get() = (this as? DataValue.Timestamp)?.value

val DataValue.durationOrNull: Duration?
    get() = (this as? DataValue.Duration)?.value

val DataValue.elementsOrNull: List<DataValue>?
    get() = (this as? DataValue.ListValue)?.values

val DataValue.entriesOrNull: List<DataMapEntry>?
    get() = (this as? DataValue.MapValue)?.entries

val DataValue.fieldsOrNull: Map<String, DataValue>?
    get() = (this as? DataValue.Record)?.fields

/** Returns a record field when present. */
operator fun DataValue.Record.get(name: String): DataValue? = fields[name]

/** Returns a required record field and reports its name when absent. */
fun DataValue.Record.requireField(name: String): DataValue = requireNotNull(fields[name]) { "Record does not contain field '$name'." }

/** Produces the nominal Some representation for this value. */
fun DataValue.toSomeValue(valueType: TypeExpression): DataValue.Polymorphic =
    DataValue.Polymorphic(
        concreteType = StandardTypes.someOf(valueType),
        value = DataValue.Record(mapOf("value" to this)),
    )

/** Produces the nominal None representation for the supplied value type. */
fun noneValue(valueType: TypeExpression): DataValue.Polymorphic =
    DataValue.Polymorphic(
        concreteType = StandardTypes.noneOf(valueType),
        value = DataValue.Unit,
    )

/** Converts Kotlin nullability into the canonical Typewriter option representation. */
fun DataValue?.toOptionValue(valueType: TypeExpression): DataValue.Polymorphic = this?.toSomeValue(valueType) ?: noneValue(valueType)

/** Extracts a canonical option value, returning null for None. */
fun DataValue.unwrapOption(): DataValue? {
    val polymorphic = requireValue<DataValue.Polymorphic>()
    require(polymorphic.concreteType.arguments.size == 1) { "Option values must have one type argument." }

    return when (polymorphic.concreteType.id) {
        TypeId.Some -> {
            polymorphic.value.requireValue<DataValue.Record>().requireField("value")
        }

        TypeId.None -> {
            polymorphic.value.requireValue<DataValue.Unit>()
            null
        }

        else -> {
            throw IllegalArgumentException("Expected Some or None, but found ${polymorphic.concreteType.id}.")
        }
    }
}

/** Wraps this expression in the canonical Option type. */
val TypeExpression.optional: TypeExpression.Named
    get() = TypeExpression.Named(StandardTypes.optionOf(this))

/** Uses this nominal reference as a type expression. */
val ResolvedTypeRef.expression: TypeExpression.Named
    get() = TypeExpression.Named(this)
