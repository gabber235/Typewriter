package com.typewritermc.realm.repository.utils

import com.surrealdb.Response
import com.surrealdb.SurrealException
import com.surrealdb.Value

fun Response.takeTransaction(index: Int): Value {
    require(index >= 0) { "Index must be non-negative, got $index" }
    require(index < size()) { "Index must be less than the size of the response, got $index and size ${size()}" }

    val exception: SurrealException
    try {
        return take(index)
    } catch (e: SurrealException) {
        exception = e
    }

    for (i in 0 until size()) {
        try {
            take(i)
        } catch (e: SurrealException) {
            val message = e.message ?: continue
            if (!message.contains("The query was not executed due to a failed transaction")) {
                throw TransactionException(i, e)
            }
        }
    }

    throw exception
}

class TransactionException(
    index: Int,
    cause: Throwable,
) : RuntimeException("Failed to run transaction, statement $index", cause)
