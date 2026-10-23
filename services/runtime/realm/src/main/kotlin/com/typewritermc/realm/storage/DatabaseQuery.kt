package com.typewritermc.realm.schema

import com.surrealdb.Surreal

/**
 * Executes every result of a multi statement query so later statement failures cannot remain unobserved.
 *
 * SurrealDB reports statement results lazily through the response object. Consuming each result is therefore part of
 * executing the script, not merely response cleanup.
 *
 * Used for migration scripts where inspecting only the first result could incorrectly report success.
 */
internal fun Surreal.execute(statement: String) {
    val response = query(statement)
    repeat(response.size()) { index -> response.take(index) }
}
