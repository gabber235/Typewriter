package com.typewritermc.realm.storage

import com.surrealdb.Surreal
import com.surrealdb.Transaction
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
