package com.typewritermc.discovery

import com.typewritermc.failures.rethrowExceptional

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
