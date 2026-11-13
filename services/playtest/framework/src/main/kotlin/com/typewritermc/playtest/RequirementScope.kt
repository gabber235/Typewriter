package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.StepUntil
import com.typewritermc.playtest.wire.Message.StopStepping

/**
 * What a requirement's body sees during one attempt: its leased [players], the Paper [probe], and
 * [within] for every check. Every window counts from the last stimulus.
 */
class RequirementScope internal constructor(
    val players: List<GamePlayer>,
    private val attempt: Attempt,
) {
    /** The attempt's only player, for requirements that lease one. */
    val player: GamePlayer get() = players.single()

    /** Stimuli that run inside Paper, between ticks. */
    val probe: Probe = Probe()

    private var anchor: Mark? = null

    /** The framework's Paper probe; each call becomes the anchor of the windows after it. */
    inner class Probe internal constructor() {
        /** Paper sends [text] to [to] as a chat line. */
        suspend fun chat(
            to: GamePlayer,
            text: String,
        ): Mark = attempt.probeChat(to, text).also { anchor = it }
    }

    /**
     * Passes once every check of [checks] held in a tick of the window, the [window] ticks after the
     * last stimulus. Fails with [WindowMissed] once those ticks ran and a check never held. Ticks run
     * only while a window waits, so a pass costs no more ticks than the truth needs.
     */
    suspend fun within(
        window: Ticks,
        checks: WindowChecks.() -> Unit,
    ) {
        val at = attempt.requirementLine(Throwable().stackTrace)
        val mark = checkNotNull(anchor) { "within needs a stimulus before it; its window counts from the last one" }
        val declared = WindowChecks().apply(checks).checks
        val rules = Window(mark.tick, window, attempt.nextBarrier(), declared)
        val checked = declared.map { it.player }.distinct()
        // What the players perceived since the attempt began counts too: a window opened late still
        // sees the records of every tick after its stimulus.
        var verdict: Window.Verdict = Window.Verdict.Open
        attempt.timeline.forEach { verdict = rules.judge(it) }
        if (verdict == Window.Verdict.Open) {
            checked.forEach { attempt.send(StepUntil(it.uuid, rules.end, rules.barrier)) }
            while (verdict == Window.Verdict.Open) verdict = rules.judge(attempt.nextEvent())
            checked.forEach { attempt.send(StopStepping(it.uuid)) }
        }
        val missed = verdict as? Window.Verdict.Missed ?: return
        throw WindowMissed(missed.report, at)
    }

    private fun Window.judge(event: Attempt.Event): Window.Verdict =
        when (event) {
            is Attempt.Event.Perceived -> perceived(event.player, event.perception)
            is Attempt.Event.Barrier -> barrierSeen(event.player, event.id)
        }
}

/** The checks one window declares. */
class WindowChecks internal constructor() {
    internal val checks = mutableListOf<Check>()

    /** The player perceives [fact] in some tick of the window. */
    infix fun GamePlayer.sees(fact: Perceivable) {
        checks += Check(this, fact)
    }
}
