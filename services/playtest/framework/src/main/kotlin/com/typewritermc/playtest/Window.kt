package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message.Perception

/** One check of a window: [player] perceives [fact] at some tick of it, or, as a never check, at none. */
internal data class Check(
    val player: GamePlayer,
    val fact: Perceivable,
)

/**
 * The rules of one `within` window, fed each checked player's perception stream in order. The window
 * covers the ticks after [anchor], the tick in which the last stimulus ran, up to and including [end].
 * A check holds at the first tick inside the window whose perception shows its fact. A client sends a
 * record only when what the player perceives changed, so a record stands for every tick up to the
 * next one: a record from before the window shows the window's first tick until a later record or the
 * barrier arrives. A fact about a change compares with the record that stood at the anchor. Paper sends
 * [barrier] to every checked player once the window's last tick ran, and the client echoes it after
 * every record of those ticks, so a barrier with a check still open is the failure.
 *
 * A never check fails at the first tick inside the window whose perception shows its fact. A window
 * with never checks can pass only once every checked player's barrier arrived, since a later tick could
 * still show it; it needs a positive check all the same, so a requirement always proves something
 * happened.
 */
internal class Window(
    private val anchor: Int,
    private val length: Ticks,
    val barrier: Int,
    checks: List<Check>,
    nevers: List<Check> = listOf(),
) {
    init {
        require(checks.isNotEmpty()) { "a window needs a positive check: without one it could never fail" }
    }

    val end: Int = anchor + length.count

    private val open = checks.toMutableList()
    private val nevers = nevers.toList()
    private val waitingFor = (checks + nevers).map { it.player }.toMutableSet()
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
            val report: String,
        ) : Verdict
    }

    /** The window after [player] perceived [perception]. */
    fun perceived(
        player: GamePlayer,
        perception: Perception,
    ): Verdict {
        if (verdict != Verdict.Open || perception.tick() > end) return verdict
        val carried = lastSeen.put(player, perception)
        if (perception.tick() <= anchor) {
            atStimulus[player] = perception
            return verdict
        }
        if (carried != null && carried.tick() <= anchor && perception.tick() > anchor + 1) judge(player, carried, at = anchor + 1)
        if (verdict == Verdict.Open) judge(player, perception, at = perception.tick())
        return verdict
    }

    /** The window after [player]'s client echoed barrier [id]. */
    fun barrierSeen(
        player: GamePlayer,
        id: Int,
    ): Verdict {
        if (verdict != Verdict.Open || id != barrier) return verdict
        lastSeen[player]?.takeIf { it.tick() <= anchor }?.let { judge(player, it, at = anchor + 1) }
        if (verdict != Verdict.Open) return verdict
        waitingFor -= player
        if (waitingFor.isEmpty()) verdict = if (open.isEmpty()) Verdict.Passed(heldUntil) else Verdict.Missed(report())
        return verdict
    }

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
        if (open.isEmpty() && nevers.isEmpty()) verdict = Verdict.Passed(heldUntil)
    }

    private fun report(): String =
        buildString {
            open.forEach {
                append(
                    "${it.player.name} did not see ${it.fact.description} within ${this@Window.length.count} ticks (ticks ${anchor + 1} to $end).\n",
                )
            }
            open.map { it.player }.distinct().forEach { player ->
                val texts = lastSeen[player]?.texts().orEmpty()
                val shown = if (texts.isEmpty()) "nothing" else texts.joinToString { "${it.element()} \"${it.text()}\"" }
                append("At tick $end ${player.name} perceived $shown.\n")
            }
        }.trimEnd()
}
