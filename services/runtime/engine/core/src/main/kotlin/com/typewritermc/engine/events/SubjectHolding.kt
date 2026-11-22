package com.typewritermc.engine.events

import com.typewritermc.identity.Identity

/**
 * Whether this engine holds an identity: a session of a protagonist, one session, or itself. An event about an identity
 * it does not hold runs none of its handlers here; delivery sends it to the engines that do.
 */
fun interface SubjectHolding {
    fun holds(subject: Identity): Boolean
}
