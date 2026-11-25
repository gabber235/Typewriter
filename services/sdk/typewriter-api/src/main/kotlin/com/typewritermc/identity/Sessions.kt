package com.typewritermc.identity

/**
 * How an engine kind tells its engine which sessions it holds. Paper reports a player's join and quit; the panel
 * engine reports each tab's heartbeat and its leave. Calls never wait on the network, so a game thread can make them.
 */
interface SessionReporter {
    /** [protagonist] connected to this engine as session [id], or this engine took the session over. */
    fun connected(
        protagonist: Protagonist,
        id: SessionId,
    )

    /**
     * Session [id] left this engine. Nobody holds it from then on; it stays alive, vacant, for its engine kind's vacancy
     * and ends unless an engine takes it over.
     */
    fun disconnected(id: SessionId)
}

/** Reads which engines hold a protagonist's sessions now, across the Realm. */
interface Sessions {
    /**
     * The engines holding at least one session of [protagonist] now. A vacant session, alive but left by its protagonist
     * and awaiting a takeover, has no holder, so an engine the protagonist left is never listed.
     */
    suspend fun holders(protagonist: Protagonist): Set<EngineId>
}
