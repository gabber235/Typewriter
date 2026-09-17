package com.typewritermc.realm.repository.search

import com.surrealdb.Surreal
import com.surrealdb.Value

/** Collects independent search statements into one Surreal request and decodes each result by statement index. */
internal class AuthoringSearchQueryBatch(
    private val database: Surreal,
) {
    private val statements = mutableListOf<String>()
    private val bindings = mutableMapOf<String, Any>()
    private val decoders = mutableListOf<(Value) -> Unit>()
    private var executed = false

    fun <Result> enqueue(
        statement: String,
        statementBindings: Map<String, Any>,
        decode: (Value) -> Result,
    ): PendingSearchResult<Result> {
        check(!executed) { "Search batch has already executed." }
        val index = statements.size
        val pending = PendingSearchResult<Result>()
        statements += namespace(statement, statementBindings, index)
        decoders += { value -> pending.complete(decode(value)) }
        statementBindings.forEach { (name, value) ->
            bindings[qualifiedName(index, name)] = value
        }
        return pending
    }

    fun execute() {
        check(!executed) { "Search batch has already executed." }
        executed = true
        if (statements.isEmpty()) return
        val response = database.query(statements.joinToString("\n"), bindings)
        decoders.forEachIndexed { index, decode -> decode(response.take(index)) }
    }

    private fun namespace(
        statement: String,
        statementBindings: Map<String, Any>,
        index: Int,
    ): String {
        val referenced = BINDING_REFERENCE.findAll(statement).map { it.groupValues[1] }.toSet()
        require(referenced == statementBindings.keys) {
            "Search statement bindings differ from referenced variables. Referenced: $referenced, provided: ${statementBindings.keys}"
        }
        return BINDING_REFERENCE.replace(statement) { match ->
            "\$${qualifiedName(index, match.groupValues[1])}"
        }
    }

    private fun qualifiedName(
        index: Int,
        name: String,
    ): String = "search_${index}_$name"

    private companion object {
        val BINDING_REFERENCE = Regex("\\$([A-Za-z_][A-Za-z0-9_]*)")
    }
}

internal class PendingSearchResult<Result> {
    private var result: Result? = null
    private var completed = false

    val value: Result
        get() {
            check(completed) { "Search batch has not executed." }
            @Suppress("UNCHECKED_CAST")
            return result as Result
        }

    internal fun complete(value: Result) {
        check(!completed) { "Search result completed twice." }
        result = value
        completed = true
    }
}
