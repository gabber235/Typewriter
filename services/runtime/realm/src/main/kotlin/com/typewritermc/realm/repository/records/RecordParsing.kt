package com.typewritermc.realm.repository.records

import com.surrealdb.Value

/**
 * Normalizes an array, single record, or absent query result into record objects.
 *
 * NONE and NULL produce an empty list. Scalar values fail instead of being silently dropped.
 */
internal fun <Record : Any> Value.parseRecords(type: Class<Record>): List<Record> =
    when {
        isArray -> array.map { it.get(type) }
        isObject -> listOf(get(type))
        isNone || isNull -> emptyList()
        else -> error("Expected a record or record collection")
    }
