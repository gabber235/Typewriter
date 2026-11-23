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

    /** Session [id] left this engine; it ends after its engine kind's grace unless an engine takes it again. */
    fun disconnected(id: SessionId)
}

/** Reads which engines hold an identity now, across the Realm. */
interface Sessions {
    /**
     * The engines that hold [subject]: every engine holding a live session of a protagonist, the engine holding a
     * session, and an engine itself. Empty while the subject is offline.
     */
    suspend fun holders(subject: Identity): Set<EngineId>
}
