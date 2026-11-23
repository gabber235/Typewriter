package com.typewritermc.engine.session.testing

import com.typewritermc.events.ChainQueueing
import com.typewritermc.events.Event
import java.util.concurrent.CopyOnWriteArrayList

/** The chain queueing of a harness engine: it keeps every event the engine emitted, in order, instead of running it. */
class EmittedEvents : ChainQueueing {
    private val emitted = CopyOnWriteArrayList<Event>()

    /** Every event emitted so far. */
    val all: List<Event> get() = emitted.toList()

    override fun emit(event: Event) {
        emitted += event
    }
}
