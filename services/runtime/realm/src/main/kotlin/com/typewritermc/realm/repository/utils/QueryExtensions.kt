package com.typewritermc.realm.repository.utils

import com.surrealdb.Response
import com.surrealdb.SurrealException
import com.surrealdb.Value

/**
 * Consumes transaction statement results while preserving the substantive failure rather than a skipped query
 * message.
 *
 * The requested index must exist. Errors at other statements can fail the operation because a successful target
 * result alone does not prove the transaction succeeded.
 */
fun Response.takeTransaction(index: Int): Value {
    require(index >= 0) { "Index must be non-negative, got $index" }
    require(index < size()) { "Index must be less than the size of the response, got $index and size ${size()}" }

    var result: Value? = null
    var targetFailure: SurrealException? = null
    for (i in 0 until size()) {
        try {
            val value = take(i)
            if (i == index) result = value
        } catch (e: SurrealException) {
            if (i == index) targetFailure = e
            val message = e.message ?: continue
            if (!message.contains("The query was not executed due to a failed transaction")) {
                throw TransactionException(i, e)
            }
        }
    }
    return result ?: throw checkNotNull(targetFailure)
}

/**
 * Adds the failing statement index while retaining the original database exception as cause.
 */
class TransactionException(
    index: Int,
    cause: Throwable,
) : RuntimeException("Failed to run transaction, statement $index", cause)
