package com.typewritermc.types.skir

import com.typewritermc.types.RecordIdKey
import com.typewritermc.types.RecordIdValue
import com.typewritermc.types.ResourceId
import skirout.kernel.v1.record_id.ObjectRecordIdKey
import skirout.kernel.v1.record_id.ObjectRecordIdValue
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey as SkirRecordIdKey
import skirout.kernel.v1.record_id.RecordIdValue as SkirRecordIdValue

internal fun ResourceId.toSkirRecordId(): RecordId = RecordId(table = table, key = key.toSkirKey())

internal fun RecordId.toResourceId(): ResourceId = ResourceId(table, key.toResourceKey())

private fun SkirRecordIdKey.toResourceKey(): RecordIdKey =
    when (this) {
        is SkirRecordIdKey.NumberWrapper -> RecordIdKey.Number(value)
        is SkirRecordIdKey.StringWrapper -> RecordIdKey.String(value)
        is SkirRecordIdKey.UuidWrapper -> RecordIdKey.Uuid(value)
        is SkirRecordIdKey.ArrayWrapper -> RecordIdKey.Array(value.map(SkirRecordIdValue::toResourceValue))
        is SkirRecordIdKey.ObjectWrapper -> RecordIdKey.Object(value.associate { it.key to it.value.toResourceValue() })
        is SkirRecordIdKey.Unknown -> error("Unknown record id key")
    }

private fun SkirRecordIdValue.toResourceValue(): RecordIdValue =
    when (this) {
        SkirRecordIdValue.NULL -> RecordIdValue.Null
        is SkirRecordIdValue.BooleanWrapper -> RecordIdValue.Boolean(value)
        is SkirRecordIdValue.NumberWrapper -> RecordIdValue.Number(value)
        is SkirRecordIdValue.FloatWrapper -> RecordIdValue.Float(value)
        is SkirRecordIdValue.StringWrapper -> RecordIdValue.String(value)
        is SkirRecordIdValue.ArrayWrapper -> RecordIdValue.Array(value.map(SkirRecordIdValue::toResourceValue))
        is SkirRecordIdValue.ObjectWrapper -> RecordIdValue.Object(value.associate { it.key to it.value.toResourceValue() })
        is SkirRecordIdValue.Unknown -> error("Unknown record id value")
    }

private fun RecordIdKey.toSkirKey(): SkirRecordIdKey =
    when (this) {
        is RecordIdKey.Number -> {
            SkirRecordIdKey.NumberWrapper(value)
        }

        is RecordIdKey.String -> {
            SkirRecordIdKey.StringWrapper(value)
        }

        is RecordIdKey.Uuid -> {
            SkirRecordIdKey.UuidWrapper(value)
        }

        is RecordIdKey.Array -> {
            SkirRecordIdKey.ArrayWrapper(values.map(RecordIdValue::toSkirValue))
        }

        is RecordIdKey.Object -> {
            SkirRecordIdKey.ObjectWrapper(
                values.map { ObjectRecordIdKey(key = it.key, value = it.value.toSkirValue()) },
            )
        }
    }

private fun RecordIdValue.toSkirValue(): SkirRecordIdValue =
    when (this) {
        RecordIdValue.Null -> {
            SkirRecordIdValue.NULL
        }

        is RecordIdValue.Boolean -> {
            SkirRecordIdValue.BooleanWrapper(value)
        }

        is RecordIdValue.Number -> {
            SkirRecordIdValue.NumberWrapper(value)
        }

        is RecordIdValue.Float -> {
            SkirRecordIdValue.FloatWrapper(value)
        }

        is RecordIdValue.String -> {
            SkirRecordIdValue.StringWrapper(value)
        }

        is RecordIdValue.Array -> {
            SkirRecordIdValue.ArrayWrapper(values.map(RecordIdValue::toSkirValue))
        }

        is RecordIdValue.Object -> {
            SkirRecordIdValue.ObjectWrapper(
                values.map { ObjectRecordIdValue(key = it.key, value = it.value.toSkirValue()) },
            )
        }
    }
