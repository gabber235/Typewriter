package com.typewritermc.engine.events

import com.typewritermc.authoring.GraphPlacement
import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.engine.pages.SequencePage
import com.typewritermc.engine.pages.SequenceTriggers
import com.typewritermc.events.CancelableEvent
import com.typewritermc.events.Candidate
import com.typewritermc.events.Event
import com.typewritermc.events.EventContext
import com.typewritermc.events.EventReason
import com.typewritermc.events.Handler
import com.typewritermc.events.Verdict
import com.typewritermc.events.deny
import com.typewritermc.events.pass
import com.typewritermc.formula.Var
import com.typewritermc.library.PageElements
import com.typewritermc.types.Ref
import com.typewritermc.types.TypewriterDisplay
import com.typewritermc.types.TypewriterType

/** Starts its chain on every occurrence of [E] for which [condition] holds. */
@TypewriterType(id = EVENT_ENTRY_TYPE_ID)
@TypewriterDisplay(name = "Event", description = "Starts its links when the event happens.", icon = "mdi:lightning-bolt")
data class EventEntry<E : Event>(
    override val page: Ref<PageElements.Element, SequencePage>,
    override val name: String,
    override val placement: GraphPlacement,
    override val triggers: Set<Ref<SequenceTriggers.Entry, SequenceEntry>> = emptySet(),
    val condition: Var<Boolean, EventContext<E>> = Var.Value(true),
) : Triggerable

/**
 * Decides on every occurrence of [E] for which [condition] holds: while [cancel] holds it stops what caused the event.
 * Either way it starts its chain once the outcome stands.
 */
@TypewriterType(id = CANCELABLE_EVENT_ENTRY_TYPE_ID)
@TypewriterDisplay(name = "Cancelable Event", description = "Can stop the event, then starts its links.", icon = "mdi:cancel")
data class CancelableEventEntry<E : CancelableEvent>(
    override val page: Ref<PageElements.Element, SequencePage>,
    override val name: String,
    override val placement: GraphPlacement,
    override val triggers: Set<Ref<SequenceTriggers.Entry, SequenceEntry>> = emptySet(),
    val condition: Var<Boolean, EventContext<E>> = Var.Value(true),
    val cancel: Var<Boolean, EventContext<E>> = Var.Value(false),
) : Triggerable

/** An event entry about this event starts its chain while its condition holds. */
@Handler
suspend fun <E : Event> E.start(entry: Candidate<EventEntry<E>>) {
    if (entry.condition) entry.fire()
}

/** A cancelable event entry about this event denies it while cancel holds, and starts its chain once the outcome stands. */
@Handler
fun <E : CancelableEvent> E.rule(entry: Candidate<CancelableEventEntry<E>>): Verdict =
    when {
        !entry.condition -> pass()
        entry.cancel -> deny(EventReason(code = "cancelled", message = "${entry.name} cancels this.")) { entry.fire() }
        else -> pass { entry.fire() }
    }

const val EVENT_ENTRY_TYPE_ID = "827a8d96758d41c8980c94ea0ec354df"
const val CANCELABLE_EVENT_ENTRY_TYPE_ID = "1811c5d4ec9742c495f359cffb0dce93"
