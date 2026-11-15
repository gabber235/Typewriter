package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.AimAtBlockStep
import com.typewritermc.playtest.wire.Message.AimAtEntityStep
import com.typewritermc.playtest.wire.Message.ButtonStep
import com.typewritermc.playtest.wire.Message.InputStep
import com.typewritermc.playtest.wire.Message.KeyStep
import com.typewritermc.playtest.wire.Message.PointAtSlotStep
import com.typewritermc.playtest.wire.Message.ScrollStep
import com.typewritermc.playtest.wire.Message.StepUntil
import com.typewritermc.playtest.wire.Message.StopStepping
import com.typewritermc.playtest.wire.Message.TypeInChatStep
import com.typewritermc.playtest.wire.Message.WaitStep
import com.typewritermc.playtest.wire.Message.WalkToStep

/** A key a requirement presses, named as the default key bindings name it. */
typealias Key = Message.Key

/** A mouse button. */
enum class Button(
    internal val number: Int,
) {
    LEFT(1),
    MIDDLE(2),
    RIGHT(3),
}

/**
 * What a requirement's body sees during one attempt: its leased [players], the Paper [probe], the
 * players' hands, and [within] for every check. Every window counts from the last stimulus: a probe
 * call, or an input from the tick it reached the client. Every position counts from the middle of the
 * attempt's region, where the players stand when the body starts: `BlockPos(0, 101, 2)` is two blocks
 * south of it, whichever part of the world the region lies in.
 */
class RequirementScope internal constructor(
    internal val attempt: Attempt,
) {
    /** The players the attempt claimed, in a fixed order: `val (member, partner, outsider) = players`. */
    val players: List<GamePlayer> = attempt.players

    /** The attempt's only player, for requirements that lease one. */
    val player: GamePlayer get() = players.single()

    private var anchor: Mark? = null

    /** Arrangements and stimuli that run inside Paper, between ticks. */
    val probe: Probe = Probe(attempt) { anchor = it }

    /**
     * Opens the chat with its key when it is closed and types [text], as one burst of keys between two
     * ticks. While the chat stays open with that text, a suggestion request that got no answer for 6
     * ticks makes the client retype the last character, as a person does when no list shows.
     */
    suspend fun GamePlayer.typeInChat(text: String): Mark = input("types \"$text\" in chat", TypeInChatStep(text))

    /** Presses and releases [key]. */
    suspend fun GamePlayer.press(key: Key): Mark = input("presses $key", KeyStep(key, true), KeyStep(key, false))

    /** Holds [key] down for [ticks] client ticks. */
    suspend fun GamePlayer.hold(
        key: Key,
        ticks: Ticks,
    ): Mark = input("holds $key for ${ticks.count} ticks", KeyStep(key, true), WaitStep(ticks.count), KeyStep(key, false))

    /** Presses and releases [button]. */
    suspend fun GamePlayer.click(button: Button): Mark =
        input("clicks $button", ButtonStep(button.number, true), ButtonStep(button.number, false))

    /** Holds [button] down for [ticks] client ticks. */
    suspend fun GamePlayer.hold(
        button: Button,
        ticks: Ticks,
    ): Mark =
        input(
            "holds $button for ${ticks.count} ticks",
            ButtonStep(button.number, true),
            WaitStep(ticks.count),
            ButtonStep(button.number, false),
        )

    /** Turns the mouse wheel by [notches]; negative scrolls down, toward the next hotbar slot. */
    suspend fun GamePlayer.scroll(notches: Int): Mark = input("scrolls $notches notches", ScrollStep(notches))

    /** Turns the view with the mouse until the crosshair rests on [entity]; fails when it lands elsewhere. */
    suspend fun GamePlayer.aimAt(entity: EntityRef): Mark = input("aims at entity ${entity.uuid}", AimAtEntityStep(entity.uuid))

    /** Turns the view with the mouse until the crosshair rests on [block]; fails when it lands elsewhere. */
    suspend fun GamePlayer.aimAt(block: BlockRef): Mark = input("aims at block ${block.at}", AimAtBlockStep(attempt.region.world(block.at)))

    /** Moves the pointer over the open screen's slot for the player's inventory [slot] and clicks it. */
    suspend fun GamePlayer.clickInventorySlot(slot: Int): Mark =
        input(
            "clicks inventory slot $slot",
            PointAtSlotStep(slot),
            ButtonStep(Button.LEFT.number, true),
            ButtonStep(Button.LEFT.number, false),
        )

    /**
     * Faces [x], [z] and holds the forward key until the player stands within half a block of it, or
     * [limit] ticks passed.
     */
    suspend fun GamePlayer.walkTo(
        x: Double,
        z: Double,
        limit: Ticks = 80.ticks,
    ): Mark = input("walks to $x, $z", WalkToStep(attempt.region.worldX(x), attempt.region.worldZ(z), limit.count))

    /**
     * Kills the attempt's Paper as a crash would, so it saves nothing, boots it again on the same world,
     * and returns once every player's client is back and holds what Paper sends it. Each player is where
     * Paper put it on its join, with what Paper loaded for it: what was saved survives, the rest is gone.
     * The mark is the tick of the new Paper after which they are back; windows count from it, and nothing
     * perceived before the kill counts for them. Fails with [PaperLost] when the Paper does not come back.
     * Only a requirement declared with `restartsPaper = true` runs on a Paper it may kill.
     */
    suspend fun restartPaper(): Mark = attempt.restart().also { anchor = it }

    /**
     * The frame the player's client holds now is the golden [name], to the pixel. It is compared only
     * on the pinned renderer, where a frame that differs, or a golden another renderer drew, fails; any
     * other machine notes it as not checked. Ask once a window let the scene settle, of a scene where
     * nothing moves from tick to tick. `cargo xtask goldens approve` approves the frames the pinned
     * renderer drew in a run.
     */
    suspend fun GamePlayer.looksLike(name: String) = attempt.golden(this, name)

    private suspend fun GamePlayer.input(
        says: String,
        vararg steps: InputStep,
    ): Mark = attempt.input(this, steps.toList(), says).also { anchor = it }

    /**
     * Passes once every check of [checks] held in a tick of the window, the [window] ticks after the
     * last stimulus. Fails with [WindowMissed] once those ticks ran and a check never held, and with
     * [WorkHung] or [ClientLost] as soon as work a plugin counted for a player of the attempt hangs or
     * a player's client is lost. Ticks run only
     * while a window waits, so a pass costs no more ticks than the truth needs.
     */
    suspend fun within(
        window: Ticks,
        checks: WindowChecks.() -> Unit,
    ) {
        attempt.called()
        val at = attempt.requirementLine(Throwable().stackTrace)
        val mark = anchor ?: throw RequirementRefused("within needs a stimulus before it; its window counts from the last one")
        val declared = WindowChecks().apply(checks)
        val rules = Window(mark.tick, window, attempt.nextBarrier(), declared.checks, declared.nevers)
        val checked = (declared.checks + declared.nevers).map { it.player }.distinct()
        val opened = System.currentTimeMillis()
        val ranBefore = attempt.ranUntil
        // What the players perceived since the attempt began counts too: a window opened late still
        // sees the records of every tick after its stimulus.
        var verdict: Window.Verdict = Window.Verdict.Open
        // Only a check that reads pixels makes its player's client draw: from the look on, each record
        // counts them, and the look ends with the window.
        val looks =
            (declared.checks + declared.nevers)
                .groupBy({ it.player }, { it.fact.pixelsOf })
                .mapValues { (_, entities) -> entities.flatten().distinct() }
                .filterValues { it.isNotEmpty() }
        try {
            looks.forEach { (player, entities) -> attempt.look(player, entities) }
            attempt.timeline.filter { it !is Attempt.Event.Failed }.forEach { verdict = rules.judge(it) }
            if (verdict == Window.Verdict.Open) verdict = rules.stepUntilDecided(checked)
            looks.keys.forEach { attempt.look(it, listOf()) }
        } finally {
            attempt.took(opened, says(window, verdict, mark, ranBefore, declared))
        }
        val missed = verdict as? Window.Verdict.Missed ?: return
        throw WindowMissed(missed.report, at)
    }

    /**
     * The window's step: how it ended, at which of its ticks, how many ticks Paper ran for it beyond
     * those the attempt already knew had run, and its checks.
     */
    private fun says(
        window: Ticks,
        verdict: Window.Verdict,
        mark: Mark,
        ranBefore: Int,
        declared: WindowChecks,
    ): String {
        val decided =
            when (verdict) {
                is Window.Verdict.Passed -> verdict.tick
                is Window.Verdict.Missed -> verdict.tick
                Window.Verdict.Open -> attempt.ranUntil
            }
        attempt.ran(decided)
        val how =
            when (verdict) {
                is Window.Verdict.Passed -> "held at tick ${decided - mark.tick}"
                is Window.Verdict.Missed -> "missed at tick ${decided - mark.tick}"
                Window.Verdict.Open -> "ended by a failure at tick ${decided - mark.tick}"
            }
        val checks =
            declared.checks.map { "${it.player.name} sees ${it.fact.description}" } +
                declared.nevers.map { "${it.player.name} never sees ${it.fact.description}" }
        return "window of ${window.count} ticks $how, stepped ${maxOf(0, decided - maxOf(ranBefore, mark.tick))}: ${checks.joinToString()}"
    }

    /** Paper runs the window's ticks for [checked] until the window decides, then stops running them. */
    private suspend fun Window.stepUntilDecided(checked: List<GamePlayer>): Window.Verdict {
        checked.forEach { attempt.send(StepUntil(it.uuid, end, barrier)) }
        try {
            var verdict: Window.Verdict = Window.Verdict.Open
            while (verdict == Window.Verdict.Open) {
                val event = attempt.nextEvent()
                // Hung work or a lost client fails the attempt at once, whatever the window would decide.
                if (event is Attempt.Event.Failed) throw event.failure
                verdict = judge(event)
            }
            return verdict
        } finally {
            checked.forEach { attempt.send(StopStepping(it.uuid)) }
        }
    }

    private fun Window.judge(event: Attempt.Event): Window.Verdict =
        when (event) {
            is Attempt.Event.Perceived -> perceived(event.player, event.perception)
            is Attempt.Event.Barrier -> barrierSeen(event.player, event.id)
            is Attempt.Event.Failed -> error("a failure of the attempt is thrown where the body takes it; no window judges it")
        }
}

/** The checks one window declares. */
class WindowChecks internal constructor() {
    internal val checks = mutableListOf<Check>()
    internal val nevers = mutableListOf<Check>()

    /** The player perceives [fact] in some tick of the window. */
    infix fun GamePlayer.sees(fact: Perceivable) {
        checks += Check(this, fact)
    }

    /**
     * The player perceives a fact in no tick of the window: `outsider.never sees anyChat()`. The window
     * then runs all its ticks, and still needs a positive check.
     */
    val GamePlayer.never: Absence get() = Absence(this, nevers)
}

/** A player that must not perceive a fact in a window; see [WindowChecks.never]. */
class Absence internal constructor(
    private val player: GamePlayer,
    private val nevers: MutableList<Check>,
) {
    /** The player perceives [fact] in no tick of the window. */
    infix fun sees(fact: Perceivable) {
        nevers += Check(player, fact)
    }
}
