package com.typewritermc.realm.repository.utils

import com.surrealdb.Id
import com.surrealdb.Value
import com.typewritermc.elements.ElementInstanceId
import com.typewritermc.library.BookId
import com.typewritermc.library.PageId
import com.typewritermc.library.Tag
import com.typewritermc.library.TagId
import com.typewritermc.library.tagId
import com.typewritermc.types.RecordIdKey
import com.typewritermc.types.RecordIdValue
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import skirout.kernel.v1.errors.InvalidRecordIdError
import skirout.kernel.v1.record_id.ObjectRecordIdKey
import skirout.kernel.v1.record_id.ObjectRecordIdValue
import skirout.kernel.v1.record_id.RecordId
import java.util.UUID
import kotlin.uuid.Uuid
import skirout.kernel.v1.record_id.RecordIdKey as SkirRecordIdKey
import skirout.kernel.v1.record_id.RecordIdValue as SkirRecordIdValue

internal fun RecordId.invalidRecordId(expectedTable: String): InvalidRecordIdError? = listOf(this).invalidRecordId(expectedTable)

internal fun Iterable<RecordId>.invalidRecordId(expectedTable: String): InvalidRecordIdError? {
    val givenTables = map(RecordId::table).filter { it != expectedTable }.distinct()
    if (givenTables.isEmpty()) return null
    return InvalidRecordIdError(expectedTable = expectedTable, givenTables = givenTables)
}

internal fun RecordId.toBookId(): BookId {
    requireTable("book")
    return BookId(key.toLibraryKey())
}

internal fun RecordId.toTagId(): TagId {
    requireTable("tag")
    return TagId(key.toLibraryKey())
}

internal fun RecordId.toPageId(): PageId {
    requireTable("page")
    return PageId(key.toLibraryKey())
}

/**
 * Converts a wire record id only when it targets the element table and uses a string key.
 *
 * Other resource kinds retain richer key forms, but element instance identity is currently scalar text.
 */
internal fun RecordId.toElementInstanceId(): ElementInstanceId {
    requireTable("element")
    val value = key.toLibraryKey()
    require(value is RecordIdKey.String) { "Element record ids must use string keys." }
    return ElementInstanceId(value.value)
}

internal fun RecordId.toResourceId(): ResourceId = ResourceId(table, key.toLibraryKey())

internal fun BookId.toSkirRecordId(): RecordId = RecordId(table = "book", key = key.toSkirKey())

internal fun TagId.toSkirRecordId(): RecordId = RecordId(table = "tag", key = key.toSkirKey())

internal fun PageId.toSkirRecordId(): RecordId = RecordId(table = "page", key = key.toSkirKey())

internal fun Ref<*>.toSkirRecordId(): RecordId = RecordId(table = id.table, key = id.key.toSkirKey())

internal fun ResourceId.toSkirRecordId(): RecordId = RecordId(table = table, key = key.toSkirKey())

internal fun BookId.surrealId(): com.surrealdb.RecordId = key.toSurrealRecordId("book")

internal fun TagId.surrealId(): com.surrealdb.RecordId = key.toSurrealRecordId("tag")

internal fun PageId.surrealId(): com.surrealdb.RecordId = key.toSurrealRecordId("page")

internal fun ElementInstanceId.surrealId(): com.surrealdb.RecordId = com.surrealdb.RecordId("element", value)

internal fun Ref<*>.surrealId(): com.surrealdb.RecordId = id.key.toSurrealRecordId(id.table)

internal fun ResourceId.surrealId(): com.surrealdb.RecordId = key.toSurrealRecordId(table)

internal fun Iterable<TagId>.surrealTagIds(): List<com.surrealdb.RecordId> = map(TagId::surrealId)

internal fun Iterable<Ref<Tag>>.surrealTagRefs(): List<com.surrealdb.RecordId> = map { it.tagId().surrealId() }

/**
 * Validates the target table and preserves the typed key when crossing from wire to database identity.
 *
 * Avoid stringifying ids, which loses the distinction between string and composite keys.
 */
internal fun RecordId.surrealId(expectedTable: String): com.surrealdb.RecordId {
    requireTable(expectedTable)
    return key.toLibraryKey().toSurrealRecordId(table)
}

internal fun List<RecordId>.surrealId(expectedTable: String): List<com.surrealdb.RecordId> {
    invalidRecordId(expectedTable)?.let { invalid ->
        throw IllegalArgumentException("Expected all record ids to be $expectedTable, but found ${invalid.givenTables.joinToString()}")
    }
    return map { it.surrealId(expectedTable) }
}

internal fun com.surrealdb.RecordId.toBookId(): BookId {
    require(table == "book") { "Expected a book record id, received $table." }
    return BookId(id.toLibraryKey())
}

internal fun com.surrealdb.RecordId.toTagId(): TagId {
    require(table == "tag") { "Expected a tag record id, received $table." }
    return TagId(id.toLibraryKey())
}

internal fun com.surrealdb.RecordId.toPageId(): PageId {
    require(table == "page") { "Expected a page record id, received $table." }
    return PageId(id.toLibraryKey())
}

internal fun com.surrealdb.RecordId.toElementInstanceId(): ElementInstanceId {
    require(table == "element") { "Expected an element record id, received $table." }
    require(id.isString) { "Element record ids must use string keys." }
    return ElementInstanceId(id.string)
}

internal fun com.surrealdb.RecordId.toSkirRecordId(): RecordId =
    RecordId(
        table = table,
        key = id.toLibraryKey().toSkirKey(),
    )

/**
 * Preserves table and typed key when projecting database identity into portable resource references.
 *
 * Nested array and object keys are converted recursively rather than flattened to display text.
 */
internal fun com.surrealdb.RecordId.toResourceId(): ResourceId = ResourceId(table, id.toLibraryKey())

private fun RecordId.requireTable(expectedTable: String) {
    require(table == expectedTable) { "Expected a $expectedTable record id, received $table." }
}

private fun Id.toLibraryKey(): RecordIdKey =
    when {
        isLong -> RecordIdKey.Number(long)
        isString -> RecordIdKey.String(string)
        isUuid -> RecordIdKey.Uuid(uuid.toString())
        isArray -> RecordIdKey.Array(array.map(Value::toLibraryValue))
        isObject -> RecordIdKey.Object(getObject().associate { it.key to it.value.toLibraryValue() })
        else -> error("Unsupported SurrealDB record id key")
    }

private fun Value.toLibraryValue(): RecordIdValue =
    when {
        isNull || isNone -> RecordIdValue.Null
        isBoolean -> RecordIdValue.Boolean(boolean)
        isLong -> RecordIdValue.Number(long)
        isDouble -> RecordIdValue.Float(double)
        isString -> RecordIdValue.String(string)
        isArray -> RecordIdValue.Array(array.map(Value::toLibraryValue))
        isObject -> RecordIdValue.Object(getObject().associate { it.key to it.value.toLibraryValue() })
        else -> error("Unsupported SurrealDB record id value")
    }

private fun SkirRecordIdKey.toLibraryKey(): RecordIdKey =
    when (this) {
        is SkirRecordIdKey.NumberWrapper -> RecordIdKey.Number(value)
        is SkirRecordIdKey.StringWrapper -> RecordIdKey.String(value)
        is SkirRecordIdKey.UuidWrapper -> RecordIdKey.Uuid(value)
        is SkirRecordIdKey.ArrayWrapper -> RecordIdKey.Array(value.map(SkirRecordIdValue::toLibraryValue))
        is SkirRecordIdKey.ObjectWrapper -> RecordIdKey.Object(value.associate { it.key to it.value.toLibraryValue() })
        is SkirRecordIdKey.Unknown -> error("Unknown record id key")
    }

private fun SkirRecordIdValue.toLibraryValue(): RecordIdValue =
    when (this) {
        SkirRecordIdValue.NULL -> RecordIdValue.Null
        is SkirRecordIdValue.BooleanWrapper -> RecordIdValue.Boolean(value)
        is SkirRecordIdValue.NumberWrapper -> RecordIdValue.Number(value)
        is SkirRecordIdValue.FloatWrapper -> RecordIdValue.Float(value)
        is SkirRecordIdValue.StringWrapper -> RecordIdValue.String(value)
        is SkirRecordIdValue.ArrayWrapper -> RecordIdValue.Array(value.map(SkirRecordIdValue::toLibraryValue))
        is SkirRecordIdValue.ObjectWrapper -> RecordIdValue.Object(value.associate { it.key to it.value.toLibraryValue() })
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

private fun RecordIdKey.toSurrealRecordId(table: String): com.surrealdb.RecordId =
    when (this) {
        is RecordIdKey.Number -> {
            com.surrealdb.RecordId(table, value)
        }

        is RecordIdKey.String -> {
            com.surrealdb.RecordId(table, value)
        }

        is RecordIdKey.Uuid -> {
            com.surrealdb.RecordId(table, UUID.fromString(value))
        }

        is RecordIdKey.Array -> {
            com.surrealdb.RecordId(table, com.surrealdb.Array.fromList(values.map(RecordIdValue::databaseValue)))
        }

        is RecordIdKey.Object -> {
            throw UnsupportedOperationException("Objects are not supported by the SurrealDB Java SDK.")
        }
    }

private fun RecordIdValue.databaseValue(): Any? =
    when (this) {
        RecordIdValue.Null -> null
        is RecordIdValue.Boolean -> value
        is RecordIdValue.Number -> value
        is RecordIdValue.Float -> value
        is RecordIdValue.String -> value
        is RecordIdValue.Array -> values.map(RecordIdValue::databaseValue)
        is RecordIdValue.Object -> values.mapValues { it.value.databaseValue() }
    }
