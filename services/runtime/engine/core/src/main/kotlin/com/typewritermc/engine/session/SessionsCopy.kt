package com.typewritermc.engine.session

import com.typewritermc.identity.Engine
import com.typewritermc.identity.EngineId
import com.typewritermc.identity.Identity
import com.typewritermc.identity.Protagonist
import com.typewritermc.identity.Session
import com.typewritermc.identity.SessionId
import com.typewritermc.identity.Sessions
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.update
import java.util.concurrent.ConcurrentHashMap

/**
 * This engine's copy of every live session in the Realm's sessions bucket, kept by the [SessionKeeper]'s watch. Reads
 * answer from memory, so they work while NATS is unreachable, and each waits until the first watch has replayed the
 * bucket, so an engine that just started never answers from half a copy. The copy outlives a broken watch: the next
 * watch replays over it, and an expiry it replays still finds the key's last entry.
 */
class SessionsCopy : Sessions {
    private val live = ConcurrentHashMap<SessionId, SessionEntry>()
    private val caughtUp = MutableStateFlow(false)
    private val changes = MutableStateFlow(0L)

    /** How many changes the copy took so far; [changedSince] waits for the next. */
    val version: Long get() = changes.value

    /** Waits until the copy took a change after it was at [version]. */
    suspend fun changedSince(version: Long) {
        changes.first { it > version }
    }

    /** The engines holding [subject], one rule per kind of identity. */
    override suspend fun holders(subject: Identity): Set<EngineId> {
        caughtUp.first { it }
        return when (subject) {
            is Protagonist -> live.values.filter { it.protagonist == subject }.mapTo(linkedSetOf()) { it.holder }
            is Session -> setOfNotNull(live[subject.id]?.takeIf { it.protagonist == subject.protagonist }?.holder)
            is Engine -> setOf(subject.id)
        }
    }

    /** The live entry of session [id], or null when there is none. */
    suspend fun entry(id: SessionId): SessionEntry? {
        caughtUp.first { it }
        return live[id]
    }

    internal fun put(
        key: String,
        entry: SessionEntry,
    ) {
        live[sessionOf(key)] = entry
        changes.update { it + 1 }
    }

    /** Forgets [key]'s session and returns its last entry, or null when the copy had none. */
    internal fun expire(key: String): SessionEntry? = live.remove(sessionOf(key)).also { changes.update { it + 1 } }

    /** Whether another live session of [protagonist] remains. */
    internal fun online(protagonist: Protagonist): Boolean = live.values.any { it.protagonist == protagonist }

    internal fun caughtUp() {
        caughtUp.value = true
    }
}
