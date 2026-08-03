package com.typewritermc.realm.repository.utils

import com.surrealdb.Id
import com.surrealdb.Value
import skirout.kernel.v1.errors.InvalidRecordIdError
import skirout.kernel.v1.record_id.ObjectRecordIdKey
import skirout.kernel.v1.record_id.ObjectRecordIdValue
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.kernel.v1.record_id.RecordIdValue
import java.util.UUID

internal fun RecordId.invalidRecordId(expectedTable: String): InvalidRecordIdError? = listOf(this).invalidRecordId(expectedTable)

internal fun Iterable<RecordId>.invalidRecordId(expectedTable: String): InvalidRecordIdError? {
    val givenTables = map(RecordId::table).filter { it != expectedTable }.distinct()
    if (givenTables.isEmpty()) return null
    return InvalidRecordIdError(expectedTable = expectedTable, givenTables = givenTables)
}

internal fun RecordId.surrealId(expectedTable: String): com.surrealdb.RecordId {
    require(table == expectedTable) { "Expected a $expectedTable record id, received $table" }
    return toSurrealRecordId()
}

internal fun List<RecordId>.surrealId(expectedTable: String): List<com.surrealdb.RecordId> {
    invalidRecordId(expectedTable)?.let { invalid ->
        throw IllegalArgumentException("Expected all record ids to be $expectedTable, but found ${invalid.givenTables.joinToString()}")
    }
    return map { it.toSurrealRecordId() }
}

internal fun com.surrealdb.RecordId.toSkirRecordId(): RecordId =
    RecordId(
        table = table,
        key = id.toSkirRecordIdKey(),
    )

private fun Id.toSkirRecordIdKey(): RecordIdKey =
    when {
        isLong -> {
            RecordIdKey.NumberWrapper(long)
        }

        isString -> {
            RecordIdKey.StringWrapper(string)
        }

        isUuid -> {
            RecordIdKey.UuidWrapper(uuid.toString())
        }

        isArray -> {
            RecordIdKey.ArrayWrapper(array.map(Value::toSkirRecordIdValue))
        }

        isObject -> {
            RecordIdKey.ObjectWrapper(
                getObject().map { ObjectRecordIdKey(key = it.key, value = it.value.toSkirRecordIdValue()) },
            )
        }

        else -> {
            error("Unsupported SurrealDB record id key")
        }
    }

private fun Value.toSkirRecordIdValue(): RecordIdValue =
    when {
        isNull || isNone -> {
            RecordIdValue.NULL
        }

        isBoolean -> {
            RecordIdValue.BooleanWrapper(boolean)
        }

        isLong -> {
            RecordIdValue.NumberWrapper(long)
        }

        isDouble -> {
            RecordIdValue.FloatWrapper(double)
        }

        isString -> {
            RecordIdValue.StringWrapper(string)
        }

        isArray -> {
            RecordIdValue.ArrayWrapper(array.map(Value::toSkirRecordIdValue))
        }

        isObject -> {
            RecordIdValue.ObjectWrapper(
                getObject().map { ObjectRecordIdValue(key = it.key, value = it.value.toSkirRecordIdValue()) },
            )
        }

        else -> {
            error("Unsupported SurrealDB record id value")
        }
    }

internal fun RecordId.toSurrealRecordId(): com.surrealdb.RecordId =
    when (this.key) {
        is RecordIdKey.NumberWrapper -> {
            com.surrealdb.RecordId(table, (this.key as RecordIdKey.NumberWrapper).value)
        }

        is RecordIdKey.StringWrapper -> {
            com.surrealdb.RecordId(table, (this.key as RecordIdKey.StringWrapper).value)
        }

        is RecordIdKey.UuidWrapper -> {
            com.surrealdb.RecordId(table, UUID.fromString((this.key as RecordIdKey.UuidWrapper).value))
        }

        is RecordIdKey.ArrayWrapper -> {
            com.surrealdb.RecordId(
                table,
                com.surrealdb.Array.fromList((this.key as RecordIdKey.ArrayWrapper).value.map(RecordIdValue::databaseValue)),
            )
        }

        is RecordIdKey.ObjectWrapper -> {
            throw UnsupportedOperationException(
                "Objects are not supported in the java sdk yet. Maybe in the kotlin sdk in the future?",
            )
        }

        is RecordIdKey.Unknown -> {
            error("Unknown record id key")
        }
    }

private fun RecordIdValue.databaseValue(): Any? =
    when (this) {
        RecordIdValue.NULL -> null
        is RecordIdValue.BooleanWrapper -> value
        is RecordIdValue.NumberWrapper -> value
        is RecordIdValue.FloatWrapper -> value
        is RecordIdValue.StringWrapper -> value
        is RecordIdValue.ArrayWrapper -> value.map(RecordIdValue::databaseValue)
        is RecordIdValue.ObjectWrapper -> value.associate { it.key to it.value.databaseValue() }
        is RecordIdValue.Unknown -> error("Unknown record id value")
    }
