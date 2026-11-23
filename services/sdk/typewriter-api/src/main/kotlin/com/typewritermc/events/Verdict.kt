package com.typewritermc.events

/**
 * What a decision handler says about one occurrence. Pass means "not my business" and never overrides another
 * decision. Every verdict may carry a follow up that runs once the final outcome matches it, so one handler holds both
 * the decision and its reaction:
 *
 * ```kotlin
 * @Handler
 * fun <E : CancelableEvent> E.rule(entry: Candidate<CancelableEventEntry<E>>): Verdict = when {
 *     !entry.condition -> pass()
 *     entry.cancel -> deny { entry.complete() }
 *     else -> pass { entry.complete() }
 * }
 * ```
 */
sealed interface Verdict {
    /** Runs once the final outcome matches this verdict. */
    val followUp: (suspend FollowUp.() -> Unit)?

    data class Allow(
        override val followUp: (suspend FollowUp.() -> Unit)? = null,
    ) : Verdict

    data class Deny(
        val reason: EventReason,
        override val followUp: (suspend FollowUp.() -> Unit)? = null,
    ) : Verdict

    /** Replaces the event with [change]'s result; changes apply from low to high priority, each seeing the last. */
    data class Change(
        val change: (Event) -> Event,
        override val followUp: (suspend FollowUp.() -> Unit)? = null,
    ) : Verdict

    data class Pass(
        val on: PassOn = PassOn.Allowed,
        override val followUp: (suspend FollowUp.() -> Unit)? = null,
    ) : Verdict
}

/** When a pass verdict's follow up runs. */
enum class PassOn { Allowed, Denied, Any }

/** What a follow up sees: the final outcome of the occurrence it decided on. */
interface FollowUp {
    val outcome: Outcome<Event>
}

/** The reason a deny gives when its handler names none. */
val DENIED_BY_RULE: EventReason = EventReason(code = "denied", message = "A rule denied this.")

fun allow(followUp: (suspend FollowUp.() -> Unit)? = null): Verdict = Verdict.Allow(followUp)

fun deny(
    reason: EventReason = DENIED_BY_RULE,
    followUp: (suspend FollowUp.() -> Unit)? = null,
): Verdict = Verdict.Deny(reason, followUp)

fun pass(
    on: PassOn = PassOn.Allowed,
    followUp: (suspend FollowUp.() -> Unit)? = null,
): Verdict = Verdict.Pass(on, followUp)

/** Changes the event to [change]'s result; the change is pure and sees the event lower priorities left. */
@Suppress("UNCHECKED_CAST")
fun <E : Event> change(
    followUp: (suspend FollowUp.() -> Unit)? = null,
    change: (E) -> E,
): Verdict = Verdict.Change({ change(it as E) }, followUp)
