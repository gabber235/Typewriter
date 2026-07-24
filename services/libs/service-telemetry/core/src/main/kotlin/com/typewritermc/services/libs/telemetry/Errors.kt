package com.typewritermc.services.libs.telemetry

import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable

@JvmInline
value class ErrorSlug private constructor(val value: String) {
    companion object {
        private val pattern = Regex("[a-z0-9]+(?:-[a-z0-9]+)*")
        fun of(value: String): ErrorSlug {
            require(pattern.matches(value)) { "Error slug must be lowercase kebab-case: $value" }
            return ErrorSlug(value)
        }
    }
}

class SluggedException private constructor(val slug: ErrorSlug, cause: Throwable) : RuntimeException(cause.message, cause) {
    companion object {
        fun wrap(slug: ErrorSlug, cause: Throwable): SluggedException =
            cause as? SluggedException ?: SluggedException(slug, cause)
    }
}

inline fun <T> withErrorSlug(slug: ErrorSlug, block: () -> T): T = try {
    block()
} catch (failure: Throwable) {
    rethrowExceptionalThrowable(failure)
    if (failure is SluggedException) throw failure
    throw SluggedException.wrap(slug, failure)
}

suspend fun <T> withErrorSlugSuspending(slug: ErrorSlug, block: suspend () -> T): T = try {
    block()
} catch (failure: Throwable) {
    rethrowExceptionalThrowable(failure)
    if (failure is SluggedException) throw failure
    throw SluggedException.wrap(slug, failure)
}

fun <T> Result<T>.withErrorSlug(slug: ErrorSlug): Result<T> = fold(
    onSuccess = { Result.success(it) },
    onFailure = { failure ->
        rethrowExceptionalThrowable(failure)
        if (failure is SluggedException) Result.failure(failure)
        else Result.failure(SluggedException.wrap(slug, failure))
    },
)
