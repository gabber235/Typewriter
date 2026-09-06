package com.typewritermc.services.libs.utils

import kotlinx.coroutines.CancellationException
import java.util.Collections
import java.util.IdentityHashMap

/**
 * Finds cancellation or fatal runtime failure through cause and suppressed exception graphs.
 *
 * Identity based cycle protection prevents loops. The first exceptional throwable encountered is returned
 * unchanged.
 */
fun findExceptionalThrowable(throwable: Throwable): Throwable? {
    val visited = Collections.newSetFromMap(IdentityHashMap<Throwable, Boolean>())
    val pending = ArrayDeque<Throwable>().apply { add(throwable) }
    while (pending.isNotEmpty()) {
        val current = pending.removeFirst()
        if (!visited.add(current)) continue
        if (current.isExceptional()) return current
        current.cause?.let(pending::addLast)
        current.suppressed.forEach(pending::addLast)
    }
    return null
}

/**
 * Preserves cancellation and fatal failures before converting ordinary exceptions into result values.
 *
 * Wrapped and suppressed exceptional failures are included so recovery code cannot classify them as retryable
 * errors.
 */
fun rethrowExceptionalThrowable(throwable: Throwable) {
    findExceptionalThrowable(throwable)?.let { throw it }
}

@Suppress("DEPRECATION")
private fun Throwable.isExceptional(): Boolean =
    this is CancellationException || this is VirtualMachineError || this is ThreadDeath || this is LinkageError
