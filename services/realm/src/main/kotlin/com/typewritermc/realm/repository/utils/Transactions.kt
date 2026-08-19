package com.typewritermc.realm.repository.utils

import com.surrealdb.Surreal
import com.surrealdb.Transaction

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
