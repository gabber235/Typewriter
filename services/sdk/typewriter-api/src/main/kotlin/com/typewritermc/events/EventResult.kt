package com.typewritermc.events

/**
 * How one occurrence ended on every engine that holds its subject. Each holder decides for itself; the merged result
 * is the strongest of theirs: [Denied], then [Failed], then [Done], then [NotHandled].
 */
sealed interface EventResult {
    /** A handler ran and none denied or failed. */
    data object Done : EventResult

    /** A verdict denied the occurrence for [reason]. */
    data class Denied(
        val reason: EventReason,
    ) : EventResult

    /** The occurrence could not end as its handlers meant, for [reason]: a handler failed, or delivery did. */
    data class Failed(
        val reason: EventReason,
    ) : EventResult

    /** No handler ran: none applies, or no engine holds the subject. */
    data object NotHandled : EventResult
}

/** Thrown by an after handler to end its occurrence as [EventResult.Failed] with [reason]. */
class EventFailure(
    val reason: EventReason,
) : RuntimeException(reason.message)

/**
 * Sends events to every engine that holds their subject and waits for the merged result:
 *
 * ```kotlin
 * when (val result = emitter.send(QuestOffered(protagonist, quest))) {
 *     is EventResult.Denied -> chat.send(result.reason.message)
 *     else -> Unit
 * }
 * ```
 *
 * A handler's `emit(event)` delivers under the same rule without waiting.
 */
interface Emitter : EnginePart {
    /** Delivers [event], caused by [origin] when one is given, and returns its merged result. */
    suspend fun send(
        event: Event,
        origin: Origin? = null,
    ): EventResult
}
