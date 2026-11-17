package com.typewritermc.playtest.pool

/**
 * What the pool handed on for its sessions under pool wide ids, so each answer finds the session [S]
 * that asked, under that session's own id [T]. A session that left gets no answers, and what it asked
 * leaves no trace.
 */
internal class Routes<S, T> {
    /** [id], what [session] calls the request the pool handed on. */
    class Routed<S, T>(
        val session: S,
        val id: T,
    )

    private val routed = mutableMapOf<Long, Routed<S, T>>()
    private var next = 0L

    /** Remembers that [session] asked under [id]; returns the pool wide id to hand the request on under. */
    fun route(
        session: S,
        id: T,
    ): Long {
        routed[++next] = Routed(session, id)
        return next
    }

    /** Who asked what the pool handed on as [pool], once. */
    fun answer(pool: Long): Routed<S, T>? = routed.remove(pool)

    /** [session] left: its requests get no answers. */
    fun leave(session: S) {
        routed.values.removeIf { it.session == session }
    }
}
