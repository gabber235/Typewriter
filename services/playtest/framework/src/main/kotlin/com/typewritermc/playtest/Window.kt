package com.typewritermc.playtest

import skirout.harness.v1.wire.Perception

/** One check of a window: [player] perceives [fact] at some tick of it, or, as a never check, at none. */
internal data class Check(
    val player: GamePlayer,
    val fact: Perceivable,
)

/**
 * One check of a window on state no player perceives, such as a record in a store: [holds] reads it from
 * the test JVM after each tick of the window. As a positive check it holds at the first tick [holds]
 * returns true; as a never check it fails at the first tick [holds] returns true.
 */
internal class StateCheck(
    val description: String,
    val holds: suspend () -> Boolean,
)

/**
 * The rules of one `within` window, fed each checked player's perception stream in order. The window
 * covers the ticks after [anchor], the tick in which the last stimulus ran, up to and including [end].
 * A check holds at the first tick inside the window whose perception shows its fact. A client sends a
 * record only when what the player perceives changed, so a record stands for every tick up to the
 * next one: a record from before the window shows the window's first tick until a later record or the
 * barrier arrives. A record of a frame a clip draws between two ticks judges nothing: only the record
 * at a tick's end does, the one a gated attempt makes too. A fact about a change compares with the
 * record that stood at the anchor. Paper sends
 * [barrier] to every checked player once the window's last tick ran, and the client echoes it after
 * every record of those ticks, so a barrier with a check still open is the failure.
 *
 * A never check fails at the first tick inside the window whose perception shows its fact. A window
 * with never checks can pass only once every checked player's barrier arrived, since a later tick could
 * still show it; it needs a positive check all the same, so a requirement always proves something
 * happened.
 *
 * State checks are read between ticks, never from a record: the requirement steps the window one tick
 * at a time and reports what each tick's reads found through [statesSeen]. [stepping] are the players
 * whose barrier closes the window, which a window of state checks alone names itself.
 */
internal class Window(
    val anchor: Int,
    private val length: Ticks,
    val barrier: Int,
    declared: WindowChecks,
    stepping: Collection<GamePlayer> = (declared.checks + declared.nevers).map { it.player },
) {
    /** The never state checks, read after every tick of the window. */
    val neverStates: List<StateCheck> = declared.neverStates.toList()

    init {
        if (declared.checks.isEmpty() && declared.states.isEmpty()) {
            throw RequirementRefused("a window needs a positive check: without one it could never fail")
        }
    }

    val end: Int = anchor + length.count

    private val open = declared.checks.toMutableList()
    private val nevers = declared.nevers.toList()
    private val states = declared.states.toMutableList()
    private val waitingFor = stepping.toMutableSet()

    /** The positive state checks that have not held yet. */
    val openStates: List<StateCheck> get() = states.toList()

    /** Whether the window reads state checks after each tick, and so steps one tick at a time. */
    val readsStates: Boolean get() = states.isNotEmpty() || neverStates.isNotEmpty()

    private val lastSeen = mutableMapOf<GamePlayer, Perception>()
    private val atStimulus = mutableMapOf<GamePlayer, Perception>()
    private var heldUntil = anchor
    private var verdict: Verdict = Verdict.Open

    /** What the window decided so far. */
    sealed interface Verdict {
        data object Open : Verdict

        data class Passed(
            val tick: Int,
        ) : Verdict

        data class Missed(
            val tick: Int,
            val report: String,
        ) : Verdict
    }

    /** The window after [player] perceived [perception]. */
    fun perceived(
        player: GamePlayer,
        perception: Perception,
    ): Verdict {
        // A frame a clip draws between two ticks shows the clip; only a tick's end is judged, as without one.
        if (verdict != Verdict.Open || perception.tick > end || perception.partial < 1f) return verdict
        val carried = lastSeen.put(player, perception)
        if (perception.tick <= anchor) {
            atStimulus[player] = perception
            return verdict
        }
        if (carried != null && carried.tick <= anchor && perception.tick > anchor + 1) judge(player, carried, at = anchor + 1)
        if (verdict == Verdict.Open) judge(player, perception, at = perception.tick)
        return verdict
    }

    /** The window after [player]'s client echoed barrier [id]. */
    fun barrierSeen(
        player: GamePlayer,
        id: Int,
    ): Verdict {
        if (verdict != Verdict.Open || id != barrier) return verdict
        lastSeen[player]?.takeIf { it.tick <= anchor }?.let { judge(player, it, at = anchor + 1) }
        if (verdict != Verdict.Open) return verdict
        waitingFor -= player
        if (waitingFor.isEmpty()) verdict = if (allHeld()) Verdict.Passed(heldUntil) else Verdict.Missed(end, report())
        return verdict
    }

    /**
     * The window after the reads of tick [at]: [held] are the open state checks that read true, and
     * [broken] the never state checks that did.
     */
    fun statesSeen(
        at: Int,
        held: List<StateCheck>,
        broken: List<StateCheck> = listOf(),
    ): Verdict {
        if (verdict != Verdict.Open || at > end) return verdict
        broken.firstOrNull()?.let {
            verdict =
                Verdict.Missed(
                    at,
                    "${it.description} held at tick ${at - anchor} of the ${length.count} tick window (tick $at); it must never hold.",
                )
            return verdict
        }
        if (held.isEmpty()) return verdict
        states -= held.toSet()
        heldUntil = maxOf(heldUntil, at)
        if (allHeld() && nevers.isEmpty() && neverStates.isEmpty()) verdict = Verdict.Passed(heldUntil)
        return verdict
    }

    private fun allHeld(): Boolean = open.isEmpty() && states.isEmpty()

    /** What [perception], shown to [player] from tick [at], decides: a never check it breaks, or the checks it holds. */
    private fun judge(
        player: GamePlayer,
        perception: Perception,
        at: Int,
    ) {
        val stimulus = Stimulus(anchor, atStimulus[player])
        val broken = nevers.firstOrNull { it.player == player && it.fact.shownIn(perception, stimulus) }
        if (broken != null) {
            verdict =
                Verdict.Missed(
                    at,
                    "${player.name} saw ${broken.fact.shownAs(
                        perception,
                        stimulus,
                    )} at tick ${at - anchor} of the ${length.count} tick window " +
                        "(tick $at); it must never see ${broken.fact.description}.",
                )
            return
        }
        val held = open.filter { it.player == player && it.fact.shownIn(perception, stimulus) }
        if (held.isEmpty()) return
        open -= held
        heldUntil = maxOf(heldUntil, at)
        if (allHeld() && nevers.isEmpty() && neverStates.isEmpty()) verdict = Verdict.Passed(heldUntil)
    }

    private fun report(): String =
        buildString {
            states.forEach {
                append("${it.description} did not hold within ${this@Window.length.count} ticks (ticks ${anchor + 1} to $end).\n")
            }
            open.forEach {
                append(
                    "${it.player.name} did not see ${it.fact.description} within ${this@Window.length.count} ticks (ticks ${anchor + 1} to $end).\n",
                )
            }
            open.map { it.player }.distinct().forEach { player ->
                val last = lastSeen[player]
                val texts = last?.texts.orEmpty()
                val shown = if (texts.isEmpty()) "nothing" else texts.joinToString { "${it.element} \"${it.text}\"" }
                append("At tick $end ${player.name} perceived $shown.\n")
                open.filter { it.player == player }.mapNotNull { check -> last?.let(check.fact::observed) }.distinct().forEach {
                    append("At tick $end ${player.name} perceived $it.\n")
                }
            }
        }.trimEnd()
}
