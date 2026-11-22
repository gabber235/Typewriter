package com.typewritermc.events

import com.typewritermc.elements.Entry
import com.typewritermc.identity.Identity
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.types.TypewriterType

/**
 * An engine took [session]: a join, a relog, a server move, or a return after a crash. Work that must follow the
 * connection, such as rejoining a step, belongs here, because a server move keeps the session.
 */
@TypewriterType(id = SESSION_ARRIVED_TYPE_ID)
data class SessionArrived(
    val session: Session,
) : Event

/** [protagonist] came online: it had no session anywhere before this one. Fired by the engine that took the session. */
@TypewriterType(id = PROTAGONIST_JOINED_TYPE_ID)
data class ProtagonistJoined(
    val protagonist: Protagonist,
) : Event

/**
 * [protagonist] is gone everywhere: its last session ended after the grace. Best effort, since after a crash no engine
 * is left to fire it, and the player is no longer available; cleanup that must happen uses session scoped values.
 */
@TypewriterType(id = PROTAGONIST_LEFT_TYPE_ID)
data class ProtagonistLeft(
    val protagonist: Protagonist,
) : Event

/**
 * A link fired into [entry] for [subject], carrying the chain's [context]. Actions and steps react to it through a
 * handler on [Triggered], which the engine builds from it with its entry reader; nothing follows links on its own. It is
 * queued like any emitted event and stays on the engine that fired it; two equal starts in one tick merge into one
 * chain.
 */
data class TriggeredEvent<out E : Entry>(
    val entry: E,
    val subject: Identity,
    val context: Context,
) : Event

const val SESSION_ARRIVED_TYPE_ID = "6c2f4e8a1d3b4f7e9a0c5b8d2e4f6a13"
const val PROTAGONIST_JOINED_TYPE_ID = "8d1e3f5a7b9c4d2e8f0a1b3c5d7e9f24"
const val PROTAGONIST_LEFT_TYPE_ID = "9e2f4a6b8c0d4e3f9a1b2c4d6e8f0a35"
