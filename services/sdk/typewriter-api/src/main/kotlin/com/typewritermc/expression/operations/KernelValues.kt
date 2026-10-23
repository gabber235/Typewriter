@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.expression.operations

import com.typewritermc.authoring.Availability
import com.typewritermc.types.ResourceIdDefinition
import com.typewritermc.types.bigInteger
import com.typewritermc.types.duration
import com.typewritermc.types.instant
import com.typewritermc.types.integer
import com.typewritermc.types.listValue
import com.typewritermc.types.mapValue
import com.typewritermc.types.named
import com.typewritermc.types.record
import com.typewritermc.types.setValue
import com.typewritermc.types.timestamp
import com.typewritermc.types.unwrapNamed
import okio.ByteString
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkValue
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.kernel.v1.resource_id.ResourceId
import java.math.BigDecimal
import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Instant

/*
 * Conversions between DataValue and kernel types, used by the generated rule kernel dispatch. Decoders unwrap named
 * values and raise ill_typed_argument for a value of the wrong kind: checked programs never reach that, so it marks a
 * tree that skipped checking. Encoders produce structural values; a named result is built by its generated encoder.
 */

internal fun KernelArgument.value(): DataValue = (this as? KernelArgument.Value)?.value ?: throw illTyped("Expected an evaluated argument.")

internal fun <T> KernelArgument.located(decode: (DataValue) -> T): Located<T> {
    val argument = this as? KernelArgument.Value ?: throw illTyped("Expected an evaluated argument.")
    return Located(decode(argument.value), argument.location)
}

internal fun <T> KernelArgument.each(decode: (DataValue) -> T): List<T> =
    ((this as? KernelArgument.Each) ?: throw illTyped("Expected an each lambda.")).results.map(decode)

internal fun KernelArgument.step(): PortableStep {
    val lambda = lambda()
    return PortableStep { accumulator, item ->
        lambda.invoke(listOf(KernelArgument.LocalInput(accumulator), KernelArgument.LocalInput(item.value, item.id)))
    }
}

internal fun KernelArgument.comparator(): PortableComparator {
    val lambda = lambda()
    return PortableComparator { left, right ->
        lambda
            .invoke(listOf(KernelArgument.LocalInput(left.value, left.id), KernelArgument.LocalInput(right.value, right.id)))
            .asInt32()
    }
}

internal fun KernelArgument.apply(): PortableApply {
    val lambda = lambda()
    return PortableApply { value -> lambda.invoke(listOf(KernelArgument.LocalInput(value))) }
}

private fun KernelArgument.lambda(): KernelArgument.Lambda = this as? KernelArgument.Lambda ?: throw illTyped("Expected a lambda.")

internal fun DataValue.asText(): String = (unwrapNamed() as? DataValue.StringValueWrapper)?.value ?: throw illTyped("Expected text.")

internal fun DataValue.asBoolean(): Boolean = (unwrapNamed() as? DataValue.BooleanWrapper)?.value ?: throw illTyped("Expected a boolean.")

internal fun DataValue.asInteger(): BigInteger =
    (unwrapNamed() as? DataValue.IntegerWrapper)?.bigInteger ?: throw illTyped("Expected an integer.")

/** An integer argument of an int32 parameter; values outside 32 bits raise integer_out_of_range. */
internal fun DataValue.asInt32(): Int {
    val value = asInteger()
    if (value.bitLength() > 31) throw OperationFailure(EvaluatorFailure.IntegerOutOfRange, "The integer $value is outside 32 bits.")
    return value.toInt()
}

internal fun DataValue.asFloat(): Double = (unwrapNamed() as? DataValue.FloatWrapper)?.value ?: throw illTyped("Expected a float.")

internal fun DataValue.asDecimal(): BigDecimal =
    (unwrapNamed() as? DataValue.DecimalWrapper)?.value?.toBigDecimal() ?: throw illTyped("Expected a decimal.")

internal fun DataValue.asBytes(): ByteString = (unwrapNamed() as? DataValue.BytesWrapper)?.value ?: throw illTyped("Expected bytes.")

internal fun DataValue.asDuration(): Duration =
    (unwrapNamed() as? DataValue.DurationWrapper)?.duration ?: throw illTyped("Expected a duration.")

internal fun DataValue.asTimestamp(): Instant =
    (unwrapNamed() as? DataValue.TimestampWrapper)?.instant ?: throw illTyped("Expected a timestamp.")

/** A resource identity: the named ResourceId value over its text payload. */
internal fun DataValue.asResourceId(): ResourceId = ResourceId(value = asText())

internal fun DataValue.asLink(): LinkValue = (unwrapNamed() as? DataValue.LinkWrapper)?.value ?: throw illTyped("Expected a link.")

internal fun DataValue.asNumber(): PortableNumber =
    when (val value = unwrapNamed()) {
        is DataValue.IntegerWrapper -> PortableNumber.Integer(value.bigInteger)
        is DataValue.FloatWrapper -> PortableNumber.Float(value.value)
        is DataValue.DecimalWrapper -> PortableNumber.Decimal(value.value.toBigDecimal())
        else -> throw illTyped("Expected a number.")
    }

/** The items of a list or set, or the entries of a map as records of key and value with the row identities. */
internal fun DataValue.asItems(): List<ListItem> =
    when (val value = unwrapNamed()) {
        is DataValue.ListValueWrapper -> value.value.items
        is DataValue.SetValueWrapper -> value.value.items
        is DataValue.MapValueWrapper -> value.value.rows.map { row -> ListItem(id = row.id, value = entryValue(row.key, row.value)) }
        else -> throw illTyped("Expected a collection.")
    }

internal fun DataValue.asRows(): List<MapRow> =
    (unwrapNamed() as? DataValue.MapValueWrapper)?.value?.rows ?: throw illTyped("Expected a map.")

internal fun <T> DataValue.asNullable(decode: (DataValue) -> T): T? = if (unwrapNamed() == DataValue.NULL) null else decode(this)

internal fun textValue(value: String): DataValue = DataValue.StringValueWrapper(value)

internal fun booleanValue(value: Boolean): DataValue = DataValue.BooleanWrapper(value)

internal fun integerValue(value: BigInteger): DataValue = DataValue.integer(value)

internal fun int32Value(value: Int): DataValue = DataValue.integer(value.toLong())

/** A finite float; a kernel that can produce a non finite value raises non_finite_number before encoding. */
internal fun floatValue(value: Double): DataValue {
    check(value.isFinite()) { "Kernels raise non_finite_number instead of returning $value." }
    return DataValue.FloatWrapper(value)
}

/** A decimal in canonical form: plain notation without trailing fraction zeros. */
internal fun decimalValue(value: BigDecimal): DataValue = DataValue.DecimalWrapper(value.canonicalDecimal())

internal fun bytesValue(value: ByteString): DataValue = DataValue.BytesWrapper(value)

internal fun durationValue(value: Duration): DataValue = DataValue.duration(value)

internal fun timestampValue(value: Instant): DataValue = DataValue.timestamp(value)

internal fun resourceIdValue(value: ResourceId): DataValue =
    DataValue.named(ResourceIdDefinition.use, DataValue.StringValueWrapper(value.value))

internal fun linkValue(value: LinkValue): DataValue = DataValue.LinkWrapper(value)

internal fun numberValue(value: PortableNumber): DataValue =
    when (value) {
        is PortableNumber.Integer -> integerValue(value.value)
        is PortableNumber.Float -> floatValue(value.value)
        is PortableNumber.Decimal -> decimalValue(value.value)
    }

internal fun <T> nullableValue(
    value: T?,
    encode: (T) -> DataValue,
): DataValue = if (value == null) DataValue.NULL else encode(value)

/** A maybe result as the call rule returns it: missing data stays missing at the kernel's locations. */
internal fun <T> PortableMaybe<T>.toAvailability(encode: (T) -> DataValue): Availability<DataValue> =
    when (this) {
        is PortableMaybe.Value -> Availability.Available(encode(value))
        is PortableMaybe.Missing -> Availability.Unavailable(locations)
    }

internal fun itemsList(items: List<ListItem>): DataValue = DataValue.listValue(items)

internal fun itemsSet(items: List<ListItem>): DataValue = DataValue.setValue(items)

internal fun rowsMap(rows: List<MapRow>): DataValue = DataValue.mapValue(rows)

/** A list of computed values whose items are named by position: 0, 1, 2, ... */
internal fun positionalList(values: List<DataValue>): DataValue = itemsList(positionalItems(values))

/** Items named by position: 0, 1, 2, ... */
fun positionalItems(values: List<DataValue>): List<ListItem> =
    values.mapIndexed { index, value -> ListItem(id = ItemId(value = index.toString()), value = value) }

/** A map entry as items and lambdas see it: a record of key and value. */
fun entryValue(
    key: DataValue,
    value: DataValue,
): DataValue = DataValue.record("key" to key, "value" to value)

/** The identity of an inner item below an outer item, unambiguous for any two identities. */
fun nestedItemId(
    outer: ItemId,
    inner: ItemId,
): ItemId = ItemId(value = "${outer.value.length}:${outer.value}${inner.value.length}:${inner.value}")

/** The canonical decimal text: plain notation without trailing fraction zeros. */
fun BigDecimal.canonicalDecimal(): String =
    stripTrailingZeros().let { if (it.scale() < 0) it.setScale(0) else it }.toPlainString().let { if (it == "-0") "0" else it }

/** The failure for a value of the wrong kind: checked programs never raise it, so it marks a tree that skipped checking. */
internal fun illTyped(message: String) = OperationFailure(EvaluatorFailure.IllTypedArgument, message)

/** The Unicode code points of this text; portable text indexes and lengths count them. */
internal fun String.codePointArray(): IntArray = codePoints().toArray()

/** The text of the code points from [start] up to, not including, [end]. */
internal fun IntArray.codePointText(
    start: Int = 0,
    end: Int = size,
): String = String(this, start, end - start)

/** Whether an unfilled entry occurs anywhere inside, through nominal wrappers, records, lists, sets and maps. */
internal fun DataValue.containsUnfilled(): Boolean =
    when (this) {
        DataValue.UNFILLED -> true
        is DataValue.NamedWrapper -> value.payload.containsUnfilled()
        is DataValue.RecordWrapper -> value.fields.any { it.value.containsUnfilled() }
        is DataValue.ListValueWrapper -> value.items.any { it.value.containsUnfilled() }
        is DataValue.SetValueWrapper -> value.items.any { it.value.containsUnfilled() }
        is DataValue.MapValueWrapper -> value.rows.any { it.key.containsUnfilled() || it.value.containsUnfilled() }
        else -> false
    }
