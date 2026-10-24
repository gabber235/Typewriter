@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.types

import build.skir.KeyedList
import okio.ByteString.Companion.toByteString
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.EndpointId
import skirout.editor.v1.type_catalog.FieldValue
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.NamedTypeUse
import skirout.editor.v1.type_catalog.RecordPayload
import java.math.BigInteger
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Instant
import kotlin.time.toJavaInstant
import kotlin.time.toKotlinInstant
import skirout.kernel.v1.duration.Duration as SkirDuration

/*
 * Portable authored content is the generated Skir DataValue. UNFILLED preserves an unfinished editor value and differs
 * from an explicit NULL. A named value carries the actual nominal type alongside its representation payload.
 * Collection items and map rows retain ItemId identities so paths survive reordering. Constructing a value does not
 * establish schema validity or completeness; admission checks those against a catalog before native decoding or
 * publication.
 *
 * Record fields are kept in name order, so two records with the same fields are equal and encode to the same bytes.
 * The factories below establish that order, and requirePortable restores it for values that enter from outside.
 */

fun DataValue.Companion.integer(value: BigInteger): DataValue.IntegerWrapper = DataValue.IntegerWrapper(value.toString())

fun DataValue.Companion.integer(value: Long): DataValue.IntegerWrapper = DataValue.IntegerWrapper(value.toString())

fun DataValue.Companion.bytes(value: ByteArray): DataValue.BytesWrapper = DataValue.BytesWrapper(value.toByteString())

fun DataValue.Companion.timestamp(value: Instant): DataValue.TimestampWrapper = DataValue.TimestampWrapper(value.toJavaInstant())

/** Requires finite, exactly representable whole milliseconds, the range every runtime can hold. */
fun DataValue.Companion.duration(value: Duration): DataValue.DurationWrapper {
    require(value.isPortableDuration()) { "Duration values require finite, exactly representable whole milliseconds." }
    return DataValue.createDuration(value = SkirDuration(milliseconds = value.inWholeMilliseconds))
}

fun DataValue.Companion.record(fields: Map<String, DataValue>): DataValue.RecordWrapper = DataValue.RecordWrapper(recordPayload(fields))

fun DataValue.Companion.record(vararg fields: Pair<String, DataValue>): DataValue.RecordWrapper = record(fields.toMap())

fun DataValue.Companion.named(
    actualType: NamedTypeUse,
    payload: DataValue,
): DataValue.NamedWrapper = DataValue.createNamed(actualType = actualType, payload = payload)

fun DataValue.Companion.listValue(items: List<ListItem>): DataValue.ListValueWrapper = DataValue.createListValue(items = items)

fun DataValue.Companion.setValue(items: List<ListItem>): DataValue.SetValueWrapper = DataValue.createSetValue(items = items)

fun DataValue.Companion.mapValue(rows: List<MapRow>): DataValue.MapValueWrapper = DataValue.createMapValue(rows = rows)

/** Builds a record payload with its fields in name order. */
private fun recordPayload(fields: Map<String, DataValue>): RecordPayload =
    RecordPayload(fields = fields.entries.sortedBy { it.key }.map { (name, value) -> FieldValue(name = name, value = value) })

/** Returns the value of the field named [name], or null when the record has no such field. */
fun RecordPayload.field(name: String): DataValue? = fields.findByKey(name)?.value

/** The fields by name, in name order. */
val RecordPayload.fieldMap: Map<String, DataValue> get() = fields.associateTo(LinkedHashMap()) { it.name to it.value }

/** Returns this record with [name] set to [value], keeping the fields in name order. */
fun RecordPayload.with(
    name: String,
    value: DataValue,
): RecordPayload {
    val index = fields.binarySearch { it.name.compareTo(name) }
    val next = fields.toMutableList()
    if (index >= 0) next[index] = FieldValue(name = name, value = value) else next.add(-index - 1, FieldValue(name = name, value = value))
    return RecordPayload(fields = next)
}

val DataValue.NamedWrapper.actualType: NamedTypeUse get() = value.actualType

val DataValue.NamedWrapper.payload: DataValue get() = value.payload

val DataValue.RecordWrapper.fields: KeyedList<FieldValue, String> get() = value.fields

fun DataValue.RecordWrapper.field(name: String): DataValue? = value.field(name)

val DataValue.ListValueWrapper.items: List<ListItem> get() = value.items

val DataValue.SetValueWrapper.items: List<ListItem> get() = value.items

val DataValue.MapValueWrapper.rows: List<MapRow> get() = value.rows

val DataValue.LinkWrapper.endpoint: EndpointId get() = value.endpoint

val DataValue.IntegerWrapper.bigInteger: BigInteger get() = value.toBigInteger()

val DataValue.DurationWrapper.duration: Duration get() = value.value.milliseconds.milliseconds

val DataValue.TimestampWrapper.instant: Instant get() = value.toKotlinInstant()

/** Returns the structural value beneath every nominal wrapper. */
tailrec fun DataValue.unwrapNamed(): DataValue = if (this is DataValue.NamedWrapper) value.payload.unwrapNamed() else this

internal fun String.requireCanonicalDecimal(label: String) {
    require(CANONICAL_DECIMAL.matches(this)) { "$label must use canonical decimal syntax." }
}

internal fun String.isCanonicalDecimal(): Boolean = CANONICAL_DECIMAL.matches(this)

private val CANONICAL_DECIMAL = Regex("-?(0|[1-9][0-9]*)(\\.[0-9]+)?")
