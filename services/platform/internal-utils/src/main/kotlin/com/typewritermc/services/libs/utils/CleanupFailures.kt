package com.typewritermc.services.libs.utils

/** Records failures from independent cleanup steps so that later steps still run. */
class CleanupFailures {
    @PublishedApi
    internal val failures = mutableListOf<Throwable>()

    /** Runs [action] and records its failure instead of propagating it. */
    inline fun attempt(action: () -> Unit) {
        try {
            action()
        } catch (failure: Throwable) {
            failures += failure
        }
    }

    /** Adds every recorded failure to [primary] as a suppressed exception. */
    fun suppressInto(primary: Throwable) {
        failures.forEach { failure -> if (failure !== primary) primary.addSuppressed(failure) }
    }

    /** Throws the first recorded failure with every later failure suppressed. */
    fun throwIfAny() {
        val first = failures.firstOrNull() ?: return
        failures.drop(1).forEach { failure -> if (failure !== first) first.addSuppressed(failure) }
        throw first
    }
}

/**
 * Runs every [cleanup] step, then reports their failures together.
 *
 * With a [primary] failure, cleanup failures are suppressed into it and nothing is thrown, leaving the caller to
 * rethrow [primary]. Without one, the first cleanup failure is thrown with later failures suppressed.
 */
inline fun closeAll(
    primary: Throwable? = null,
    cleanup: CleanupFailures.() -> Unit,
) {
    val failures = CleanupFailures().apply(cleanup)
    if (primary == null) failures.throwIfAny() else failures.suppressInto(primary)
}

/** Closes every resource in iteration order with [closeAll] failure reporting. */
fun Iterable<AutoCloseable?>.closeAll(primary: Throwable? = null) {
    closeAll(primary) { forEach { closeable -> attempt { closeable?.close() } } }
}
