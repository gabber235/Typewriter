package com.typewritermc.playtest.pool

/**
 * How long the pool runs: while a session of its run is connected, and for [graceMillis] after its
 * last session left, so a module whose tests start later joins this pool instead of booting another.
 * The test JVM that starts the pool opens its session as soon as the pool listens, so a pool that no
 * session reached within [ownerMillis] of [startedAt] lost its owner, as when that test JVM died first.
 * Times are wall clock milliseconds.
 */
internal class Lifetime<S>(
    private val startedAt: Long,
    private val ownerMillis: Long,
    private val graceMillis: Long,
) {
    private val connected = mutableSetOf<S>()
    private var reached = false
    private var lastLeftAt = 0L

    /** The sessions connected now. */
    val sessions: Set<S> get() = connected

    /** [session] opened its connection. */
    fun joined(session: S) {
        connected += session
        reached = true
    }

    /** [session] left [at]. */
    fun left(
        session: S,
        at: Long,
    ) {
        connected -= session
        lastLeftAt = at
    }

    /** Whether the pool's run is over by [now]: no session came while its owner could open one, or none came back within the grace. */
    fun over(now: Long): Boolean = wakeAt()?.let { now >= it } ?: false

    /** When [over] turns true by time alone, or null while a session is connected. */
    fun wakeAt(): Long? =
        when {
            !reached -> startedAt + ownerMillis
            connected.isEmpty() -> lastLeftAt + graceMillis
            else -> null
        }
}
