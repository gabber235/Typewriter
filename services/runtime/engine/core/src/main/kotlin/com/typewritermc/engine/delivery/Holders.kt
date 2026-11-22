package com.typewritermc.engine.delivery

import com.typewritermc.engine.session.SessionsCopy
import com.typewritermc.events.EventResult
import com.typewritermc.identity.Engine
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Identity
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session

/**
 * The engines an event about an identity runs on, one rule per kind of identity, from this engine's copy of the
 * Realm's sessions: every engine holding a session of a protagonist, the engine holding one session, and an engine
 * itself.
 */
class Holders(
    private val copy: SessionsCopy,
) {
    suspend fun of(subject: Identity): Set<EngineId> =
        when (subject) {
            is Protagonist -> copy.holders(subject)
            is Session -> setOfNotNull(copy.entry(subject.id)?.takeIf { it.protagonist == subject.protagonist }?.holder)
            is Engine -> setOf(subject.id)
        }

    /** How many changes the copy took so far; [changedSince] waits for the next. */
    val version: Long get() = copy.version

    /** Waits until the holders may have changed since the copy was at [version]. */
    suspend fun changedSince(version: Long) = copy.changedSince(version)
}

/**
 * The strongest of [results]: [EventResult.Denied], then [EventResult.Failed], then [EventResult.Done], then
 * [EventResult.NotHandled]; the first of equal strength wins, and no result at all is [EventResult.NotHandled].
 */
fun merged(results: Collection<EventResult>): EventResult =
    results.minByOrNull { result ->
        when (result) {
            is EventResult.Denied -> 0
            is EventResult.Failed -> 1
            EventResult.Done -> 2
            EventResult.NotHandled -> 3
        }
    } ?: EventResult.NotHandled
