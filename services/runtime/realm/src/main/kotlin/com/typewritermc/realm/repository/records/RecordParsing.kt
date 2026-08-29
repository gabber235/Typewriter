package com.typewritermc.realm.repository.records

import com.surrealdb.Value

internal fun <Record : Any> Value.parseRecords(type: Class<Record>): List<Record> =
    when {
        isArray -> array.map { it.get(type) }
        isObject -> listOf(get(type))
        isNone || isNull -> emptyList()
        else -> error("Expected a record or record collection")
    }
