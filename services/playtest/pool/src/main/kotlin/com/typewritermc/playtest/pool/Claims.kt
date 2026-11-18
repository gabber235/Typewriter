package com.typewritermc.playtest.pool

import com.typewritermc.playtest.launch.HeapShare

/** Why a player sits out of every claim. */
internal enum class Out {
    /** Its client is lost and the new one is not ready yet. */
    LOST_CLIENT,

    /** Work that hung on it still runs. */
    HUNG_WORK,

    /** Its client is on a restart attempt's own Paper, or on its way back to the shared one. */
    AWAY,
}

/** Submission [submission] waits for [players] players, and for a Paper of its own when it [restarts] Paper. */
internal data class Claim(
    val submission: Long,
    val players: Int,
    val restarts: Boolean = false,
)

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
 * and nothing holds it [out][holdOut]. A claim that restarts Paper also waits until fewer than
 * [ownPapers] own Papers have not fully exited, as more would outgrow the memory their shares assume.
 */
internal class Claims<S, P>(
    private val players: List<P>,
    private val ownPapers: Int = HeapShare.OWN_PAPERS,
) {
    /** Submissions that wait together, each for its count of players. */
    private class Waiting(
        val together: List<Claim>,
    ) {
        val count = together.sumOf { it.players }
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
    private var ownPapersAlive = 0
    private val out = mutableMapOf<P, MutableSet<Out>>()
    private var clock = 0L

    /** [session]'s claims in [together], each waiting for its players, all granted at the same moment. */
    fun submit(
        session: S,
        vararg together: Claim,
    ) {
        require(together.isNotEmpty()) { "a submission names at least 1 attempt" }
        for (claim in together) require(claim.players >= 1) { "a requirement claims at least 1 player, not ${claim.players}" }
        val restarts = together.count { it.restarts }
        require(restarts <= ownPapers) {
            "attempts side by side need $restarts Papers of their own, but the pool runs at most $ownPapers at once"
        }
        val count = together.sumOf { it.players }
        require(count <= players.size) { "a requirement claims $count players, but the pool holds ${players.size}" }
        turns.getOrPut(session) { Turn(clock++) }.waiting.addLast(Waiting(together.toList()))
    }

    /** The attempt holding [released] ended; they are free for the next claim unless something holds them out. */
    fun release(released: List<P>) {
        claimed -= released.toSet()
    }

    /** An own Paper a granted claim started ended for good; until then it counts, even while it stops. */
    fun ownPaperGone() {
        check(ownPapersAlive > 0) { "no own Paper of a claim is alive" }
        ownPapersAlive--
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
            val restarts = head.together.count { it.restarts }
            if (head.count > free.size || ownPapersAlive + restarts > ownPapers) break
            var next = 0
            for (claim in head.together) {
                val taken = free.subList(next, next + claim.players)
                next += claim.players
                claimed += taken
                granted += Grant(session, claim.submission, taken.toList())
            }
            ownPapersAlive += restarts
            turn.waiting.removeFirst()
            turn.served = clock++
        }
        return granted
    }
}
