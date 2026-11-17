package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Wire
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.supervisorScope
import kotlinx.coroutines.withContext
import skirout.harness.v1.test_run.CoveredClass
import skirout.harness.v1.test_run.Demonstrates
import skirout.harness.v1.test_run.Step
import skirout.harness.v1.wire.Answer
import skirout.harness.v1.wire.Ask
import skirout.harness.v1.wire.ClientTask
import skirout.harness.v1.wire.Hello
import skirout.harness.v1.wire.InputStep
import skirout.harness.v1.wire.Lease
import skirout.harness.v1.wire.Message
import skirout.harness.v1.wire.PaperAsk
import skirout.harness.v1.wire.PlayerEvent
import skirout.harness.v1.wire.Probe
import skirout.harness.v1.wire.ProbeAction
import skirout.harness.v1.wire.Renderer
import skirout.harness.v1.wire.Request
import skirout.harness.v1.wire.Result
import skirout.harness.v1.wire.Role
import skirout.harness.v1.wire.StateKind
import skirout.harness.v1.wire.Submit
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.IOException
import java.net.Socket
import java.nio.file.Path
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import kotlin.concurrent.thread

/** The game could not run a requirement; [message] says why and where the logs are. */
class GameUnavailable(
    message: String,
    cause: Throwable? = null,
) : IllegalStateException(message, cause)

/** The pool can never run this requirement, for example since it claims more players than the pool holds. */
class RequirementDeclined(
    message: String,
) : RequirementRefused(message)

/** A probe could not arrange what the requirement asked for; [message] says why. */
class ProbeFailed(
    message: String,
) : AssertionError(message)

/** The client could not perform an input as a person would; [message] says which step failed. */
class InputFailed(
    message: String,
) : AssertionError(message)

/** The player's frame is not the golden it names, or none is approved; [message] says how and where the frame and its diff lie. */
class GoldenDiffers(
    message: String,
) : AssertionError(message)

/** A client could not record or write the clip of a demo; [message] says why. */
class ClipFailed(
    message: String,
) : AssertionError(message)

/** The client could not draw or write the frame a golden asked for; [message] says why. */
class FrameNotCaptured(
    message: String,
) : AssertionError(message)

/**
 * One test JVM's connection to the game pool. Requirements submit through it, and it routes what the
 * pool sends back: leases to the waiting submission, probe replies to the waiting call, and each
 * leased player's perception stream to the attempt holding that player.
 */
internal class PoolSession private constructor(
    private val socket: Socket,
    private val settings: PlaytestSettings,
) {
    private val output = DataOutputStream(BufferedOutputStream(socket.getOutputStream()))
    private val submissions = AtomicLong()
    private val requests = AtomicLong()
    private val barriers = AtomicInteger()
    private val leases = ConcurrentHashMap<SubmissionId, Leasing>()
    private val replies = ConcurrentHashMap<Long, CompletableDeferred<Answer>>()
    private val settles = ConcurrentHashMap<SubmissionId, CompletableDeferred<Message.Settled>>()
    private val restarts = ConcurrentHashMap<Long, Attempt>()
    private val attempts = ConcurrentHashMap<String, Attempt>()
    private val attemptsOf = ConcurrentHashMap<String, Int>()

    /** This project's goldens and the local golden images. */
    val goldens = Goldens(settings.root, settings.goldens, settings.goldenImages, PinnedRenderer(settings.mesa, settings.pinnedRunner))
    private val ended = CompletableDeferred<Unit>()

    @Volatile
    private var broken: GameUnavailable? = null

    /**
     * A submission waiting for its lease. The reader thread starts its [Attempt] as the lease arrives,
     * so the records that follow the lease find it.
     */
    private class Leasing(
        val requirementCode: RequirementCode,
        val restartsPaper: Boolean,
    ) {
        val attempt = CompletableDeferred<Attempt>()
    }

    fun send(message: Message) {
        broken?.let { throw it }
        synchronized(output) { Wire.write(output, message) }
    }

    fun nextBarrier(): Int = barriers.incrementAndGet()

    /**
     * One attempt of a requirement to run: [bodies] in order on [players] players, on a Paper of its own
     * with [restartsPaper]. A [demo] runs after the requirement's last attempt with its clients recording
     * clips, and lands in the case's demo.
     */
    class Planned(
        val testId: String,
        val requirement: String,
        val players: Int,
        val demonstrates: Demonstrates,
        val bodies: List<suspend RequirementScope.() -> Unit>,
        val restartsPaper: Boolean = false,
        val demo: Boolean = false,
    )

    /** How one attempt ended: why it failed, or null, and the plugin code it covered by its last settle. */
    class AttemptEnd(
        val failure: Throwable?,
        val covered: List<CoveredClass> = listOf(),
    )

    /**
     * Runs one attempt of a requirement: waits for its lease and runs its bodies in order, then reports
     * the outcome. Before each body after the first, the pool releases and claims the same players
     * again, as the next attempt would get them: wiped and in a new region. Returns how it ended.
     */
    suspend fun attempt(planned: Planned): AttemptEnd = sideBySide(listOf(planned)).single()

    /**
     * Runs [planned] side by side, each as an attempt of its own: the pool claims and leases all their
     * players at the same moment. Every attempt runs to its own end; returns how each ended.
     */
    suspend fun sideBySide(planned: List<Planned>): List<AttemptEnd> {
        val leasings =
            planned.map { SubmissionId(submissions.incrementAndGet()) to Leasing(RequirementCode.of(it.bodies.first()), it.restartsPaper) }
        for ((submission, leasing) in leasings) {
            leases[submission] = leasing
            broken?.let(leasing.attempt::completeExceptionally)
        }
        try {
            send(
                Message.createQueue(
                    together =
                        planned.zip(leasings) { it, (submission, _) ->
                            Submit(
                                submission = submission.value,
                                testId = it.testId,
                                requirement = it.requirement,
                                players = it.players,
                                demonstrates = it.demonstrates,
                                restartsPaper = it.restartsPaper,
                                demo = it.demo,
                            )
                        },
                ),
            )
        } catch (unavailable: GameUnavailable) {
            leasings.forEach { (_, leasing) -> leasing.attempt.completeExceptionally(unavailable) }
        }
        return supervisorScope {
            planned
                .zip(leasings) { it, (submission, leasing) -> async { runAttempt(submission, leasing, it) } }
                .awaitAll()
        }
    }

    /** Runs [planned]'s bodies once [leasing] holds its lease; returns how the attempt ended. */
    private suspend fun runAttempt(
        submission: SubmissionId,
        leasing: Leasing,
        planned: Planned,
    ): AttemptEnd {
        var attempt =
            try {
                leasing.attempt.await()
            } catch (
                @Suppress("TooGenericExceptionCaught") unleased: Throwable,
            ) {
                return AttemptEnd(unleased)
            } finally {
                leases.remove(submission)
            }
        val started = System.nanoTime()
        var failure: Throwable? = null
        var covered = listOf<CoveredClass>()
        val steps = mutableListOf<Step>()
        val evidence =
            Evidence(
                settings.testRun.toAbsolutePath().parent,
                planned.testId,
                if (planned.demo) "demo" else "attempt-${attemptsOf.merge(planned.testId, 1, Int::plus)}",
            )
        for ((index, body) in planned.bodies.withIndex()) {
            if (index > 0) {
                attempt.players.forEach { attempts.remove(it.name) }
                attempt = lease(submission, leasing) { send(Message.createReclaim(submission = submission.value)) }
            }
            attempt.evidence = evidence
            val ended = runBody(submission, attempt, body, if (planned.demo) clipSuffix(planned, index) else null)
            failure = ended.failure
            covered = ended.covered
            steps += attempt.steps
            if (failure != null) break
        }
        attempt.players.forEach { attempts.remove(it.name) }
        send(Message.ResultWrapper(result(submission, attempt, failure, (System.nanoTime() - started) / 1_000_000, steps, evidence)))
        return AttemptEnd(failure, covered)
    }

    /** What [submission]'s attempt reports to the pool once it ended with [failure] after [millis]. */
    private fun result(
        submission: SubmissionId,
        attempt: Attempt,
        failure: Throwable?,
        millis: Long,
        steps: List<Step>,
        evidence: Evidence,
    ): Result =
        Result(
            submission = submission.value,
            durationMillis = millis,
            failure = failure?.described,
            firstBroken = failure?.let { attempt.requirementLine(it.stackTrace) ?: (it as? WindowMissed)?.at },
            steps = steps,
            folder = if (evidence.screenshots.isEmpty() && evidence.clips.isEmpty()) "" else evidence.folder,
            screenshots = evidence.screenshots,
            clips = evidence.clips,
        )

    /**
     * Runs [body] on [attempt] and settles it; with a [clip] suffix, every player's client records the
     * body as a clip named with it. Returns how the body ended.
     */
    private suspend fun runBody(
        submission: SubmissionId,
        attempt: Attempt,
        body: suspend RequirementScope.() -> Unit,
        clip: String?,
    ): AttemptEnd {
        val notStarted = clip?.let { attempt.startClips(it) }
        val settled = settle(submission, attempt, notStarted ?: run(attempt, body))
        val notWritten = clip?.let { attempt.stopClips() }
        return AttemptEnd(settled.failure?.let(attempt::located) ?: notWritten, settled.covered)
    }

    /** What sets the clips of [planned]'s body [index] apart: nothing for a single body. */
    private fun clipSuffix(
        planned: Planned,
        index: Int,
    ): String = if (planned.bodies.size > 1) "-${index + 1}" else ""

    /** Waits for the lease of [submission] that [ask] asks the pool for. */
    private suspend fun lease(
        submission: SubmissionId,
        first: Leasing,
        ask: () -> Unit,
    ): Attempt {
        val leasing = Leasing(first.requirementCode, first.restartsPaper)
        leases[submission] = leasing
        broken?.let { leasing.attempt.completeExceptionally(it) }
        return try {
            ask()
            leasing.attempt.await()
        } finally {
            leases.remove(submission)
        }
    }

    /** Runs [body] on [attempt]; returns why it failed, or null. A body that made no positive check fails. */
    private suspend fun run(
        attempt: Attempt,
        body: suspend RequirementScope.() -> Unit,
    ): Throwable? =
        try {
            RequirementScope(attempt).body()
            bodyEnded(failure = null, proved = attempt.proved)
        } catch (cancelled: CancellationException) {
            cancelled
        } catch (
            @Suppress("TooGenericExceptionCaught") failed: Throwable,
        ) {
            failed
        }

    /**
     * Waits until the work plugins count for the attempt's players is quiet, so none of it reaches the
     * next attempt on those players; returns how the attempt ended: failed by hung work or a lost
     * client the body never met first, else by [failure], and what it covered so far.
     */
    private suspend fun settle(
        submission: SubmissionId,
        attempt: Attempt,
        failure: Throwable?,
    ): AttemptEnd {
        // A cancelled body still ends its attempt, so the pool hears the result and frees its players.
        val at = System.currentTimeMillis()
        val settled = withContext(NonCancellable) { waitFor(settles, submission) { send(Message.createSettle(id = submission.value)) } }
        attempt.took(at, "settle ${attempt.players.joinToString { it.name }}")
        val untaken = attempt.untakenFailures().firstOrNull() ?: return AttemptEnd(failure, settled.covered)
        failure?.let(untaken::addSuppressed)
        return AttemptEnd(untaken, settled.covered)
    }

    /**
     * Kills and boots again the own Paper of [attempt], which runs [submission]; returns the new Paper's
     * tick after which every player is back. The attempt hears it is back as the answer is read, before
     * any record the new Paper sends.
     */
    suspend fun restart(
        attempt: Attempt,
        submission: SubmissionId,
    ): Int {
        var asked = 0L
        try {
            val restarted =
                answer<Answer.RestartedWrapper>(requests.incrementAndGet()) { request ->
                    asked = request
                    restarts[request] = attempt
                    Message.createRestart(request = request, submission = submission.value)
                }
            return restarted.value.tick
        } finally {
            restarts.remove(asked)
        }
    }

    /** The kinds of state [player] carries a mark of, as Paper sees them. */
    suspend fun query(player: GamePlayer): List<StateKind> {
        val marks = request<Answer.MarksWrapper>(Ask.PaperWrapper(PaperAsk.createQuery(player = player.uuid.toString()))).value
        marks.failure?.let { throw ProbeFailed(it) }
        return marks.marked
    }

    /** Paper runs [action] for [players]; returns, once each of their clients holds its effect, the tick after which it ran. */
    suspend fun probe(
        players: List<GamePlayer>,
        action: ProbeAction,
    ): Int {
        val probe = Probe(players = players.map { it.uuid.toString() }, action = action)
        val done = request<Answer.ProbeDoneWrapper>(Ask.PaperWrapper(PaperAsk.ProbeWrapper(probe))).value
        done.failure?.let { throw ProbeFailed(it) }
        return done.tick
    }

    /** [player]'s client runs [steps]; returns the tick after which their first event reached the client. */
    suspend fun input(
        player: GamePlayer,
        steps: List<InputStep>,
    ): Int {
        val done = request<Answer.InputDoneWrapper>(player, ClientTask.createInput(steps = steps)).value
        done.failure?.let { throw InputFailed(it) }
        return done.tick
    }

    /** [player]'s client records a clip from the next tick on and writes it as an mp4 to [mp4]. */
    suspend fun startClip(
        player: GamePlayer,
        mp4: Path,
    ): Answer.ClipStarted = request<Answer.ClipStartedWrapper>(player, ClientTask.createStartClip(path = mp4.toString())).value

    /** [player]'s client finishes its clip. */
    suspend fun stopClip(player: GamePlayer): Answer.ClipWritten = request<Answer.ClipWrittenWrapper>(player, ClientTask.STOP_CLIP).value

    /** [player]'s client draws the frame it holds now and writes it as a PNG to [png]; returns the renderer that drew it. */
    suspend fun capture(
        player: GamePlayer,
        png: Path,
    ): Renderer {
        val captured = request<Answer.CapturedWrapper>(player, ClientTask.createCapture(path = png.toString())).value
        captured.failure?.let { throw FrameNotCaptured(it) }
        return captured.renderer
    }

    /** Ends the session: once every session of the run ended, the pool marks the run file ended. */
    suspend fun end() {
        send(Message.END)
        ended.await()
        socket.close()
    }

    /** Asks [player]'s client to run [task] under a fresh request id and returns its answer. */
    private suspend inline fun <reified T : Answer> request(
        player: GamePlayer,
        task: ClientTask,
    ): T = request(Ask.createClient(player = player.uuid.toString(), task = task))

    /** Asks the game [ask] under a fresh request id and returns its answer. */
    private suspend inline fun <reified T : Answer> request(ask: Ask): T =
        answer(requests.incrementAndGet()) { request -> Message.RequestWrapper(Request(id = request, ask = ask)) }

    /** Sends the message [message] builds from [request] and returns the answer to it, which must be a [T]. */
    private suspend inline fun <reified T : Answer> answer(
        request: Long,
        crossinline message: (Long) -> Message,
    ): T =
        when (val answer = waitFor(replies, request) { send(message(request)) }) {
            is T -> answer
            else -> throw GameUnavailable("the game answered request $request with ${answer.kind}, which does not answer it")
        }

    private suspend fun <K : Any, T> waitFor(
        pending: ConcurrentHashMap<K, CompletableDeferred<T>>,
        key: K,
        ask: () -> Unit,
    ): T {
        val reply = CompletableDeferred<T>()
        pending[key] = reply
        broken?.let { reply.completeExceptionally(it) }
        ask()
        return try {
            reply.await()
        } finally {
            pending.remove(key)
        }
    }

    private fun read() {
        val input = DataInputStream(BufferedInputStream(socket.getInputStream()))
        try {
            while (true) dispatch(Wire.read(input))
        } catch (closed: IOException) {
            if (!ended.isCompleted) {
                fail(
                    GameUnavailable("the game pool broke the connection before the run ended; see ${settings.poolLog}", closed),
                )
            }
        }
    }

    private fun dispatch(message: Message) {
        when (message) {
            is Message.LeaseWrapper -> {
                val lease = message.value
                leases[SubmissionId(lease.submission)]?.let { leasing -> leasing.attempt.complete(start(lease, leasing)) }
            }

            is Message.DeclinedWrapper -> {
                val declined = message.value
                leases[SubmissionId(declined.submission)]?.attempt?.completeExceptionally(RequirementDeclined(declined.reason))
            }

            is Message.LeaseFailedWrapper -> {
                val failed = message.value
                leases[SubmissionId(failed.submission)]?.attempt?.completeExceptionally(PaperLost(failed.reason))
            }

            is Message.ReplyWrapper -> {
                val reply = message.value
                if (reply.answer is Answer.RestartedWrapper) restarts.remove(reply.request)?.restarted()
                replies[reply.request]?.complete(reply.answer)
            }

            is Message.PlayerEventWrapper -> {
                deliver(message.value)
            }

            is Message.SettledWrapper -> {
                settles[SubmissionId(message.value.id)]?.complete(message.value)
            }

            is Message.RefusedWrapper -> {
                fail(GameUnavailable(message.value.reason))
            }

            Message.ENDED -> {
                ended.complete(Unit)
            }

            else -> {
                fail(GameUnavailable("the game pool sent ${message.kind}, which a session never receives"))
            }
        }
    }

    /** Hands [event] to the attempt that holds its player; nobody holds a released player. */
    private fun deliver(event: PlayerEvent) {
        val attempt = attempts[event.player] ?: return
        val player = attempt.player(event.player)
        val happened = event.happened
        attempt.deliver(
            when (happened) {
                is PlayerEvent.Happened.PerceivedWrapper -> {
                    Attempt.Event.Perceived(player, happened.value)
                }

                is PlayerEvent.Happened.BarrierSeenWrapper -> {
                    Attempt.Event.Barrier(player, happened.value.barrier)
                }

                is PlayerEvent.Happened.WorkHungWrapper -> {
                    Attempt.Event.Failed(player, WorkHung(player.name, happened.value.work, happened.value.beganAfter))
                }

                is PlayerEvent.Happened.ClientLostWrapper -> {
                    Attempt.Event.Failed(player, ClientLost(player.name, happened.value.reason))
                }

                is PlayerEvent.Happened.PaperLostWrapper -> {
                    Attempt.Event.Failed(player, PaperLost(happened.value.reason))
                }

                is PlayerEvent.Happened.LeaseExpiredWrapper -> {
                    Attempt.Event.Failed(player, LeaseExpired(happened.value.reason))
                }

                else -> {
                    return fail(GameUnavailable("the game pool sent ${happened.kind} for ${event.player}, which this build does not know"))
                }
            },
        )
    }

    private fun fail(cause: GameUnavailable) {
        broken = cause
        leases.values.forEach { it.attempt.completeExceptionally(cause) }
        replies.values.forEach { it.completeExceptionally(cause) }
        settles.values.forEach { it.completeExceptionally(cause) }
        attempts.values.forEach { it.fail(cause) }
        ended.completeExceptionally(cause)
    }

    private fun start(
        lease: Lease,
        leasing: Leasing,
    ): Attempt {
        val attempt =
            Attempt(
                this,
                SubmissionId(lease.submission),
                lease.players.map { GamePlayer(it.name, UUID.fromString(it.uuid)) },
                lease.region,
                lease.paper,
                leasing.requirementCode,
                leasing.restartsPaper,
            )
        attempt.players.forEach { attempts[it.name] = attempt }
        return attempt
    }

    private fun Attempt.player(name: String): GamePlayer = players.first { it.name == name }

    companion object {
        /** Connects to the worktree's game pool, starting it when none runs. */
        fun open(settings: PlaytestSettings = PlaytestSettings.fromSystemProperties()): PoolSession {
            val socket = PoolLauncher(settings).connect()
            val session = PoolSession(socket, settings)
            session.send(Message.HelloWrapper(Hello(role = Role.SESSION, name = settings.run)))
            // The pool writes the run's file after every attempt, so it needs the file before the first.
            session.send(Message.createJoin(testRunFile = settings.testRun.toString(), policy = RunPlan.current.policy))
            thread(name = "playtest-session", isDaemon = true) { session.read() }
            return session
        }
    }
}
