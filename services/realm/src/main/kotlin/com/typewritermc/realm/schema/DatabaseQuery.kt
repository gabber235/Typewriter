package com.typewritermc.realm.schema

import com.surrealdb.Surreal

internal fun Surreal.execute(statement: String) {
    val response = query(statement)
    repeat(response.size()) { index -> response.take(index) }
}
