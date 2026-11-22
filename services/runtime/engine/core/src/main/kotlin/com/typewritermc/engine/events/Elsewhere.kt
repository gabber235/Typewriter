package com.typewritermc.engine.events

import com.typewritermc.events.Event
import com.typewritermc.events.Origin
import com.typewritermc.identity.Identity

/** Hands an occurrence to the engines other than this one that hold its subject; delivery is the one that does. */
fun interface Elsewhere {
    /** Delivers [event], about [subject] and caused by [origin], to every other holder of [subject], without waiting. */
    fun forward(
        event: Event,
        subject: Identity,
        origin: Origin?,
    )
}
