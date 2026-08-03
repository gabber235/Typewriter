package com.typewritermc.services.libs.utils

import kotlinx.coroutines.suspendCancellableCoroutine
import java.util.concurrent.CompletableFuture
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException

suspend fun <T> CompletableFuture<T>.await(): T =
    suspendCancellableCoroutine { continuation ->
        whenComplete { value, failure ->
            if (failure == null) continuation.resume(value) else continuation.resumeWithException(failure)
        }
        continuation.invokeOnCancellation { cancel(true) }
    }
