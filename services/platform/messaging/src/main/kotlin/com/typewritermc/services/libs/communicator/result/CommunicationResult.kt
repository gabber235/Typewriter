package com.typewritermc.services.libs.communicator.result

import com.typewritermc.services.libs.telemetry.ErrorSlug

/** Explicit communication success or infrastructure failure. */
sealed interface CommunicationResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : CommunicationResult<Value>

    data class Failure(
        val error: CommunicationError,
    ) : CommunicationResult<Nothing>
}

/** Typed communication failures. Cancellation is never represented as a value. */
sealed interface CommunicationError {
    val slug: ErrorSlug
    val cause: Throwable?

    data class Encode(
        override val slug: ErrorSlug,
        override val cause: Throwable,
    ) : CommunicationError

    data class Decode(
        override val slug: ErrorSlug,
        override val cause: Throwable,
    ) : CommunicationError

    data class Timeout(
        override val slug: ErrorSlug,
        override val cause: Throwable? = null,
    ) : CommunicationError

    data class Unavailable(
        override val slug: ErrorSlug,
        override val cause: Throwable? = null,
    ) : CommunicationError

    data class NoResponders(
        override val slug: ErrorSlug,
        override val cause: Throwable? = null,
    ) : CommunicationError

    data class Transport(
        override val slug: ErrorSlug,
        override val cause: Throwable,
    ) : CommunicationError
}
