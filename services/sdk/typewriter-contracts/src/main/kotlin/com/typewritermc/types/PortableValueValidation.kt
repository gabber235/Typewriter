package com.typewritermc.types

import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.FieldValue
import skirout.editor.v1.type_catalog.ItemId
import skirout.editor.v1.type_catalog.LinkTarget
import skirout.editor.v1.type_catalog.ListItem
import skirout.editor.v1.type_catalog.MapRow
import skirout.editor.v1.type_catalog.PathSegment
import skirout.editor.v1.type_catalog.RecordPayload
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.editor.v1.type_catalog.ValuePath
import skirout.kernel.v1.resource_id.ResourceId

/** The deepest nesting of authored values, counting each nominal wrapper, record field and collection entry. */
const val MAX_VALUE_DEPTH = 512

/*
 * Checks the wire invariants of authored values where they enter the runtime: from the wire, from storage and from the
 * SDK boundary. Generated Skir constructors cannot enforce them, so code below these boundaries relies on values that
 * passed this check. Each check fails with an IllegalArgumentException naming the rule.
 */

/**
 * Checks the nesting depth, finite floats, integer, decimal and duration payloads, unique record fields, non blank item
 * and resource ids, nominal types, link endpoints and paths, and rejects unknown variants.
 *
 * Returns the canonical form of the value: record fields in name order and integers in canonical decimal notation, so
 * equal content compares and encodes equally whatever order or notation the sender used. A value that is already
 * canonical is returned as is.
 */
fun DataValue.requirePortable(): DataValue = portable(depth = 0)

/** The canonical form of the value, or null when it is not portable. */
fun DataValue.portableOrNull(): DataValue? =
    try {
        requirePortable()
    } catch (_: IllegalArgumentException) {
        null
    }

/** This path when it is valid, or null. */
fun ValuePath.validOrNull(): ValuePath? =
    try {
        requireValid()
    } catch (_: IllegalArgumentException) {
        null
    }

fun ItemId.requireValid(): ItemId = apply { require(value.isNotBlank()) { "Item ids must not be blank." } }

fun ValuePath.requireValid(): ValuePath =
    apply {
        segments.forEach { segment ->
            when (segment) {
                is PathSegment.FieldWrapper -> Unit
                is PathSegment.ItemWrapper -> segment.value.id.requireValid()
                PathSegment.MAP_KEY, PathSegment.MAP_VALUE -> Unit
                else -> throw IllegalArgumentException("Unknown path segment.")
            }
        }
    }

private fun DataValue.portable(depth: Int): DataValue {
    require(depth <= MAX_VALUE_DEPTH) { "Authored value exceeds the supported nesting depth." }
    return when (this) {
        DataValue.UNFILLED, DataValue.NULL, DataValue.UNIT,
        is DataValue.BooleanWrapper, is DataValue.StringValueWrapper, is DataValue.BytesWrapper,
        is DataValue.TimestampWrapper, is DataValue.EnumCaseWrapper,
        -> {
            this
        }

        is DataValue.IntegerWrapper -> {
            val canonical = requireNotNull(value.toBigIntegerOrNull()) { "Integer payload is invalid." }.toString()
            if (canonical == value) this else DataValue.IntegerWrapper(canonical)
        }

        is DataValue.FloatWrapper -> {
            apply { require(value.isFinite()) { "Float payload must be finite." } }
        }

        is DataValue.DecimalWrapper -> {
            apply { value.requireCanonicalDecimal("Decimal payload") }
        }

        is DataValue.DurationWrapper -> {
            apply {
                require(value.value.milliseconds.isPortableDurationMilliseconds()) {
                    "Duration millisecond count exceeds the finite portable range."
                }
            }
        }

        is DataValue.RecordWrapper -> {
            val payload = value.portable(depth)
            if (payload === value) this else DataValue.RecordWrapper(payload)
        }

        is DataValue.NamedWrapper -> {
            value.actualType.requireValid()
            val payload = value.payload.portable(depth + 1)
            if (payload === value.payload) this else DataValue.named(value.actualType, payload)
        }

        is DataValue.ListValueWrapper -> {
            val items = value.items.portable(depth)
            if (items === value.items) this else DataValue.listValue(items)
        }

        is DataValue.SetValueWrapper -> {
            val items = value.items.portable(depth)
            if (items === value.items) this else DataValue.setValue(items)
        }

        is DataValue.MapValueWrapper -> {
            val rows = value.rows.portableRows(depth)
            if (rows === value.rows) this else DataValue.mapValue(rows)
        }

        is DataValue.LinkWrapper -> {
            apply {
                value.endpoint.requireValid()
                value.target.requireValid()
            }
        }

        else -> {
            throw IllegalArgumentException("Unknown value variant.")
        }
    }
}

private fun RecordPayload.portable(depth: Int): RecordPayload {
    var changed = false
    val checked =
        fields.map { field ->
            val value = field.value.portable(depth + 1)
            if (value === field.value) {
                field
            } else {
                changed = true
                FieldValue(name = field.name, value = value)
            }
        }
    val ordered = (1 until fields.size).all { index -> fields[index - 1].name < fields[index].name }
    if (ordered && !changed) return this
    val sorted = if (ordered) checked else checked.sortedBy { it.name }
    sorted.zipWithNext { previous, next -> require(previous.name != next.name) { "Record field ${next.name} is duplicated." } }
    return RecordPayload(fields = sorted)
}

private fun List<ListItem>.portable(depth: Int): List<ListItem> {
    var changed = false
    val checked =
        map { item ->
            item.id.requireValid()
            val value = item.value.portable(depth + 1)
            if (value === item.value) {
                item
            } else {
                changed = true
                ListItem(id = item.id, value = value)
            }
        }
    return if (changed) checked else this
}

private fun List<MapRow>.portableRows(depth: Int): List<MapRow> {
    var changed = false
    val checked =
        map { row ->
            row.id.requireValid()
            val key = row.key.portable(depth + 1)
            val value = row.value.portable(depth + 1)
            if (key === row.key && value === row.value) {
                row
            } else {
                changed = true
                MapRow(id = row.id, key = key, value = value)
            }
        }
    return if (changed) checked else this
}

fun ResourceId.requireValid(): ResourceId = apply { require(value.isNotBlank()) { "Resource ids must not be blank." } }

fun ValueLocation.requireValid(): ValueLocation =
    apply {
        resource.requireValid()
        path.requireValid()
    }

fun LinkTarget.requireValid(): LinkTarget =
    apply {
        resource.requireValid()
        opposite?.requireValid()
    }
