package com.typewritermc.playtest.pool

/** Why a player sits out of every claim. */
internal enum class Out {
    /** Its client is lost and the new one is not ready yet. */
    LOST_CLIENT,

    /** Work that hung on it still runs. */
    HUNG_WORK,
}

/** [players] go to [session]'s [submission] until its attempt ends. */
internal data class Grant<S, P>(
    val session: S,
    val submission: Long,
    val players: List<P>,
)

/**
 * Which waiting attempt gets which of the pool's [players]. Each attempt claims 1 to all of them and
 * gets them together; attempts submitted together, side by side, all get theirs at the same moment.
 * Sessions (test JVMs) take turns, so one that arrives late is served next instead of behind everything
 * queued before it. The claim whose turn it is holds back every later claim until enough players are
 * free for it, so a group is never starved by smaller claims. A player is free once no attempt holds it
 * and nothing holds it [out][holdOut].
 */
internal class Claims<S, P>(
    private val players: List<P>,
) {
    /** Submissions that wait together, each for its count of players. */
    private class Waiting(
        val together: List<Pair<Long, Int>>,
    ) {
        val count = together.sumOf { it.second }
    }

    /** A session's waiting claims in submission order, and when it was last served. */
    private class Turn(
        val arrived: Long,
    ) {
        val waiting = ArrayDeque<Waiting>()
        var served = Long.MIN_VALUE
    }

    private val turns = mutableMapOf<S, Turn>()
    private val claimed = mutableSetOf<P>()
    private val out = mutableMapOf<P, MutableSet<Out>>()
    private var clock = 0L

    /** [session]'s submissions in [together], each waiting for its count of players, all granted at the same moment. */
    fun submit(
        session: S,
        vararg together: Pair<Long, Int>,
    ) {
        require(together.isNotEmpty()) { "a submission names at least 1 attempt" }
        for ((_, count) in together) require(count >= 1) { "a requirement claims at least 1 player, not $count" }
        val count = together.sumOf { it.second }
        require(count <= players.size) { "a requirement claims $count players, but the pool holds ${players.size}" }
        turns.getOrPut(session) { Turn(clock++) }.waiting.addLast(Waiting(together.toList()))
    }

    /** The attempt holding [released] ended; they are free for the next claim unless something holds them out. */
    fun release(released: List<P>) {
        claimed -= released.toSet()
    }

    /** [player] sits out of every claim for [why] until [letBack] for it; an attempt holding it keeps it. */
    fun holdOut(
        player: P,
        why: Out,
    ) {
        out.getOrPut(player) { mutableSetOf() } += why
    }

    /** [player] no longer sits out for [why]. */
    fun letBack(
        player: P,
        why: Out,
    ) {
        val reasons = out[player] ?: return
        reasons -= why
        if (reasons.isEmpty()) out -= player
    }

    /** Whether something holds [player] out of every claim. */
    fun isOut(player: P): Boolean = player in out

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
            val free = players.filter { it !in claimed && it !in out }
            if (head.count > free.size) break
            var next = 0
            for ((submission, count) in head.together) {
                val taken = free.subList(next, next + count)
                next += count
                claimed += taken
                granted += Grant(session, submission, taken.toList())
            }
            turn.waiting.removeFirst()
            turn.served = clock++
        }
        return granted
    }
}
