package com.typewritermc.engine.session

import com.typewritermc.engine.events.SubjectHolding
import com.typewritermc.identity.Engine
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Identity
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import java.util.concurrent.ConcurrentHashMap

/**
 * The sessions this engine's keeper reported and still has: connected, not disconnected, and not lost to another
 * engine. The keeper keeps it on its own, without NATS, so events keep running while NATS is down. Engine [self] holds
 * a protagonist with any of these sessions, each of these sessions, and itself.
 */
class HeldSessions(
    private val self: EngineId,
) : SubjectHolding {
    private val held = ConcurrentHashMap<SessionId, Protagonist>()

    override fun holds(subject: Identity): Boolean =
        when (subject) {
            is Protagonist -> held.containsValue(subject)
            is Session -> held[subject.id] == subject.protagonist
            is Engine -> subject.id == self
        }

    internal fun hold(
        protagonist: Protagonist,
        id: SessionId,
    ) {
        held[id] = protagonist
    }

    internal fun release(id: SessionId) {
        held.remove(id)
    }
}
