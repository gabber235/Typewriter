package com.typewritermc.services.libs.utils

import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.withTimeout
import kotlin.time.Duration

/**
 * Thread-safe wrapper for a value that will be set later.
 *
 * Use when a dependency becomes available after application startup
 * (e.g., NatsClient after connection, Credential after issuance).
 * Consumers inject DeferredProvider<T> and call get() or getOrNull().
 * Producers call set() when the value is ready.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class DeferredProvider<T> {
    private val deferred = CompletableDeferred<T>()

    val isSet: Boolean
        get() = deferred.isCompleted

    suspend fun get(): T = deferred.await()

    suspend fun get(timeout: Duration): T = withTimeout(timeout) { deferred.await() }

    fun getOrNull(): T? = if (deferred.isCompleted) deferred.getCompleted() else null

    fun set(value: T) {
        if (!deferred.complete(value)) {
            throw IllegalStateException("DeferredProvider value already set")
        }
    }

    fun trySet(value: T): Boolean = deferred.complete(value)
}
