package com.typewritermc.playtest

import build.skir.reflection.EnumDescriptor
import build.skir.reflection.EnumWrapperVariant
import build.skir.reflection.StructDescriptor
import build.skir.reflection.StructField
import build.skir.reflection.TypeDescriptor
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Deferred
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.async
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.selects.select
import kotlinx.coroutines.withContext
import skirout.harness.v1.golden.Renderer
import skirout.harness.v1.test_run.Artifact
import skirout.harness.v1.test_run.ArtifactKind
import skirout.harness.v1.test_run.Step
import skirout.harness.v1.wire.Answer
import skirout.harness.v1.wire.InputStep
import skirout.harness.v1.wire.Message
import skirout.harness.v1.wire.Perception
import skirout.harness.v1.wire.PlayerAction
import skirout.harness.v1.wire.ProbeAction
import skirout.harness.v1.wire.Region
import skirout.harness.v1.wire.StateKind
import skirout.harness.v1.wire.WorldAction
import java.nio.file.Path

/**
 * What an attempt asks of the pool it runs in. [PoolSession] answers over its connection to the pool;
 * the framework's own tests answer without one.
 */
internal interface AttemptPool {
    /** This project's goldens and the local golden images. */
    val goldens: Goldens

    fun send(message: Message)

    fun nextBarrier(): Int

    /** Paper runs [action] for [players]; returns, once each of their clients holds its effect, the tick after which it ran. */
    suspend fun probe(
        players: List<GamePlayer>,
        action: ProbeAction,
    ): Int

    /** The kinds of state [player] carries a mark of, as Paper sees them. */
    suspend fun query(player: GamePlayer): List<StateKind>

    /** The tick that last ended on the Paper of [player]'s attempt. */
    suspend fun now(player: GamePlayer): Int

    /**
     * The publication the Typewriter engine on the Paper of [player]'s attempt applies now.
     *
     * TODO(node 9): temporary test only signal; replace with the engine's reported active publication ("applied on N of M").
     */
    suspend fun applied(player: GamePlayer): String?

    /** Kills and boots again the own Paper of [attempt], which runs [submission]; returns the new Paper's tick after which every player is back. */
    suspend fun restart(
        attempt: Attempt,
        submission: SubmissionId,
    ): Int

    /** [player]'s client runs [steps]; returns the tick after which their first event reached the client. */
    suspend fun input(
        player: GamePlayer,
        steps: List<InputStep>,
    ): Int

    /** [player]'s client leaves its Paper as a person quits; returns, once Paper saw the player leave, the tick after which it left. */
    suspend fun quit(player: GamePlayer): Int

    /** [player]'s client joins its Paper again; returns, once it holds what Paper sends it, the tick after which it joined. */
    suspend fun rejoin(player: GamePlayer): Int

    /** [player]'s client draws the frame it holds now and writes it as a PNG to [png]; returns the renderer that drew it. */
    suspend fun capture(
        player: GamePlayer,
        png: Path,
    ): Renderer

    /** [player]'s client records a clip from the next tick on and writes it as an mp4 to [mp4]. */
    suspend fun startClip(
        player: GamePlayer,
        mp4: Path,
    ): Answer.ClipStarted

    /** [player]'s client finishes its clip. */
    suspend fun stopClip(player: GamePlayer): Answer.ClipWritten
}

/**
 * One attempt of one requirement while it holds its lease: the players' perception streams in arrival
 * order, kept whole as the attempt's timeline, and the pool it talks to. Positions
 * the requirement names count from the middle of the attempt's [region]; the attempt turns them into
 * world positions on the way out and turns what the players perceive back on the way in. It runs on
 * the Paper named [paper].
 */
internal class Attempt(
    private val session: AttemptPool,
    private val submission: SubmissionId,
    val players: List<GamePlayer>,
    val region: Region,
    val paper: String,
    private val requirementCode: RequirementCode,
    private val restartsPaper: Boolean,
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
         * ([WorkHung]), its client or Paper was lost ([ClientLost], [PaperLost]), or its lease ran out
         * ([LeaseExpired]).
         */
        data class Failed(
            override val player: GamePlayer,
            val failure: AssertionError,
        ) : Event
    }

    private val incoming = Channel<Event>(Channel.UNLIMITED)
    private val received = mutableListOf<Event>()
    private val lost = CompletableDeferred<AssertionError>()
    private val thrown = mutableSetOf<AssertionError>()
    private val taken = mutableListOf<Step>()

    /** The players who quit and have not rejoined: no window, input or frame can reach their clients. */
    private val away = mutableSetOf<GamePlayer>()

    /** Every event the body has taken so far, in arrival order. */
    val timeline: List<Event> get() = received

    /** What the body did so far, in order, each with its wall clock start and duration. */
    val steps: List<Step> get() = taken

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

    /**
     * Whether the body made a positive check: a window whose checks held, a golden compare that matched,
     * a state check of the test kit, or an outcome the framework observed and threw into it ([observed]).
     */
    var proved = false

    /**
     * [failure], an outcome the framework observed (a missed window, hung work, a lost client or Paper),
     * as it reaches the body: a body that expects it and catches it has made a positive check.
     */
    fun observed(failure: AssertionError): AssertionError = failure.also { proved = true }

    /**
     * Runs [body] on the attempt; returns why it failed, or null. A body that made no positive check fails.
     * Each of [content] is written for the players and live on Paper before the body runs, and removed with
     * its removal live once the body ended, however it ended, so the players go back to the pool without it.
     * The body's own failure comes first; a failed removal fails an attempt that passed.
     */
    suspend fun outcome(
        content: List<AttemptContent> = emptyList(),
        body: suspend RequirementScope.() -> Unit,
    ): Throwable? {
        val written = mutableListOf<Pair<AttemptContent, WrittenContent>>()
        val failure =
            caught {
                for (each in content) {
                    each.write(players).also { written += each to it }
                    each.liveness.awaitLive(contentPaper)
                }
                RequirementScope(this, written.map { (each, wrote) -> LiveChanges(wrote, each.liveness) }).body()
                bodyEnded(proved)
            }
        val removals =
            withContext(NonCancellable) {
                written.asReversed().mapNotNull { (each, wrote) ->
                    caught {
                        wrote.remove()
                        each.liveness.awaitLive(contentPaper)
                        null
                    }
                }
            }
        val first = failure ?: removals.firstOrNull() ?: return null
        (removals - first).forEach(first::addSuppressed)
        return first
    }

    /** [written] content whose changes a body makes are live on Paper before the body goes on. */
    private inner class LiveChanges(
        private val written: WrittenContent,
        private val liveness: ContentLiveness,
    ) : WrittenContent by written {
        override suspend fun change() {
            written.change()
            liveness.awaitLive(contentPaper)
        }

        override suspend fun remove() {
            written.remove()
            liveness.awaitLive(contentPaper)
        }
    }

    /** The attempt's Paper as content liveness reads it. */
    val contentPaper =
        object : ContentPaper {
            override val name = paper

            override suspend fun applied(): String? = unlessLost { session.applied(players.first()) }
        }

    /** What [block] returned as its failure, or what it threw. */
    private suspend fun caught(block: suspend () -> Throwable?): Throwable? =
        try {
            block()
        } catch (cancelled: CancellationException) {
            cancelled
        } catch (
            @Suppress("TooGenericExceptionCaught") failed: Throwable,
        ) {
            failed
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
        taken += Step(atMillis = atMillis, actor = null, says = says, durationMillis = System.currentTimeMillis() - atMillis)
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
        // A lost client or Paper, or a lease that ran out, never answers what the body waits for.
        (event as? Event.Failed)?.failure?.takeIf { it is ClientLost || it is PaperLost || it is LeaseExpired }?.let(lost::complete)
    }

    /**
     * The attempt's Paper is back, as the session reads its answer: every record that arrived until now
     * shows the killed Paper, which the body never took while it restarted, so it is dropped; any other
     * event stays. Called by the session's reader, the stream's only writer, so what arrives later stays behind.
     */
    fun restarted() {
        generateSequence { incoming.tryReceive().getOrNull() }
            .toList()
            .filter { it !is Event.Perceived }
            .forEach { incoming.trySend(it) }
    }

    /** Ends the streams: the connection to the pool broke with [cause]. */
    fun fail(cause: Throwable) {
        incoming.close(cause)
    }

    /** The next event of any leased player, kept in the timeline. */
    suspend fun nextEvent(): Event =
        incoming.receive().also {
            received += it
            if (it is Event.Perceived) ran(it.perception.tick)
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
    suspend fun query(player: GamePlayer): List<StateKind> = step("query ${player.name}") { unlessLost { session.query(player) } }

    /**
     * Starts [action], a stimulus from outside Paper that [says] describes, in [scope] as one step; the mark is
     * the tick that last ended on Paper before it started, since Paper runs no tick until a window waits.
     */
    suspend fun <T> outside(
        scope: CoroutineScope,
        says: String,
        action: suspend () -> T,
    ): Pair<Mark, Deferred<T>> {
        called()
        val asked =
            present.firstOrNull()
                ?: throw RequirementRefused("a stimulus from outside Paper needs a player on Paper to mark its tick, and every player quit")
        val mark = Mark(unlessLost { session.now(asked) }).also { ran(it.tick) }
        val at = System.currentTimeMillis()
        return mark to
            scope.async {
                try {
                    action()
                } finally {
                    took(at, "outside: $says")
                }
            }
    }

    /**
     * Kills the attempt's own Paper and boots it again; the mark is the new Paper's tick after which every
     * player is back. What the players perceived before is gone from the timeline: its ticks are the
     * killed Paper's, which the new one counts again from the start.
     */
    suspend fun restart(): Mark {
        if (!restartsPaper) {
            called()
            throw RequirementRefused(
                "restartPaper needs restartsPaper = true on the requirement: a kill drops every client on a Paper, so only an attempt on a Paper of its own may restart it",
            )
        }
        players.forEach { onPaper(it, "restartPaper, as the restarted Paper waits for every player of the attempt") }
        val mark = step("restart Paper") { Mark(unlessLost { session.restart(this, submission) }) }
        received.clear()
        ranUntil = mark.tick
        return mark
    }

    /** [player]'s client runs [steps], which [says] describes; the mark is the tick after which its first event reached the client. */
    suspend fun input(
        player: GamePlayer,
        steps: List<InputStep>,
        says: String,
    ): Mark {
        onPaper(player, "an input")
        return step("input ${player.name} $says") { Mark(unlessLost { session.input(player, steps) }) }.also { ran(it.tick) }
    }

    /**
     * [player]'s client leaves its Paper as a person quits and stays away until [rejoin]; the mark is the
     * tick after which Paper saw it leave. It stays the attempt's player meanwhile.
     */
    suspend fun quit(player: GamePlayer): Mark {
        if (player in away) {
            called()
            throw RequirementRefused("${player.name} already quit; rejoin it before it quits again")
        }
        // The client leaves even when no answer comes, so nothing may wait for it from here on.
        away += player
        return step("quit ${player.name}") { Mark(unlessLost { session.quit(player) }) }.also { ran(it.tick) }
    }

    /** [player], away since its [quit], joins its Paper again; the mark is the tick after which it joined. */
    suspend fun rejoin(player: GamePlayer): Mark {
        if (player !in away) {
            called()
            throw RequirementRefused("${player.name} is on Paper; only a player who quit can rejoin")
        }
        val mark = step("rejoin ${player.name}") { Mark(unlessLost { session.rejoin(player) }) }
        away -= player
        ran(mark.tick)
        return mark
    }

    /** The attempt's players on Paper: every one but those away since their [quit]. */
    val present: List<GamePlayer> get() = players.filter { it !in away }

    /** Refuses [use] of [player], which needs its client on Paper, while it is away since its [quit]. */
    fun onPaper(
        player: GamePlayer,
        use: String,
    ) {
        if (player !in away) return
        called()
        throw RequirementRefused("${player.name} quit and is not on Paper; rejoin it before $use")
    }

    /** Where the attempt keeps the frames it writes; the session sets it once the attempt holds its lease. */
    lateinit var evidence: Evidence

    /**
     * [player]'s frame, as the client holds it now, is the golden [name]: the frame and what an approve
     * needs go into the attempt's evidence, and on the pinned renderer it is compared with the approved
     * golden; another renderer notes it as not checked. A frame that differs, or has no golden there,
     * fails the attempt. Only a compare that matched is a positive check.
     */
    suspend fun golden(
        player: GamePlayer,
        name: String,
    ) {
        val at = System.currentTimeMillis()
        val (png, frame, renderer) = capture(player, name)
        val goldens = session.goldens
        goldens.writeCandidate(evidence.file("$name.golden"), name, png.fileName.toString(), frame, renderer)
        evidence.artifacts += Artifact(kind = ArtifactKind.GOLDEN, path = "$name.golden")
        val golden = goldens.golden(name)
        val says = "golden $name of ${player.name}"
        when (val verdict = judge(golden, golden?.let(goldens::image), frame, renderer, goldens.pinned)) {
            GoldenVerdict.Matches -> {
                proved = true
                took(at, "$says matches")
            }

            is GoldenVerdict.NotChecked -> {
                took(at, "$says not checked: ${verdict.reason}")
            }

            is GoldenVerdict.Differs -> {
                val diff = verdict.diff?.let { marked -> evidence.file("$name.diff.png").also(marked::writePng) }
                diff?.let { evidence.artifacts += Artifact(kind = ArtifactKind.SCREENSHOT, path = it.fileName.toString()) }
                took(at, "$says fails: ${verdict.reason}")
                throw GoldenDiffers(
                    "${player.name}'s frame fails golden $name: ${verdict.reason}. The frame is $png" +
                        (diff?.let { ", its diff $it" } ?: "") +
                        "; when the change is meant, `cargo xtask goldens approve --pr <n>` makes the pull request's CI " +
                        "frame the golden (`cargo xtask goldens approve` takes this machine's last run on the pinned renderer).",
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
        onPaper(player, "its frame is captured")
        val png = evidence.file("$name.png")
        val renderer = unlessLost { session.capture(player, png) }
        evidence.artifacts += Artifact(kind = ArtifactKind.SCREENSHOT, path = png.fileName.toString())
        return Captured(png, Frame.readPng(png), renderer)
    }

    private val clips = linkedMapOf<GamePlayer, String>()

    /**
     * Every player's client records a clip from the next tick on, into the evidence as
     * `clips/<player><suffix>.mp4`; returns why one did not start, a lost client included, or null.
     */
    suspend fun startClips(suffix: String): Throwable? {
        for (player in players) {
            val clip = "clips/${player.name}$suffix.mp4"
            val answer =
                try {
                    unlessLost { session.startClip(player, evidence.file(clip)) }
                } catch (lost: AssertionError) {
                    return lost
                }
            answer.failure?.let { return ClipFailed("${player.name}'s clip did not start: $it") }
            clips[player] = clip
        }
        return null
    }

    /**
     * Each client that records a clip finishes it, and the clip joins the evidence unless no tick ran
     * while it recorded; returns why one could not be written, or null. Once a client of the attempt is
     * lost no clip is asked for: the loss is the attempt's own to report or expect, and a lost client
     * answers nothing.
     */
    suspend fun stopClips(): Throwable? {
        var failed: Throwable? = null
        for ((player, clip) in clips) {
            val written =
                try {
                    unlessLost { session.stopClip(player) }
                } catch (_: AssertionError) {
                    break
                }
            val failure = written.failure
            when {
                failure != null -> failed = failed ?: ClipFailed("${player.name}'s clip was not written: $failure")
                written.frames > 0 -> evidence.artifacts += Artifact(kind = ArtifactKind.CLIP, path = clip)
            }
        }
        clips.clear()
        return failed
    }

    /** A frame a client drew: its PNG in the evidence, its pixels, and the renderer that drew it. */
    data class Captured(
        val png: Path,
        val frame: Frame,
        val renderer: Renderer,
    )

    /** The answer of [call], unless a client or the Paper of the attempt is lost first: neither answers then. */
    private suspend fun <T> unlessLost(call: suspend () -> T): T =
        coroutineScope {
            val answer = async { call() }
            select {
                answer.onAwait { it }
                lost.onAwait { failure ->
                    answer.cancel()
                    thrown += failure
                    throw observed(failure)
                }
            }
        }

    /** The first frame of [trace] in the requirement's own code, as `File.kt:line`. */
    fun requirementLine(trace: Array<StackTraceElement>): String? = requirementCode.line(trace)
}

/** A probe action as a step names it: `Chat[text=Hello]`. */
private val ProbeAction.says: String
    get() =
        when (this) {
            is ProbeAction.OnPlayerWrapper -> said(PlayerAction.typeDescriptor, value)
            is ProbeAction.OnWorldWrapper -> said(WorldAction.typeDescriptor, value)
            else -> "$kind"
        }

/** [value], a variant of the enum [descriptor] describes, as a step names it: the variant, then its fields. */
private fun <E> said(
    descriptor: EnumDescriptor.Reflective<E>,
    value: E,
): String {
    val variant = descriptor.getVariant(value)
    if (variant !is EnumWrapperVariant.Reflective<E, *>) {
        return variant.name.split('_').joinToString("") { it.replaceFirstChar(Char::uppercase) } +
            "[]"
    }
    return said(variant.type, variant.get(value))
}

/** [value] of [type] as a step names it: a struct as `Name[field=value, ...]`, anything else as itself. */
@Suppress("UNCHECKED_CAST")
private fun said(
    type: TypeDescriptor.Reflective<*>,
    value: Any?,
): String {
    val struct = type as? StructDescriptor.Reflective<Any?, *> ?: return value.toString()
    return struct.fields.joinToString(", ", "${struct.name}[", "]") { field ->
        val name =
            field.name
                .split('_')
                .mapIndexed { index, part ->
                    if (index ==
                        0
                    ) {
                        part
                    } else {
                        part.replaceFirstChar(Char::uppercase)
                    }
                }.joinToString("")
        "$name=${said(field.type, (field as StructField.Reflective<Any?, *, *>).get(value))}"
    }
}
