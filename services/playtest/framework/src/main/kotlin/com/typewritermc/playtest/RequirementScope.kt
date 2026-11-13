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
    private val attempt: Attempt,
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
    suspend fun GamePlayer.typeInChat(text: String): Mark = input(TypeInChatStep(text))

    /** Presses and releases [key]. */
    suspend fun GamePlayer.press(key: Key): Mark = input(KeyStep(key, true), KeyStep(key, false))

    /** Holds [key] down for [ticks] client ticks. */
    suspend fun GamePlayer.hold(
        key: Key,
        ticks: Ticks,
    ): Mark = input(KeyStep(key, true), WaitStep(ticks.count), KeyStep(key, false))

    /** Presses and releases [button]. */
    suspend fun GamePlayer.click(button: Button): Mark = input(ButtonStep(button.number, true), ButtonStep(button.number, false))

    /** Holds [button] down for [ticks] client ticks. */
    suspend fun GamePlayer.hold(
        button: Button,
        ticks: Ticks,
    ): Mark = input(ButtonStep(button.number, true), WaitStep(ticks.count), ButtonStep(button.number, false))

    /** Turns the mouse wheel by [notches]; negative scrolls down, toward the next hotbar slot. */
    suspend fun GamePlayer.scroll(notches: Int): Mark = input(ScrollStep(notches))

    /** Turns the view with the mouse until the crosshair rests on [entity]; fails when it lands elsewhere. */
    suspend fun GamePlayer.aimAt(entity: EntityRef): Mark = input(AimAtEntityStep(entity.uuid))

    /** Turns the view with the mouse until the crosshair rests on [block]; fails when it lands elsewhere. */
    suspend fun GamePlayer.aimAt(block: BlockRef): Mark = input(AimAtBlockStep(attempt.region.world(block.at)))

    /** Moves the pointer over the open screen's slot for the player's inventory [slot] and clicks it. */
    suspend fun GamePlayer.clickInventorySlot(slot: Int): Mark =
        input(PointAtSlotStep(slot), ButtonStep(Button.LEFT.number, true), ButtonStep(Button.LEFT.number, false))

    /**
     * Faces [x], [z] and holds the forward key until the player stands within half a block of it, or
     * [limit] ticks passed.
     */
    suspend fun GamePlayer.walkTo(
        x: Double,
        z: Double,
        limit: Ticks = 80.ticks,
    ): Mark = input(WalkToStep(attempt.region.worldX(x), attempt.region.worldZ(z), limit.count))

    private suspend fun GamePlayer.input(vararg steps: InputStep): Mark = attempt.input(this, steps.toList()).also { anchor = it }

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
        val declared = WindowChecks().apply(checks)
        val rules = Window(mark.tick, window, attempt.nextBarrier(), declared.checks, declared.nevers)
        val checked = (declared.checks + declared.nevers).map { it.player }.distinct()
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
