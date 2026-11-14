package com.typewritermc.playtest.pool

/** [players] go to [session]'s [submission] until its attempt ends. */
internal data class Grant<S, P>(
    val session: S,
    val submission: Long,
    val players: List<P>,
)

/**
 * Which waiting attempt gets which of the pool's [players]. Each attempt claims 1 to all of them and
 * gets them together. Sessions (test JVMs) take turns, so one that arrives late is served next instead
 * of behind everything queued before it. The claim whose turn it is holds back every later claim until
 * enough players are free for it, so a group is never starved by smaller claims.
 */
internal class Claims<S, P>(
    private val players: List<P>,
) {
    private class Waiting(
        val submission: Long,
        val count: Int,
    )

    /** A session's waiting claims in submission order, and when it was last served. */
    private class Turn(
        val arrived: Long,
    ) {
        val waiting = ArrayDeque<Waiting>()
        var served = Long.MIN_VALUE
    }

    private val turns = mutableMapOf<S, Turn>()
    private val free = players.toMutableSet()
    private val lost = mutableSetOf<P>()
    private var clock = 0L

    /** [session]'s [submission] waits for [count] players. */
    fun submit(
        session: S,
        submission: Long,
        count: Int,
    ) {
        require(count >= 1) { "a requirement claims at least 1 player, not $count" }
        require(count <= players.size) { "a requirement claims $count players, but the pool holds ${players.size}" }
        turns.getOrPut(session) { Turn(clock++) }.waiting.addLast(Waiting(submission, count))
    }

    /** The attempt holding [released] ended; they are free for the next claim, except players whose client is lost. */
    fun release(released: List<P>) {
        free += released.filterNot { it in lost }
    }

    /** [player]'s client is lost: no claim gets the player until its new client is [restored][restore]. */
    fun lose(player: P) {
        lost += player
        free -= player
    }

    /** [player]'s new client is ready: the player is free again. */
    fun restore(player: P) {
        if (lost.remove(player)) free += player
    }

    /** [session] is gone, and so are its waiting claims. */
    fun leave(session: S) {
        turns.remove(session)
    }

    /**
     * Grants every claim that can run now, in turn order: the session served longest ago goes first, and
     * a session never served before every served one. Stops at the first claim that does not fit.
     */
    fun grants(): List<Grant<S, P>> {
        val granted = mutableListOf<Grant<S, P>>()
        while (true) {
            val (session, turn) =
                turns.entries
                    .filter { it.value.waiting.isNotEmpty() }
                    .minWithOrNull(compareBy({ it.value.served }, { it.value.arrived }))
                    ?: break
            val head = turn.waiting.first()
            if (head.count > free.size) break
            val claimed = players.filter { it in free }.take(head.count)
            free -= claimed.toSet()
            turn.waiting.removeFirst()
            turn.served = clock++
            granted += Grant(session, head.submission, claimed)
        }
        return granted
    }
}
