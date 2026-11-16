package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.AttemptStep
import com.typewritermc.playtest.wire.Message.BarrierSeen
import com.typewritermc.playtest.wire.Message.Capture
import com.typewritermc.playtest.wire.Message.Captured
import com.typewritermc.playtest.wire.Message.Declined
import com.typewritermc.playtest.wire.Message.End
import com.typewritermc.playtest.wire.Message.Ended
import com.typewritermc.playtest.wire.Message.Hello
import com.typewritermc.playtest.wire.Message.Input
import com.typewritermc.playtest.wire.Message.InputDone
import com.typewritermc.playtest.wire.Message.InputStep
import com.typewritermc.playtest.wire.Message.Kind
import com.typewritermc.playtest.wire.Message.Lease
import com.typewritermc.playtest.wire.Message.Marks
import com.typewritermc.playtest.wire.Message.Perceived
import com.typewritermc.playtest.wire.Message.Probe
import com.typewritermc.playtest.wire.Message.ProbeAction
import com.typewritermc.playtest.wire.Message.ProbeDone
import com.typewritermc.playtest.wire.Message.Query
import com.typewritermc.playtest.wire.Message.Queue
import com.typewritermc.playtest.wire.Message.Reclaim
import com.typewritermc.playtest.wire.Message.Refused
import com.typewritermc.playtest.wire.Message.Renderer
import com.typewritermc.playtest.wire.Message.Reply
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Role
import com.typewritermc.playtest.wire.Message.Settle
import com.typewritermc.playtest.wire.Message.ClipStarted
import com.typewritermc.playtest.wire.Message.ClipWritten
import com.typewritermc.playtest.wire.Message.CoveredClass
import com.typewritermc.playtest.wire.Message.StartClip
import com.typewritermc.playtest.wire.Message.StopClip
import com.typewritermc.playtest.wire.Message.Settled
import com.typewritermc.playtest.wire.Message.Submit
import com.typewritermc.playtest.wire.Wire
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.supervisorScope
import kotlinx.coroutines.withContext
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.IOException
import java.net.Socket
import java.nio.file.Path
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
    private val leases = ConcurrentHashMap<Long, Leasing>()
    private val replies = ConcurrentHashMap<Long, CompletableDeferred<Reply>>()
    private val settles = ConcurrentHashMap<Long, CompletableDeferred<Settled>>()
    private val attempts = ConcurrentHashMap<String, Attempt>()
    private val attemptsOf = ConcurrentHashMap<String, Int>()

    /** This project's goldens and the local golden images. */
    val goldens = Goldens(settings.root, settings.goldens, settings.goldenImages, PinnedRenderer(settings.mesa))
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
            planned.map { submissions.incrementAndGet() to Leasing(RequirementCode.of(it.bodies.first()), it.restartsPaper) }
        for ((submission, leasing) in leasings) {
            leases[submission] = leasing
            broken?.let(leasing.attempt::completeExceptionally)
        }
        try {
            send(
                Queue(
                    planned.zip(leasings) { it, (submission, _) ->
                        Submit(submission, it.testId, it.requirement, it.players, it.demonstrates, it.restartsPaper, it.demo)
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
        submission: Long,
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
        val steps = mutableListOf<AttemptStep>()
        val evidence =
            Evidence(
                settings.testRun.toAbsolutePath().parent,
                planned.testId,
                if (planned.demo) "demo" else "attempt-${attemptsOf.merge(planned.testId, 1, Int::plus)}",
            )
        for ((index, body) in planned.bodies.withIndex()) {
            if (index > 0) {
                attempt.players.forEach { attempts.remove(it.name) }
                attempt = lease(submission, leasing) { send(Reclaim(submission)) }
            }
            attempt.evidence = evidence
            val clips = mutableMapOf<GamePlayer, String>()
            val notStarted = if (planned.demo) startClips(attempt, if (planned.bodies.size > 1) "-${index + 1}" else "", clips) else null
            val settled = settle(submission, attempt, notStarted ?: run(attempt, body))
            val notWritten = stopClips(attempt, clips)
            failure = settled.failure?.let(attempt::located) ?: notWritten
            covered = settled.covered
            steps += attempt.steps
            if (failure != null) break
        }
        attempt.players.forEach { attempts.remove(it.name) }
        val millis = (System.nanoTime() - started) / 1_000_000
        send(
            Result(
                submission,
                millis,
                failure?.described,
                failure?.let {
                    attempt.requirementLine(it.stackTrace)
                        ?: (it as? WindowMissed)?.at
                },
                steps,
                if (evidence.screenshots.isEmpty() && evidence.clips.isEmpty()) "" else evidence.folder,
                evidence.screenshots,
                evidence.clips,
            ),
        )
        return AttemptEnd(failure, covered)
    }

    /** Waits for the lease of [submission] that [ask] asks the pool for. */
    private suspend fun lease(
        submission: Long,
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

    /** Runs [body] on [attempt]; returns why it failed, or null. */
    private suspend fun run(
        attempt: Attempt,
        body: suspend RequirementScope.() -> Unit,
    ): Throwable? =
        try {
            RequirementScope(attempt).body()
            null
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
        submission: Long,
        attempt: Attempt,
        failure: Throwable?,
    ): AttemptEnd {
        // A cancelled body still ends its attempt, so the pool hears the result and frees its players.
        val at = System.currentTimeMillis()
        val settled = withContext(NonCancellable) { waitFor(settles, submission) { send(Settle(submission)) } }
        attempt.took(at, "settle ${attempt.players.joinToString { it.name }}")
        val untaken = attempt.untakenFailures().firstOrNull() ?: return AttemptEnd(failure, settled.covered())
        failure?.let(untaken::addSuppressed)
        return AttemptEnd(untaken, settled.covered())
    }

    /** Kills and boots again the own Paper of [submission]'s attempt; returns the new Paper's tick after which every player is back. */
    suspend fun restart(submission: Long): Int = request<Message.Restarted> { request -> Message.Restart(request, submission) }.tick()

    /** The kinds of state [player] carries a mark of, as Paper sees them. */
    suspend fun query(player: GamePlayer): List<Kind> {
        val answer = request<Marks> { request -> Query(request, player.uuid) }
        answer.failure()?.let { throw ProbeFailed(it) }
        return answer.marked()
    }

    /** Paper runs [action] for [players]; returns, once each of their clients holds its effect, the tick after which it ran. */
    suspend fun probe(
        players: List<GamePlayer>,
        action: ProbeAction,
    ): Int {
        val done = request<ProbeDone> { request -> Probe(request, players.map { it.uuid }, action) }
        done.failure()?.let { throw ProbeFailed(it) }
        return done.tick()
    }

    /** [player]'s client runs [steps]; returns the tick after which their first event reached the client. */
    suspend fun input(
        player: GamePlayer,
        steps: List<InputStep>,
    ): Int {
        val done = request<InputDone> { request -> Input(request, player.uuid, steps) }
        done.failure()?.let { throw InputFailed(it) }
        return done.tick()
    }

    /**
     * Every player's client of [attempt] records a clip from the next tick on, into the attempt's
     * evidence as `clips/<player><suffix>.mp4`, and each clip that started joins [started]; returns why a
     * clip did not start, or null.
     */
    private suspend fun startClips(
        attempt: Attempt,
        suffix: String,
        started: MutableMap<GamePlayer, String>,
    ): ClipFailed? {
        for (player in attempt.players) {
            val clip = "clips/${player.name}$suffix.mp4"
            val answer = request<ClipStarted> { request -> StartClip(request, player.uuid, attempt.evidence.file(clip).toString()) }
            answer.failure()?.let { return ClipFailed("${player.name}'s clip did not start: $it") }
            started[player] = clip
        }
        return null
    }

    /** Each client of [clips] finishes its clip, which joins the attempt's evidence; returns why one could not, or null. */
    private suspend fun stopClips(
        attempt: Attempt,
        clips: Map<GamePlayer, String>,
    ): ClipFailed? {
        var failed: ClipFailed? = null
        for ((player, clip) in clips) {
            val written = request<ClipWritten> { request -> StopClip(request, player.uuid) }
            val failure = written.failure()
            if (failure == null) attempt.evidence.clips += clip else failed = failed ?: ClipFailed("${player.name}'s clip was not written: $failure")
        }
        return failed
    }

    /** [player]'s client draws the frame it holds now and writes it as a PNG to [png]; returns the renderer that drew it. */
    suspend fun capture(
        player: GamePlayer,
        png: Path,
    ): Renderer {
        val captured = request<Captured> { request -> Capture(request, player.uuid, png.toString()) }
        captured.failure()?.let { throw FrameNotCaptured(it) }
        return captured.renderer()
    }

    /** Ends the session: the pool writes this session's cases into the run file. */
    suspend fun end() {
        send(End(settings.run, settings.testRun.toString(), RunPlan.current.policy))
        ended.await()
        socket.close()
    }

    /** Sends the request [message] builds from a fresh request id and returns its [Reply]. */
    private suspend inline fun <reified T : Reply> request(crossinline message: (Long) -> Message): T {
        val request = requests.incrementAndGet()
        return waitFor(replies, request) { send(message(request)) } as T
    }

    private suspend fun <T> waitFor(
        pending: ConcurrentHashMap<Long, CompletableDeferred<T>>,
        key: Long,
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
            is Lease -> {
                leases[message.submission()]?.let { leasing -> leasing.attempt.complete(start(message, leasing)) }
            }

            is Declined -> {
                leases[message.submission()]?.attempt?.completeExceptionally(RequirementDeclined(message.reason()))
            }

            is Message.LeaseFailed -> {
                leases[message.submission()]?.attempt?.completeExceptionally(PaperLost(message.reason()))
            }

            is Reply -> {
                replies[message.request()]?.complete(message)
            }

            is Message.PlayerEvent -> {
                deliver(message)
            }

            is Settled -> {
                settles[message.id()]?.complete(message)
            }

            is Refused -> {
                fail(GameUnavailable(message.reason()))
            }

            is Ended -> {
                ended.complete(Unit)
            }

            else -> {
                fail(GameUnavailable("the game pool sent ${message.javaClass.simpleName}, which a session never receives"))
            }
        }
    }

    /** Hands [message] to the attempt that holds its player; nobody holds a released player. */
    private fun deliver(message: Message.PlayerEvent) {
        val attempt = attempts[message.player()] ?: return
        val player = attempt.player(message.player())
        attempt.deliver(
            when (message) {
                is Perceived -> Attempt.Event.Perceived(player, message.perception())
                is BarrierSeen -> Attempt.Event.Barrier(player, message.barrier())
                is Message.WorkHung -> Attempt.Event.Failed(player, WorkHung(player.name, message.work(), message.beganAfter()))
                is Message.ClientLost -> Attempt.Event.Failed(player, ClientLost(player.name, message.reason()))
                is Message.PaperLost -> Attempt.Event.Failed(player, PaperLost(message.reason()))
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
                lease.submission(),
                lease.players().map { GamePlayer(it.name(), it.uuid()) },
                lease.region(),
                lease.paper(),
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
            session.send(Hello(Role.SESSION, settings.run))
            thread(name = "playtest-session", isDaemon = true) { session.read() }
            return session
        }
    }
}
