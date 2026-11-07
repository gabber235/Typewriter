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
fun Throwable.findExceptional(): Throwable? {
    val visited = Collections.newSetFromMap(IdentityHashMap<Throwable, Boolean>())
    val pending = ArrayDeque<Throwable>().apply { add(this@findExceptional) }
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
fun Throwable.rethrowExceptional() {
    findExceptional()?.let { throw it }
}

/**
 * Rethrows what must not become extension code's own failure: cancellation and fatal JVM errors. An exception of its
 * own, a [LinkageError] from code built against another API, and a [StackOverflowError] from code recursing by itself
 * are that extension's failure, so the caller turns them into its finding.
 */
fun Throwable.rethrowUnlessExtensionFailure() {
    if (this is LinkageError || this is StackOverflowError) return
    rethrowExceptional()
    if (this !is Exception) throw this
}

/**
 * Runs extension code: returns what [block] returns, or what [onFailure] makes of a failure that is the extension's
 * own (see [rethrowUnlessExtensionFailure]). Cancellation and fatal JVM errors propagate.
 */
inline fun <T> runExtension(
    block: () -> T,
    onFailure: (Throwable) -> T,
): T =
    runCatching(block).getOrElse { failure ->
        failure.rethrowUnlessExtensionFailure()
        onFailure(failure)
    }

@Suppress("DEPRECATION")
private fun Throwable.isExceptional(): Boolean =
    this is CancellationException || this is VirtualMachineError || this is ThreadDeath || this is LinkageError
