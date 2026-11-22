package com.typewritermc.engine.events

import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.engine.pages.SequenceTriggers
import com.typewritermc.events.Candidate
import com.typewritermc.events.Context
import com.typewritermc.events.Event
import com.typewritermc.events.Triggered
import com.typewritermc.identity.Identity
import com.typewritermc.types.Ref
import com.typewritermc.types.ResourceId
import kotlin.coroutines.AbstractCoroutineContextElement
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.coroutineContext

/** A sequence entry that links to the entries it triggers next. */
interface Triggerable : SequenceEntry {
    val triggers: Set<Ref<SequenceTriggers.Entry, SequenceEntry>>
}

/** Fires this entry's links for its subject with its context: an event entry starts its chain this way. */
suspend fun Candidate<Triggerable>.fire() = entry.triggers.fire(context, subject)

/** Ends this step and fires the entry's links, carrying the chain's context on. */
suspend fun Triggered<Triggerable>.complete() = entry.triggers.fire(context, subject)

/**
 * Fires these links for [subject] with [context]; an entry that picks which of its links go on (a random gate) fires its
 * chosen ones this way. A link into an entry whose book does not apply to [subject] is skipped. A link listed several
 * times starts its entry that many times, while a start equal to one from another event in the same tick merges into it.
 */
suspend fun Collection<Ref<SequenceTriggers.Entry, SequenceEntry>>.fire(
    context: Context,
    subject: Identity?,
) {
    if (subject == null) return
    val chain = checkNotNull(coroutineContext[ChainContent]) { "Links fire from after handlers and follow ups only." }
    val repeats = mutableMapOf<ResourceId, Int>()
    mapNotNull { chain.published.entry(it.target) }
        .filter { it.appliesTo(subject) }
        .forEach { linked ->
            val repeat = repeats.getOrDefault(linked.id, 0)
            repeats[linked.id] = repeat + 1
            chain.start(Triggered(linked.entry, subject, context), repeat)
        }
}

/**
 * The publication an after run belongs to, so links resolve against the content the run started with, and how its
 * chain starts are queued.
 */
internal class ChainContent(
    val published: PublishedEntries,
    /** Queues a chain start; the second argument counts the equal starts before it in the same `fire` call. */
    val start: (Event, Int) -> Unit,
) : AbstractCoroutineContextElement(Key) {
    companion object Key : CoroutineContext.Key<ChainContent>
}
