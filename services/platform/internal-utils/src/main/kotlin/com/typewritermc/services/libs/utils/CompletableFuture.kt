package com.typewritermc.services.libs.utils

import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.concurrent.CompletableFuture
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

/**
 * Suspends until the future completes without blocking a thread.
 *
 * Coroutine cancellation requests future cancellation with interruption allowed. Exceptional completion resumes
 * with its reported failure; completion wrappers are not unwrapped here.
 */
suspend fun <T> CompletableFuture<T>.await(): T =
    suspendCancellableCoroutine { continuation ->
        whenComplete { value, failure ->
            if (failure == null) continuation.resume(value) else continuation.resumeWithException(failure)
        }
        continuation.invokeOnCancellation { cancel(true) }
    }
