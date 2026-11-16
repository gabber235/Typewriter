package com.typewritermc.playtest.pool

import com.typewritermc.playtest.pool.PaperRules.Do

/**
 * The attempts that run on the pool's Papers, found by id and by player. An attempt ends only through
 * [end], which hands what its Paper's rules answer to the end to the pool while the attempt can still be
 * found, so a restart attempt's own Paper stops whichever way its attempt ends.
 */
internal class Attempts<A : Any> {
    private class Running<A>(
        val attempt: A,
        val players: List<String>,
        val rules: PaperRules,
    )

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
