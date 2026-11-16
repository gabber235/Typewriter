package com.typewritermc.playtest.pool

/**
 * How long the pool runs: while a session of its run is connected. The test JVM that starts the pool
 * opens its session as soon as the pool listens, so a pool that no session reached within [ownerMillis]
 * of [startedAt] lost its owner, as when that test JVM died first. Times are wall clock milliseconds.
 */
internal class Lifetime<S>(
    private val startedAt: Long,
    private val ownerMillis: Long,
) {
    private val connected = mutableSetOf<S>()
    private var reached = false

    /** The sessions connected now. */
    val sessions: Set<S> get() = connected

    /** [session] opened its connection. */
    fun joined(session: S) {
        connected += session
        reached = true
    }

    /** [session] left. */
    fun left(session: S) {
        connected -= session
    }

    /** Whether the pool's run is over by [now]: its last session left, or none came while its owner could open one. */
    fun over(now: Long): Boolean = if (reached) connected.isEmpty() else now >= startedAt + ownerMillis

    /** When [over] turns true by time alone, or null when only a session leaving ends the pool. */
    fun wakeAt(): Long? = if (reached) null else startedAt + ownerMillis
}
