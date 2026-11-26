package com.typewritermc.engine.session.testing

import com.typewritermc.identity.OnlineSessions
import com.typewritermc.identity.Session
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update
import java.time.Clock
import java.time.Instant

/**
 * The sessions of a test engine, which a test changes as its engine kind would: [join] and [quit] change the set at
 * once, and a session connects at [clock]'s instant unless the test names another. [initial] are the sessions the
 * engine starts with, each with the instant it connected, as an engine kind stamps players already online.
 */
class OnlineSet(
    private val clock: Clock = Clock.systemUTC(),
    initial: Map<Session, Instant> = emptyMap(),
) : OnlineSessions {
    override val sessions: MutableStateFlow<Map<Session, Instant>> = MutableStateFlow(initial)

    /** [session] connected to the engine at [connected]. */
    fun join(
        session: Session,
        connected: Instant = clock.instant(),
    ) = sessions.update { it + (session to connected) }

    /** [session] left the engine. */
    fun quit(session: Session) = sessions.update { it - session }
}
