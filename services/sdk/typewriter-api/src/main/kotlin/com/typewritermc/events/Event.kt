package com.typewritermc.events

import com.typewritermc.identity.PrincipalId
import com.typewritermc.identity.Session
import com.typewritermc.types.TypewriterRecordContract

/**
 * Something that happened, once. An event is a plain Typewriter type: every field is a Typewriter type, so formulas read
 * it as `event` and it can cross engines. Its subject is its only identity field (a [com.typewritermc.identity.Protagonist]
 * for most); an event with no identity field has no subject, such as a tick.
 *
 * What a delivery of the event may do (decide, change) is typed on its [Source], not on the event.
 */
@TypewriterRecordContract
interface Event

/** An event a verdict may deny, which stops what caused it (a block stays, a message is not sent). */
@TypewriterRecordContract
interface CancelableEvent : Event

/**
 * Who caused one occurrence: the session it came from and that session's principal. It travels beside the event,
 * filled by the source, never by the event, so a client cannot fake it.
 */
data class Origin(
    val session: Session,
    val principal: PrincipalId,
)

/**
 * Why an event was denied or failed, in a form any panel can show: [code] and [message] match a diagnostic's, and
 * [detail] is an optional typed value an editor may know how to show.
 */
data class EventReason(
    val code: String,
    val message: String,
    val detail: Any? = null,
)

/** How one occurrence ended, from Typewriter's own verdicts. */
sealed interface Outcome<out E : Event> {
    /** The event as it was applied: after every `change` verdict. */
    val event: E

    data class Allowed<out E : Event>(
        override val event: E,
    ) : Outcome<E>

    data class Denied<out E : Event>(
        override val event: E,
        val reason: EventReason,
    ) : Outcome<E>
}
