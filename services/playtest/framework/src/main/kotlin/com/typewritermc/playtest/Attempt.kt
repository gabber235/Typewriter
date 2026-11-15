package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.AttemptStep
import com.typewritermc.playtest.wire.Message.InputStep
import com.typewritermc.playtest.wire.Message.Kind
import com.typewritermc.playtest.wire.Message.Perception
import com.typewritermc.playtest.wire.Message.ProbeAction
import com.typewritermc.playtest.wire.Message.Region
import com.typewritermc.playtest.wire.Message.Renderer
import com.typewritermc.playtest.wire.Message.Watch
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.selects.select
import java.nio.file.Path

/**
 * One attempt of one requirement while it holds its lease: the players' perception streams in arrival
 * order, kept whole as the attempt's timeline, and the session it talks to the pool through. Positions
 * the requirement names count from the middle of the attempt's [region]; the attempt turns them into
 * world positions on the way out and turns what the players perceive back on the way in.
 */
internal class Attempt(
    private val session: PoolSession,
    val players: List<GamePlayer>,
    val region: Region,
    private val requirementCode: RequirementCode,
) {
    /** One event of a leased player's stream. */
    sealed interface Event {
        val player: GamePlayer

        data class Perceived(
            override val player: GamePlayer,
            val perception: Perception,
        ) : Event

        data class Barrier(
            override val player: GamePlayer,
            val id: Int,
        ) : Event

        /**
         * The attempt fails because of [player], wherever the body waits: its counted work hung
         * ([WorkHung]) or its client was lost ([ClientLost]).
         */
        data class Failed(
            override val player: GamePlayer,
            val failure: AssertionError,
        ) : Event
    }

    private val incoming = Channel<Event>(Channel.UNLIMITED)
    private val received = mutableListOf<Event>()
    private val lost = CompletableDeferred<ClientLost>()
    private val thrown = mutableSetOf<AssertionError>()
    private val taken = mutableListOf<AttemptStep>()

    /** Every event the body has taken so far, in arrival order. */
    val timeline: List<Event> get() = received

    /** What the body did so far, in order, each with its wall clock start and duration. */
    val steps: List<AttemptStep> get() = taken

    /** The requirement's own frame that last called into the attempt, while it was still on the stack. */
    private var calledFrom: StackTraceElement? = null

    /**
     * Notes the requirement's frame that calls into the attempt now. A failure that ends a suspended call
     * carries only the framework's frames, so [located] puts this one first.
     */
    fun called() {
        Throwable().stackTrace.firstOrNull(requirementCode::owns)?.let { calledFrom = it }
    }

    /** [failure], with the requirement's line it failed at first in its stack trace when the trace lost it. */
    fun located(failure: Throwable): Throwable {
        val frame = calledFrom
        if (frame != null && failure.stackTrace.none(requirementCode::owns)) failure.stackTrace = arrayOf(frame) + failure.stackTrace
        return failure
    }

    /** The latest tick the attempt knows ran: from its stimuli, its players' records and its windows. */
    var ranUntil: Int = 0
        private set

    /** Paper ran at least up to [tick]. */
    fun ran(tick: Int) {
        ranUntil = maxOf(ranUntil, tick)
    }

    /** One step began at [atMillis] and ends now; [says] starts with its kind. */
    fun took(
        atMillis: Long,
        says: String,
    ) {
        taken += AttemptStep(atMillis, System.currentTimeMillis() - atMillis, says)
    }

    /** Runs [action], which the requirement called, as one step that [says] describes. */
    private suspend fun <T> step(
        says: String,
        action: suspend () -> T,
    ): T {
        called()
        val at = System.currentTimeMillis()
        try {
            return action()
        } finally {
            took(at, says)
        }
    }

    /** Hands an event of one of [players] to the attempt; called by the session's reader. */
    fun deliver(event: Event) {
        incoming.trySend(if (event is Event.Perceived) event.copy(perception = region.local(event.perception)) else event)
        ((event as? Event.Failed)?.failure as? ClientLost)?.let(lost::complete)
    }

    /** Ends the streams: the connection to the pool broke with [cause]. */
    fun fail(cause: Throwable) {
        incoming.close(cause)
    }

    /** The next event of any leased player, kept in the timeline. */
    suspend fun nextEvent(): Event =
        incoming.receive().also {
            received += it
            if (it is Event.Perceived) ran(it.perception.tick())
        }

    /**
     * Why the attempt fails that the body never met: failures that arrived but that no wait threw.
     * Takes every event that arrived into the timeline; for after the body ended.
     */
    fun untakenFailures(): List<AssertionError> =
        generateSequence { incoming.tryReceive().getOrNull() }
            .toList()
            .also { received += it }
            .filterIsInstance<Event.Failed>()
            .map { it.failure }
            .filter { it !in thrown }

    fun send(message: Message) = session.send(message)

    fun nextBarrier(): Int = session.nextBarrier()

    /** Paper runs [action] for [players] and returns once each of their clients holds its effect; the mark is the tick after which it ran. */
    suspend fun probe(
        players: List<GamePlayer>,
        action: ProbeAction,
    ): Mark =
        step("probe ${players.joinToString { it.name }}: ${action.says}") { Mark(unlessLost { session.probe(players, action) }) }
            .also { ran(it.tick) }

    /** The kinds of state [player] carries a mark of, as Paper sees them. */
    suspend fun query(player: GamePlayer): List<Kind> = step("query ${player.name}") { unlessLost { session.query(player) } }

    /** [player]'s client runs [steps], which [says] describes; the mark is the tick after which its first event reached the client. */
    suspend fun input(
        player: GamePlayer,
        steps: List<InputStep>,
        says: String,
    ): Mark = step("input ${player.name} $says") { Mark(unlessLost { session.input(player, steps) }) }.also { ran(it.tick) }

    /** [player]'s client counts the pixels of [entities] in every record from now on; an empty list ends it. */
    suspend fun look(
        player: GamePlayer,
        entities: List<EntityRef>,
    ) = unlessLost { session.look(player, entities) }

    /** Where the attempt keeps the frames it writes; the session sets it once the attempt holds its lease. */
    lateinit var evidence: Evidence

    /**
     * [player]'s frame, as the client holds it now, is the golden [name]: the frame and what an approve
     * needs go into the attempt's evidence, and on the pinned renderer it is compared with the approved
     * golden; another renderer notes it as not checked. A frame that differs fails the attempt.
     */
    suspend fun golden(
        player: GamePlayer,
        name: String,
    ) {
        val at = System.currentTimeMillis()
        val (png, frame, renderer) = capture(player, name)
        val goldens = session.goldens
        Golden.writeCandidate(evidence.file("$name.golden"), goldens.file(name), png.fileName.toString(), frame, renderer, goldens.pinned)
        val golden = goldens.golden(name)
        val says = "golden $name of ${player.name}"
        when (val verdict = judge(golden, golden?.let(goldens::image), frame, renderer, goldens.pinned)) {
            GoldenVerdict.Matches -> {
                took(at, "$says matches")
            }

            is GoldenVerdict.NotChecked -> {
                took(at, "$says not checked: ${verdict.reason}")
            }

            is GoldenVerdict.Differs -> {
                val diff = verdict.diff?.let { marked -> evidence.file("$name.diff.png").also(marked::writePng) }
                diff?.let { evidence.screenshots += it.fileName.toString() }
                took(at, "$says differs: ${verdict.reason}")
                throw GoldenDiffers(
                    "${player.name}'s frame differs from golden $name: ${verdict.reason}. The frame is $png" +
                        (diff?.let { ", its diff $it" } ?: "") +
                        "; `cargo xtask goldens approve` makes it the golden when the change is meant.",
                )
            }
        }
    }

    /** [player]'s frame, as the client holds it now, kept in the attempt's evidence as `<name>.png`. */
    suspend fun capture(
        player: GamePlayer,
        name: String,
    ): Captured {
        called()
        val png = evidence.file("$name.png")
        val renderer = unlessLost { session.capture(player, png) }
        evidence.screenshots += png.fileName.toString()
        return Captured(png, Frame.readPng(png), renderer)
    }

    /** A frame a client drew: its PNG in the evidence, its pixels, and the renderer that drew it. */
    data class Captured(
        val png: Path,
        val frame: Frame,
        val renderer: Renderer,
    )

    /** The answer of [call], unless a client of the attempt is lost first: a lost client never answers. */
    private suspend fun <T> unlessLost(call: suspend () -> T): T =
        coroutineScope {
            val answer = async { call() }
            select {
                answer.onAwait { it }
                lost.onAwait { failure ->
                    answer.cancel()
                    thrown += failure
                    throw failure
                }
            }
        }

    /** Every leased player's client watches these from now on. */
    fun watch(
        blocks: List<BlockRef>,
        entities: List<EntityRef>,
    ) = players.forEach { send(Watch(it.uuid, blocks.map { block -> region.world(block.at) }, entities.map { entity -> entity.uuid })) }

    /** The first frame of [trace] in the requirement's own code, as `File.kt:line`. */
    fun requirementLine(trace: Array<StackTraceElement>): String? = requirementCode.line(trace)
}

/** A probe action as a step names it: `Chat[text=Hello]`. */
private val Message.ProbeAction.says: String get() = toString().removePrefix("Probe")
