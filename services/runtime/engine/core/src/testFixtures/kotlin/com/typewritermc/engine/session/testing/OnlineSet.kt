package com.typewritermc.engine.session.testing

import com.typewritermc.identity.OnlineSessions
import com.typewritermc.identity.Session
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.update

/** The sessions of a test engine, which a test changes as its engine kind would: [join] and [quit] change the set at once. */
class OnlineSet(
    initial: Set<Session> = emptySet(),
) : OnlineSessions {
    override val sessions: MutableStateFlow<Set<Session>> = MutableStateFlow(initial)

    /** [session] connected to the engine. */
    fun join(session: Session) = sessions.update { it + session }

    /** [session] left the engine. */
    fun quit(session: Session) = sessions.update { it - session }
}
