package com.typewritermc.playtest

import com.typewritermc.playtest.wire.variantName
import skirout.harness.v1.wire.InputStep
import skirout.harness.v1.wire.KeyboardKey
import skirout.harness.v1.wire.Message

/** A key as a step names it: `E`, `LEFT_SHIFT`. */
private val KeyboardKey.said: String get() = variantName(KeyboardKey.typeDescriptor, this).uppercase()

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
     * Opens the chat with its key when it is closed and types [text] one character per tick, as a person
     * types: typing takes a tick for each character, and Paper answers each suggestion request before
     * the next tick.
     */
    suspend fun GamePlayer.typeInChat(text: String): Mark = input("types \"$text\" in chat", InputStep.createTypeInChat(text = text))

    /** Presses and releases [key]. */
    suspend fun GamePlayer.press(key: KeyboardKey): Mark =
        input("presses ${key.said}", keyStep(key, down = true), keyStep(key, down = false))

    /** Holds [key] down for [ticks] client ticks. */
    suspend fun GamePlayer.hold(
        key: KeyboardKey,
        ticks: Ticks,
    ): Mark = input("holds ${key.said} for ${ticks.count} ticks", keyStep(key, down = true), waitStep(ticks), keyStep(key, down = false))

    /** Presses and releases [button]. */
    suspend fun GamePlayer.click(button: Button): Mark =
        input("clicks $button", buttonStep(button, down = true), buttonStep(button, down = false))

    /** Holds [button] down for [ticks] client ticks. */
    suspend fun GamePlayer.hold(
        button: Button,
        ticks: Ticks,
    ): Mark =
        input(
            "holds $button for ${ticks.count} ticks",
            buttonStep(button, down = true),
            waitStep(ticks),
            buttonStep(button, down = false),
        )

    /** Turns the mouse wheel by [notches]; negative scrolls down, toward the next hotbar slot. */
    suspend fun GamePlayer.scroll(notches: Int): Mark = input("scrolls $notches notches", InputStep.createScroll(amount = notches))

    /** Turns the view with the mouse until the crosshair rests on [entity]; fails when it lands elsewhere. */
    suspend fun GamePlayer.aimAt(entity: EntityRef): Mark =
        input("aims at entity ${entity.uuid}", InputStep.createAimAtEntity(entity = entity.uuid.toString()))

    /** Turns the view with the mouse until the crosshair rests on [block]; fails when it lands elsewhere. */
    suspend fun GamePlayer.aimAt(block: BlockRef): Mark =
        input("aims at block ${block.at}", InputStep.createAimAtBlock(block = attempt.region.world(block.at)))

    /** Moves the pointer over the open screen's slot for the player's inventory [slot] and clicks it. */
    suspend fun GamePlayer.clickInventorySlot(slot: Int): Mark =
        input(
            "clicks inventory slot $slot",
            InputStep.createPointAtSlot(slot = slot),
            buttonStep(Button.LEFT, down = true),
            buttonStep(Button.LEFT, down = false),
        )

    /**
     * Faces [x], [z] and holds the forward key until the player stands within half a block of it, or
     * [limit] ticks passed.
     */
    suspend fun GamePlayer.walkTo(
        x: Double,
        z: Double,
        limit: Ticks = 80.ticks,
    ): Mark =
        input(
            "walks to $x, $z",
            InputStep.createWalkTo(x = attempt.region.worldX(x), z = attempt.region.worldZ(z), maxTicks = limit.count),
        )

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
     * on the pinned renderer, where a frame that differs, a golden never approved, or one another
     * renderer drew fails; any other machine notes it as not checked. Ask once a window let the scene
     * settle, of a scene where nothing moves from tick to tick. `cargo xtask goldens approve --pr <n>` approves the frames a
     * pull request's CI run drew on the pinned renderer; without `--pr`, the last local run's.
     */
    suspend fun GamePlayer.looksLike(name: String) = attempt.golden(this, name)

    private suspend fun GamePlayer.input(
        says: String,
        vararg steps: InputStep,
    ): Mark = attempt.input(this, steps.toList(), says).also { anchor = it }

    private fun keyStep(
        key: KeyboardKey,
        down: Boolean,
    ): InputStep = InputStep.createKey(key = key, down = down)

    private fun buttonStep(
        button: Button,
        down: Boolean,
    ): InputStep = InputStep.createButton(button = button.number, down = down)

    private fun waitStep(ticks: Ticks): InputStep = InputStep.createWait(ticks = ticks.count)

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
        // A window of state checks alone steps every player of the attempt, so its ticks run for them.
        val checked = (declared.checks + declared.nevers).map { it.player }.distinct().ifEmpty { attempt.players }
        val rules =
            Window(
                mark.tick,
                window,
                attempt.nextBarrier(),
                declared.checks,
                declared.nevers,
                declared.states,
                declared.neverStates,
                checked,
            )
        val opened = System.currentTimeMillis()
        val ranBefore = attempt.ranUntil
        // What the players perceived since the attempt began counts too: a window opened late still
        // sees the records of every tick after its stimulus.
        var verdict: Window.Verdict = Window.Verdict.Open
        try {
            attempt.timeline.filter { it !is Attempt.Event.Failed }.forEach { verdict = rules.judge(it) }
            if (verdict == Window.Verdict.Open) verdict = rules.stepUntilDecided(checked)
        } finally {
            attempt.took(opened, says(window, verdict, mark, ranBefore, declared))
        }
        val missed = verdict as? Window.Verdict.Missed ?: return run { attempt.proved = true }
        throw attempt.observed(WindowMissed(missed.report, at))
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
                declared.nevers.map { "${it.player.name} never sees ${it.fact.description}" } +
                declared.states.map { "state ${it.description}" } +
                declared.neverStates.map { "never state ${it.description}" }
        return "window of ${window.count} ticks $how, stepped ${maxOf(0, decided - maxOf(ranBefore, mark.tick))}: ${checks.joinToString()}"
    }

    /** Paper runs the window's ticks for [checked] until the window decides, then stops running them. */
    private suspend fun Window.stepUntilDecided(checked: List<GamePlayer>): Window.Verdict {
        try {
            var verdict = if (readsStates) stepTickByTick(checked) else Window.Verdict.Open
            if (verdict != Window.Verdict.Open) return verdict
            checked.forEach { stepUntil(it, end, barrier) }
            while (verdict == Window.Verdict.Open) verdict = judge(nextEvent())
            return verdict
        } finally {
            checked.forEach { attempt.send(Message.createStopStepping(player = it.uuid.toString())) }
        }
    }

    /**
     * Runs the window one tick at a time while it reads state checks: each tick ends with a barrier of its
     * own, after every record of it, and then the window's state checks are read. The last tick's barrier
     * is the window's, handed to it only after that tick's reads. Returns once the window decided, or open
     * once it reads no more state checks or its last tick's barrier is still to come.
     */
    private suspend fun Window.stepTickByTick(checked: List<GamePlayer>): Window.Verdict {
        var verdict: Window.Verdict = Window.Verdict.Open
        for (tick in this.anchor + 1..end) {
            if (!readsStates) return verdict
            val last = tick == end
            val id = if (last) barrier else attempt.nextBarrier()
            verdict = runTick(checked, tick, id)
            if (verdict != Window.Verdict.Open) return verdict
            verdict = statesSeen(tick, held = openStates.filter { it.holds() }, broken = neverStates.filter { it.holds() })
            if (verdict != Window.Verdict.Open) return verdict
            if (last) checked.forEach { verdict = barrierSeen(it, barrier) }
        }
        return verdict
    }

    /**
     * Paper runs [tick] for [checked] and sends each of them barrier [id]; the window judges every record
     * that arrives before the last of those barriers. Returns what the records decided.
     */
    private suspend fun Window.runTick(
        checked: List<GamePlayer>,
        tick: Int,
        id: Int,
    ): Window.Verdict {
        checked.forEach { stepUntil(it, tick, id) }
        val waiting = checked.toMutableSet()
        var verdict: Window.Verdict = Window.Verdict.Open
        while (waiting.isNotEmpty() && verdict == Window.Verdict.Open) {
            val event = nextEvent()
            if (event is Attempt.Event.Barrier && event.id == id) waiting -= event.player else verdict = judge(event)
        }
        return verdict
    }

    private fun stepUntil(
        player: GamePlayer,
        tick: Int,
        barrier: Int,
    ) = attempt.send(Message.createStepUntil(player = player.uuid.toString(), tick = tick, barrier = barrier))

    /** The attempt's next event; hung work or a lost client fails the attempt at once, whatever a window would decide. */
    private suspend fun nextEvent(): Attempt.Event =
        attempt.nextEvent().also { if (it is Attempt.Event.Failed) throw attempt.observed(it.failure) }

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

    internal val states = mutableListOf<StateCheck>()
    internal val neverStates = mutableListOf<StateCheck>()

    /** The player perceives [fact] in some tick of the window. */
    infix fun GamePlayer.sees(fact: Perceivable) {
        checks += Check(this, fact)
    }

    /**
     * State no player perceives, such as a record in a store, holds after some tick of the window:
     * [holds] reads it from the test JVM after each tick, and the first true passes the check. A window
     * that reads state runs one tick at a time; [description] names the state in a failure.
     */
    fun state(
        description: String,
        holds: suspend () -> Boolean,
    ) {
        states += StateCheck(description, holds)
    }

    /**
     * State checks that must read false after every tick of the window: `never.state("session gone") { ... }`.
     * The window then runs all its ticks, and still needs a positive check.
     */
    val never: NeverState = NeverState(neverStates)

    /**
     * The player perceives a fact in no tick of the window: `outsider.never sees anyChat()`. The window
     * then runs all its ticks, and still needs a positive check.
     */
    val GamePlayer.never: Absence get() = Absence(this, nevers)
}

/** State that must not hold after any tick of a window; see [WindowChecks.never]. */
class NeverState internal constructor(
    private val neverStates: MutableList<StateCheck>,
) {
    /** [holds] reads false after every tick of the window; [description] names the state in a failure. */
    fun state(
        description: String,
        holds: suspend () -> Boolean,
    ) {
        neverStates += StateCheck(description, holds)
    }
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
