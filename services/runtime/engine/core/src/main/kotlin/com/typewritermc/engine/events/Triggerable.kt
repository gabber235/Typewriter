package com.typewritermc.engine.events

import com.typewritermc.engine.pages.SequenceEntry
import com.typewritermc.engine.pages.SequenceTriggers
import com.typewritermc.events.Candidate
import com.typewritermc.events.Context
import com.typewritermc.events.Triggered
import com.typewritermc.events.emit
import com.typewritermc.identity.Identity
import com.typewritermc.types.Ref
import kotlin.coroutines.AbstractCoroutineContextElement
import kotlin.coroutines.CoroutineContext
import kotlin.coroutines.coroutineContext

/** A sequence entry that links to the entries it triggers next. */
interface Triggerable : SequenceEntry {
    val triggers: Set<Ref<SequenceTriggers.Entry, SequenceEntry>>
}

/** Fires this entry's links for its subject with its context: an event entry starts its chain this way. */
suspend fun Candidate<Triggerable>.fire() = fireLinks(entry, subject, context)

/** Ends this step and fires the entry's links, carrying the chain's context on. */
suspend fun Triggered<Triggerable>.complete() = fireLinks(entry, subject, context)

private suspend fun fireLinks(
    entry: Triggerable,
    subject: Identity?,
    context: Context,
) {
    if (subject == null) return
    val published = checkNotNull(coroutineContext[ChainContent]) { "Links fire from after handlers and follow ups only." }.published
    entry.triggers
        .mapNotNull { published.entry(it.target) }
        .filter { it.appliesTo(subject) }
        .forEach { emit(Triggered(it.entry, subject, context)) }
}

/** The publication an after run belongs to, so links resolve against the content the run started with. */
internal class ChainContent(
    val published: PublishedEntries,
) : AbstractCoroutineContextElement(Key) {
    companion object Key : CoroutineContext.Key<ChainContent>
}
