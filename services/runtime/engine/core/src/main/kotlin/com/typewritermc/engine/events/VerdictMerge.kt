package com.typewritermc.engine.events

import com.typewritermc.events.Event
import com.typewritermc.events.FollowUp
import com.typewritermc.events.Outcome
import com.typewritermc.events.PassOn
import com.typewritermc.events.Verdict

/** One verdict with the priority of the handler or entry that gave it. */
data class Ranked(
    val verdict: Verdict,
    val priority: Int,
)

/** The merged result of one occurrence: its outcome and the follow ups that match it, highest priority first. */
class Decision<out E : Event>(
    val outcome: Outcome<E>,
    val followUps: List<suspend () -> Unit>,
)

/**
 * Merges the verdicts on [event] into one outcome. Passes never decide. Changes apply from low to high priority, each
 * seeing the event the one before left. Between allow and deny the highest priority wins and a tie denies; without
 * either the event is allowed. Each follow up runs only when the outcome matches its verdict.
 */
@Suppress("UNCHECKED_CAST")
fun <E : Event> merge(
    event: E,
    verdicts: List<Ranked>,
): Decision<E> {
    val changed =
        verdicts
            .filter { it.verdict is Verdict.Change }
            .sortedBy { it.priority }
            .fold(event as Event) { current, ranked -> (ranked.verdict as Verdict.Change).change(current) } as E
    val decisive = verdicts.filter { it.verdict is Verdict.Allow || it.verdict is Verdict.Deny }
    val top = decisive.maxOfOrNull { it.priority }
    val deny = decisive.firstOrNull { it.priority == top && it.verdict is Verdict.Deny }?.verdict as Verdict.Deny?
    val outcome: Outcome<E> = if (deny != null) Outcome.Denied(changed, deny.reason) else Outcome.Allowed(changed)
    val view =
        object : FollowUp {
            override val outcome: Outcome<Event> = outcome
        }
    val followUps =
        verdicts
            .sortedByDescending { it.priority }
            .filter { it.verdict.matches(outcome) }
            .mapNotNull { ranked -> ranked.verdict.followUp?.let { followUp -> suspend { followUp(view) } } }
    return Decision(outcome, followUps)
}

private fun Verdict.matches(outcome: Outcome<*>): Boolean {
    val denied = outcome is Outcome.Denied
    return when (this) {
        is Verdict.Deny -> denied
        is Verdict.Allow, is Verdict.Change -> !denied
        is Verdict.Pass ->
            when (on) {
                PassOn.Allowed -> !denied
                PassOn.Denied -> denied
                PassOn.Any -> true
            }
    }
}
