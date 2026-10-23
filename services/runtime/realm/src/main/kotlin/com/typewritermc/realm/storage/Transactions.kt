package com.typewritermc.realm.repository.utils

import com.surrealdb.Surreal
import com.surrealdb.SurrealException
import com.surrealdb.Transaction
import kotlinx.coroutines.CancellationException
import java.util.WeakHashMap

/**
 * Commits a database transaction only after the block returns successfully.
 *
 * Failure, including commit failure, attempts cancellation and attaches cleanup failure as suppressed before
 * rethrowing. The block must not retain the transaction handle.
 */
internal inline fun <Result> Surreal.inTransaction(block: (Transaction) -> Result): Result =
    synchronized(transactionAdmission(this)) {
        val transaction = beginTransaction()
        try {
            val result = block(transaction)
            transaction.commit()
            result
        } catch (failure: Throwable) {
            runCatching { transaction.cancel() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }

/** Executes against a transaction consistent view and always cancels instead of committing. */
internal inline fun <Result> Surreal.inPreviewTransaction(block: (Transaction) -> Result): Result =
    synchronized(transactionAdmission(this)) {
        val transaction = beginTransaction()
        try {
            val result = block(transaction)
            transaction.cancel()
            result
        } catch (failure: Throwable) {
            runCatching { transaction.cancel() }.exceptionOrNull()?.let(failure::addSuppressed)
            throw failure
        }
    }

@PublishedApi
internal fun transactionAdmission(database: Surreal): Any =
    synchronized(transactionAdmissions) {
        transactionAdmissions.getOrPut(database, ::Any)
    }

private val transactionAdmissions = WeakHashMap<Surreal, Any>()

/** Retries only transaction conflicts while preserving one prepared authoring decision. */
internal class StorageRetryPolicy(
    private val maximumAttempts: Int = 4,
) {
    init {
        require(maximumAttempts > 0) { "Maximum attempts must be positive." }
    }

    inline fun <Result> retryWriteConflicts(attempt: () -> Result): Result {
        var latest: Throwable? = null
        repeat(maximumAttempts) {
            try {
                return attempt()
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (failure: Throwable) {
                if (!failure.isStorageWriteConflict()) throw failure
                latest = failure
            }
        }
        throw requireNotNull(latest)
    }
}

private fun Throwable.isStorageWriteConflict(): Boolean {
    if (this is SurrealException) {
        val text = message.orEmpty().lowercase()
        if (text.contains("conflict") || text.contains("transaction was aborted")) return true
    }
    return cause?.isStorageWriteConflict() == true
}
