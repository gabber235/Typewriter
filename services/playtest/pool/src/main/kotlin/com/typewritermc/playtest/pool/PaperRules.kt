package com.typewritermc.playtest.pool

import skirout.harness.v1.wire.PaperLossKind
import skirout.harness.v1.wire.Region

/**
 * The life of one Paper the pool runs, as the rules the pool follows: what it does next at each thing
 * it hears about that Paper. The shared Paper ([SharedPaper]) serves every attempt that keeps its Paper;
 * a restart attempt's own Paper ([OwnPaper]) serves that one attempt. The pool forwards every event to
 * the rules of the Paper it concerns and does what they answer, so it never asks which kind of Paper
 * it talks to.
 */
internal interface PaperRules {
    /** How long one boot of this Paper may take, from its start until it serves attempts. */
    val bootSeconds: Long

    /** An attempt of the pool is [attempt] on this Paper from now on: the region it gets, and what follows. */
    fun claim(attempt: Long): Claiming

    /** The plugin of the Paper booted last connected to the pool: Paper is done starting. */
    fun connected(): List<Do>

    /** The Paper's pool connection closed. */
    fun closed(): List<Do>

    /** [player]'s client is in this Paper's world. */
    fun joined(player: String): List<Do>

    /** [player]'s client steps with this Paper. */
    fun ready(player: String): List<Do>

    /** [player]'s client comes to this Paper anew: it joins and steps again before it counts. */
    fun arriving(player: String): List<Do>

    /** [player]'s client lost this Paper for [reason] without being told to leave, while the Paper's process is [paperAlive] or not. */
    fun dropped(
        player: String,
        reason: String,
        paperAlive: Boolean,
    ): List<Do>

    /** Paper resumed its attempt after a restart; its players' clients hold all it sends from after [tick] on. */
    fun resumed(tick: Int): List<Do>

    /** An attempt asks, as [request], for its Paper to be killed and booted again. */
    fun restart(request: Long): List<Do>

    /** Paper could not do what an attempt needs, as [kind] says (it could not claim or resume), for [cause]. */
    fun failed(
        kind: PaperLossKind,
        cause: String,
    ): List<Do>

    /** [attempt] on this Paper ended, for [why]; every way an attempt ends comes here, once. */
    fun ended(
        attempt: Long,
        why: String,
    ): List<Do>

    /** The Paper process ended with [code]. */
    fun exited(code: Int): List<Do>

    /** The limit for boot [boot] ran out; boots count from 1. */
    fun bootTimedOut(boot: Int): List<Do>

    /** Where a claimed attempt stands on its Paper, and what the pool does next. */
    data class Claiming(
        val region: Region,
        val todo: List<Do>,
    )

    /** What the pool does next for a Paper, by what it touches. */
    sealed interface Do {
        /** A message to the Paper. */
        sealed interface ToPaper : Do

        /** The players' clients and claims. */
        sealed interface ToPlayers : Do

        /** The Paper's process, and the attempt it serves alone, which each step names. */
        sealed interface Life : Do

        /** The pool's game as a whole. */
        sealed interface ToGame : Do

        /** Starts boot [number] of the Paper process on its folder and port; again after a kill. */
        data class Boot(
            val number: Int,
        ) : Life

        /** Paper hears the regions the next claims on it get, so it loads their ground ahead. */
        data class RegionsAhead(
            val regions: List<Region>,
        ) : ToPaper

        /** [attempt] takes its players from the shared Paper; they serve no other claim meanwhile. */
        data class Gather(
            val attempt: Long,
        ) : ToPlayers

        /** Tells each client on this Paper to join it. */
        data object Connect : ToPlayers

        /** Paper runs a tick only when its step policy grants it, from now on. */
        data object Step : ToPaper

        /** Paper claims [attempt]'s players: wiped, in its region, then leased. */
        data class Claim(
            val attempt: Long,
        ) : ToPaper

        /** Back after a kill, [attempt]'s players belong to it again, unwiped and where Paper put them. */
        data class Resume(
            val attempt: Long,
        ) : ToPaper

        /** [player] serves claims again. */
        data class Free(
            val player: String,
        ) : ToPlayers

        /** Every client stepped with the shared Paper once: the game booted, and the pool lends players. */
        data object Booted : ToGame

        /** [player]'s client dropped off this Paper without being told to leave, for [cause]: it is lost, its attempt fails and a new client starts. */
        data class Lose(
            val player: String,
            val cause: String,
        ) : ToPlayers

        /** [player]'s records so far show a Paper that is gone; the next ones show the new one. */
        data class Forget(
            val player: String,
        ) : ToPlayers

        /** Ends the Paper process of [attempt] at once, as a crash would, so it saves nothing. */
        data class Kill(
            val attempt: Long,
        ) : Life

        /** Answers [attempt]'s restart [request]: every player is back after [tick] of the new Paper. */
        data class Restarted(
            val attempt: Long,
            val request: Long,
            val tick: Int,
        ) : Life

        /** The Paper is lost, as [kind] says, for [cause]: [attempt] fails, the process ends, the players go back to the shared Paper. */
        data class Lost(
            val attempt: Long,
            val kind: PaperLossKind,
            val cause: String,
        ) : Life

        /** The game cannot run for [cause]: every session hears why and the game stops. */
        data class Fail(
            val cause: String,
        ) : ToGame

        /** [attempt] ended: its players go back to the shared Paper and this Paper stops. */
        data class Return(
            val attempt: Long,
        ) : Life

        /** The Paper's process ended for good: the pool forgets the Paper and removes its folder unless it was lost. */
        data object Gone : Life

        /** Nothing to do but note [text] in the pool's log. */
        data class Note(
            val text: String,
        ) : ToGame
    }
}
