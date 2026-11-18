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

/** Reads which engines hold a protagonist's sessions now, across the Realm. */
interface Sessions {
    /** The engines that hold at least one live session of [protagonist]; empty while it is offline. */
    suspend fun holders(protagonist: Protagonist): Set<EngineId>
}
