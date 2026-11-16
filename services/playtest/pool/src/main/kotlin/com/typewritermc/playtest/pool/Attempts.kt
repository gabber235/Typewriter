package com.typewritermc.playtest.pool

import com.typewritermc.playtest.pool.PaperRules.Do

/**
 * The attempts that run on the pool's Papers, found by id and by player. An attempt ends only through
 * [end], which hands what its Paper's rules answer to the end to the pool while the attempt can still be
 * found, so a restart attempt's own Paper stops whichever way its attempt ends. A leased attempt holds
 * its players until a deadline, so a session that never sends its result cannot keep them for good.
 */
internal class Attempts<A : Any> {
    private class Running<A>(
        val attempt: A,
        val players: List<String>,
        val rules: PaperRules,
    ) {
        /** When its lease runs out, once it holds one. */
        var deadline: Long? = null
    }

    private val running = linkedMapOf<Long, Running<A>>()

    /** The attempts that run now, in the order they started. */
    val all: List<A> get() = running.values.map { it.attempt }

    /** The attempt [id], while it runs. */
    operator fun get(id: Long): A? = running[id]?.attempt

    /** The attempt [player] plays in now. */
    fun of(player: String): A? = running.values.firstOrNull { player in it.players }?.attempt

    /** [attempt], as [id], runs from now on with [players] on the Paper that follows [rules]. */
    fun start(
        id: Long,
        attempt: A,
        players: List<String>,
        rules: PaperRules,
    ) {
        running[id] = Running(attempt, players, rules)
    }

    /** The attempt [id] got its lease, which runs out at [until], in wall clock milliseconds. */
    fun leased(
        id: Long,
        until: Long,
    ) {
        running[id]?.deadline = until
    }

    /** The earliest moment a running attempt's lease runs out, or null when no running attempt holds one. */
    fun nextDeadline(): Long? = running.values.mapNotNull { it.deadline }.minOrNull()

    /** The running attempts whose lease ran out by [now]. */
    fun overdue(now: Long): List<A> = running.values.filter { it.deadline?.let { deadline -> deadline <= now } == true }.map { it.attempt }

    /** The attempt [id] ended for [why]: [act] does what its Paper's rules answer, then the attempt is gone. */
    fun end(
        id: Long,
        why: String,
        act: (List<Do>) -> Unit,
    ) {
        val ending = running[id] ?: return
        act(ending.rules.ended(id, why))
        running.remove(id)
    }
}
