package com.typewritermc.services.libs.telemetry

import com.typewritermc.services.libs.utils.rethrowExceptional

/**
 * Provides a stable machine readable failure identity independent of exception text.
 *
 * Create through [of], which accepts lowercase alphanumeric segments separated by hyphens. Use a bounded
 * vocabulary rather than request data to keep telemetry grouping stable.
 */
@JvmInline
value class ErrorSlug private constructor(
    val value: String,
) {
    companion object {
        private val pattern = Regex("[a-z0-9]+(?:-[a-z0-9]+)*")

        /** Validates and creates a slug suitable for stable telemetry grouping. */
        fun of(value: String): ErrorSlug {
            require(pattern.matches(value)) { "Error slug must be lowercase kebab-case: $value" }
            return ErrorSlug(value)
        }
    }
}

/**
 * Adds a stable error slug while retaining the original failure as cause.
 *
 * [wrap] preserves an already slugged exception instead of replacing its identity or adding repetitive wrappers.
 */
class SluggedException private constructor(
    val slug: ErrorSlug,
    cause: Throwable,
) : RuntimeException(cause.message, cause) {
    companion object {
        /** Returns the existing classification unchanged, or wraps [cause] with [slug]. */
        fun wrap(
            slug: ErrorSlug,
            cause: Throwable,
        ): SluggedException = cause as? SluggedException ?: SluggedException(slug, cause)
    }
}

/**
 * Classifies ordinary thrown failures while preserving cancellation and fatal exceptions.
 *
 * Already slugged failures retain their original slug. No logging occurs here; the owning span boundary records
 * the failure.
 */
inline fun <T> withErrorSlug(
    slug: ErrorSlug,
    block: () -> T,
): T =
    try {
        block()
    } catch (failure: Throwable) {
        failure.rethrowExceptional()
        if (failure is SluggedException) throw failure
        throw SluggedException.wrap(slug, failure)
    }

/**
 * Applies stable error classification around suspending work without swallowing cancellation.
 *
 * Exceptional causes are found through cause and suppressed chains before ordinary failures are wrapped.
 */
suspend fun <T> withErrorSlugSuspending(
    slug: ErrorSlug,
    block: suspend () -> T,
): T =
    try {
        block()
    } catch (failure: Throwable) {
        failure.rethrowExceptional()
        if (failure is SluggedException) throw failure
        throw SluggedException.wrap(slug, failure)
    }

/** Classifies a failed result while returning successful values unchanged and preserving exceptional failures. */
fun <T> Result<T>.withErrorSlug(slug: ErrorSlug): Result<T> =
    fold(
        onSuccess = { Result.success(it) },
        onFailure = { failure ->
            failure.rethrowExceptional()
            if (failure is SluggedException) {
                Result.failure(failure)
            } else {
                Result.failure(SluggedException.wrap(slug, failure))
            }
        },
    )
