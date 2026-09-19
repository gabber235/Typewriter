package com.typewritermc.realm.repository.utils

import com.surrealdb.Surreal
import com.surrealdb.Transaction

/**
 * Commits a database transaction only after the block returns successfully.
 *
 * Failure, including commit failure, attempts cancellation and attaches cleanup failure as suppressed before
 * rethrowing. The block must not retain the transaction handle.
 */
internal inline fun <Result> Surreal.inTransaction(block: (Transaction) -> Result): Result {
    val transaction = beginTransaction()
    try {
        val result = block(transaction)
        transaction.commit()
        return result
    } catch (failure: Throwable) {
        runCatching { transaction.cancel() }.exceptionOrNull()?.let(failure::addSuppressed)
        throw failure
    }
}

/** Executes against a transaction consistent view and always cancels instead of committing. */
internal inline fun <Result> Surreal.inPreviewTransaction(block: (Transaction) -> Result): Result {
    val transaction = beginTransaction()
    return try {
        val result = block(transaction)
        transaction.cancel()
        result
    } catch (failure: Throwable) {
        runCatching { transaction.cancel() }.exceptionOrNull()?.let(failure::addSuppressed)
        throw failure
    }
}
