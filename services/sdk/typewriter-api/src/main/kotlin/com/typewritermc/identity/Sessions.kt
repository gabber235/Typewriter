package com.typewritermc.identity

import kotlinx.coroutines.flow.StateFlow

/**
 * The sessions an engine has right now, as its engine kind sees them: Paper's online players, the panel's open tabs.
 * Each engine kind supplies one, and its engine keeps exactly these: a session added is claimed at once, a session
 * removed is left vacant at once, alive for its engine kind's vacancy so another engine or a rejoin takes it over, and
 * only sessions in the set are refreshed. The set may change on any thread, so a game thread updates it without
 * waiting on the network.
 */
interface OnlineSessions {
    val sessions: StateFlow<Set<Session>>
}

/** Reads which engines hold a protagonist's sessions now, across the Realm. */
interface Sessions {
    /**
     * The engines holding at least one session of [protagonist] now. A vacant session, alive but left by its protagonist
     * and awaiting a takeover, has no holder, so an engine the protagonist left is never listed.
     */
    suspend fun holders(protagonist: Protagonist): Set<EngineId>
}
