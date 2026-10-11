@file:OptIn(kotlin.time.ExperimentalTime::class)

package com.typewritermc.types.skir

import com.typewritermc.authoring.ItemId
import com.typewritermc.types.DataValue
import com.typewritermc.types.EndpointId
import com.typewritermc.types.LinkTarget
import com.typewritermc.types.ListItem
import com.typewritermc.types.MapRow
import com.typewritermc.types.ResourceId
import com.typewritermc.types.requireCanonicalDecimal
import okio.ByteString.Companion.toByteString
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.toJavaInstant
import kotlin.time.toKotlinInstant
import skirout.editor.v1.type_catalog.DataValue as SkirDataValue
import skirout.editor.v1.type_catalog.EndpointId as SkirEndpointId
import skirout.editor.v1.type_catalog.FieldValue as SkirFieldValue
import skirout.editor.v1.type_catalog.ItemId as SkirItemId
import skirout.editor.v1.type_catalog.LinkTarget as SkirLinkTarget
import skirout.editor.v1.type_catalog.ListItem as SkirListItem
import skirout.editor.v1.type_catalog.MapRow as SkirMapRow
import skirout.editor.v1.type_catalog.ResourceId as SkirResourceId
import skirout.kernel.v1.duration.Duration as SkirDuration

object SkirDataValueCodec {
    fun encode(value: DataValue): SkirConversionResult<SkirDataValue> = captureSkirConversion { encodeDataValue(value) }

    fun decode(value: SkirDataValue): SkirConversionResult<DataValue> = captureSkirConversion { decodeDataValue(value) }
}

internal fun ConversionScope.encodeDataValue(value: DataValue): SkirDataValue =
    withinValueDepth {
        when (value) {
            DataValue.Unfilled -> {
                SkirDataValue.UNFILLED
            }

            DataValue.Null -> {
                SkirDataValue.NULL
            }

            DataValue.Unit -> {
                SkirDataValue.UNIT
            }

            is DataValue.Boolean -> {
                SkirDataValue.BooleanWrapper(value.value)
            }

            is DataValue.Integer -> {
                SkirDataValue.IntegerWrapper(value.value.toString())
            }

            is DataValue.Float -> {
                if (!value.value.isFinite()) fail("Float values must be finite.")
                SkirDataValue.FloatWrapper(value.value)
            }

            is DataValue.Decimal -> {
                runCatching { value.value.requireCanonicalDecimal("Decimal value") }
                    .getOrElse { fail("Decimal values must use canonical notation.") }
                SkirDataValue.DecimalWrapper(value.value)
            }

            is DataValue.StringValue -> {
                SkirDataValue.StringValueWrapper(value.value)
            }

            is DataValue.Bytes -> {
                SkirDataValue.BytesWrapper(value.toByteArray().toByteString())
            }

            is DataValue.Timestamp -> {
                SkirDataValue.TimestampWrapper(value.value.toJavaInstant())
            }

            is DataValue.Duration -> {
                if (value.value.isInfinite() || value.value.inWholeMilliseconds.milliseconds != value.value) {
                    fail("Duration values require finite millisecond precision.")
                }
                SkirDataValue.createDuration(value = SkirDuration(milliseconds = value.value.inWholeMilliseconds))
            }

            is DataValue.EnumCase -> {
                SkirDataValue.EnumCaseWrapper(value.key)
            }

            is DataValue.Record -> {
                SkirDataValue.createRecord(
                    fields =
                        value.fields.toSortedMap().map { (name, field) ->
                            SkirFieldValue(name = name, value = at(name) { encodeDataValue(field) })
                        },
                )
            }

            is DataValue.Named -> {
                SkirDataValue.createNamed(
                    actualType = encodeNamedTypeUse(value.actualType),
                    payload = at("payload") { encodeDataValue(value.payload) },
                )
            }

            is DataValue.ListValue -> {
                SkirDataValue.createListValue(items = value.items.mapIndexed { index, item -> at("item $index") { encode(item) } })
            }

            is DataValue.SetValue -> {
                SkirDataValue.createSetValue(items = value.items.mapIndexed { index, item -> at("item $index") { encode(item) } })
            }

            is DataValue.MapValue -> {
                SkirDataValue.createMapValue(rows = value.rows.mapIndexed { index, row -> at("row $index") { encode(row) } })
            }

            is DataValue.Link -> {
                SkirDataValue.createLink(
                    endpoint = SkirEndpointId(value = value.endpoint.value),
                    target =
                        SkirLinkTarget(
                            resource = SkirResourceId(value = value.target.resource.value),
                            opposite = value.target.opposite?.let(::encodeValuePath),
                        ),
                )
            }
        }
    }

internal fun ConversionScope.decodeDataValue(value: SkirDataValue): DataValue =
    withinValueDepth {
        when (value) {
            SkirDataValue.UNFILLED -> {
                DataValue.Unfilled
            }

            SkirDataValue.NULL -> {
                DataValue.Null
            }

            SkirDataValue.UNIT -> {
                DataValue.Unit
            }

            is SkirDataValue.BooleanWrapper -> {
                DataValue.Boolean(value.value)
            }

            is SkirDataValue.IntegerWrapper -> {
                DataValue.Integer(value.value.toBigIntegerOrNull() ?: fail("Integer payload is invalid."))
            }

            is SkirDataValue.FloatWrapper -> {
                if (!value.value.isFinite()) fail("Float payload must be finite.")
                DataValue.Float(value.value)
            }

            is SkirDataValue.DecimalWrapper -> {
                runCatching { value.value.requireCanonicalDecimal("Decimal payload") }
                    .getOrElse { fail("Decimal payload must use canonical notation.") }
                DataValue.Decimal(value.value)
            }

            is SkirDataValue.StringValueWrapper -> {
                DataValue.StringValue(value.value)
            }

            is SkirDataValue.BytesWrapper -> {
                DataValue.Bytes(value.value.toByteArray())
            }

            is SkirDataValue.TimestampWrapper -> {
                DataValue.Timestamp(value.value.toKotlinInstant())
            }

            is SkirDataValue.DurationWrapper -> {
                DataValue.Duration(value.value.value.milliseconds.milliseconds)
            }

            is SkirDataValue.EnumCaseWrapper -> {
                DataValue.EnumCase(value.value)
            }

            is SkirDataValue.RecordWrapper -> {
                DataValue.Record(decodeRecordFields(value.value.fields))
            }

            is SkirDataValue.NamedWrapper -> {
                DataValue.Named(
                    actualType = decodeNamedTypeUse(value.value.actualType),
                    payload = at("payload") { decodeDataValue(value.value.payload) },
                )
            }

            is SkirDataValue.ListValueWrapper -> {
                DataValue.ListValue(value.value.items.mapIndexed { index, item -> at("item $index") { decode(item) } })
            }

            is SkirDataValue.SetValueWrapper -> {
                DataValue.SetValue(value.value.items.mapIndexed { index, item -> at("item $index") { decode(item) } })
            }

            is SkirDataValue.MapValueWrapper -> {
                DataValue.MapValue(value.value.rows.mapIndexed { index, row -> at("row $index") { decode(row) } })
            }

            is SkirDataValue.LinkWrapper -> {
                DataValue.Link(
                    endpoint = EndpointId(value.value.endpoint.value),
                    target =
                        LinkTarget(
                            resource = ResourceId(value.value.target.resource.value),
                            opposite =
                                value.value.target.opposite
                                    ?.let(::decodeValuePath),
                        ),
                )
            }

            else -> {
                fail("Unknown Skir data value variant.")
            }
        }
    }

internal fun ConversionScope.decodeRecordFields(fields: List<SkirFieldValue>): Map<String, DataValue> {
    val decoded = linkedMapOf<String, DataValue>()
    fields.forEachIndexed { index, field ->
        at("field $index") {
            if (field.name in decoded) fail("Record field ${field.name} is duplicated.")
            decoded[field.name] = at(field.name) { decodeDataValue(field.value) }
        }
    }
    return decoded
}

private fun ConversionScope.encode(item: ListItem): SkirListItem =
    SkirListItem(id = SkirItemId(value = item.id.value), value = encodeDataValue(item.value))

private fun ConversionScope.decode(item: SkirListItem): ListItem = ListItem(id = ItemId(item.id.value), value = decodeDataValue(item.value))

private fun ConversionScope.encode(row: MapRow): SkirMapRow =
    SkirMapRow(
        id = SkirItemId(value = row.id.value),
        key = at("key") { encodeDataValue(row.key) },
        value = at("value") { encodeDataValue(row.value) },
    )

private fun ConversionScope.decode(row: SkirMapRow): MapRow =
    MapRow(
        id = ItemId(row.id.value),
        key = at("key") { decodeDataValue(row.key) },
        value = at("value") { decodeDataValue(row.value) },
    )
