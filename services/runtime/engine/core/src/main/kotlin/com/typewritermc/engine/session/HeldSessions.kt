package com.typewritermc.engine.session

import com.typewritermc.engine.events.SubjectHolding
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.SessionId
import java.util.concurrent.ConcurrentHashMap

/**
 * The sessions this engine's keeper reported and still has: connected, not disconnected, and not lost to another
 * engine. The keeper keeps it on its own, without NATS, so events keep running while NATS is down.
 */
class HeldSessions : SubjectHolding {
    private val held = ConcurrentHashMap<SessionId, Protagonist>()

    override fun holds(protagonist: Protagonist): Boolean = held.containsValue(protagonist)

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
