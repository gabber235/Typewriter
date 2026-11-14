package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.BarrierSeen
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
import com.typewritermc.playtest.wire.Message.Reclaim
import com.typewritermc.playtest.wire.Message.Refused
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Role
import com.typewritermc.playtest.wire.Message.Settle
import com.typewritermc.playtest.wire.Message.Settled
import com.typewritermc.playtest.wire.Message.Submit
import com.typewritermc.playtest.wire.Wire
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.withContext
import java.io.BufferedInputStream
import java.io.BufferedOutputStream
import java.io.DataInputStream
import java.io.DataOutputStream
import java.io.IOException
import java.net.Socket
import java.net.URL
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
) : AssertionError(message)

/** A probe could not arrange what the requirement asked for; [message] says why. */
class ProbeFailed(
    message: String,
) : AssertionError(message)

/** The client could not perform an input as a person would; [message] says which step failed. */
class InputFailed(
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
    private val probes = ConcurrentHashMap<Long, CompletableDeferred<ProbeDone>>()
    private val inputs = ConcurrentHashMap<Long, CompletableDeferred<InputDone>>()
    private val queries = ConcurrentHashMap<Long, CompletableDeferred<Marks>>()
    private val settles = ConcurrentHashMap<Long, CompletableDeferred<Settled>>()
    private val attempts = ConcurrentHashMap<String, Attempt>()
    private val ended = CompletableDeferred<Unit>()

    @Volatile
    private var broken: GameUnavailable? = null

    /**
     * A submission waiting for its lease. The reader thread starts its [Attempt] as the lease arrives,
     * so the records that follow the lease find it.
     */
    private class Leasing(
        val requirementCode: URL?,
    ) {
        val attempt = CompletableDeferred<Attempt>()
    }

    fun send(message: Message) {
        broken?.let { throw it }
        synchronized(output) { Wire.write(output, message) }
    }

    fun nextBarrier(): Int = barriers.incrementAndGet()

    /**
     * Runs one attempt of a requirement: waits for its lease and runs [bodies] in order, then reports the
     * outcome. Before each body after the first, the pool releases and claims the same players again, as
     * the next attempt would get them: wiped and in a new region.
     */
    suspend fun attempt(
        testId: String,
        requirement: String,
        players: Int,
        bodies: List<suspend RequirementScope.() -> Unit>,
    ) {
        val submission = submissions.incrementAndGet()
        val code =
            bodies
                .first()
                .javaClass.protectionDomain.codeSource
                ?.location
        var attempt = lease(submission, code) { send(Submit(submission, testId, requirement, players)) }
        val started = System.nanoTime()
        var failure: Throwable? = null
        for ((index, body) in bodies.withIndex()) {
            if (index > 0) {
                attempt.players.forEach { attempts.remove(it.name) }
                attempt = lease(submission, code) { send(Reclaim(submission)) }
            }
            failure = settle(submission, attempt, run(attempt, body))
            if (failure != null) break
        }
        attempt.players.forEach { attempts.remove(it.name) }
        val millis = (System.nanoTime() - started) / 1_000_000
        send(
            Result(
                submission,
                millis,
                failure?.let(::describe),
                failure?.let {
                    attempt.requirementLine(it.stackTrace)
                        ?: (it as? WindowMissed)?.at
                },
            ),
        )
        failure?.let { throw it }
    }

    /** Waits for the lease of [submission] that [ask] asks the pool for. */
    private suspend fun lease(
        submission: Long,
        code: URL?,
        ask: () -> Unit,
    ): Attempt {
        val leasing = Leasing(code)
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
     * next attempt on those players; returns why the attempt failed: hung work or a lost client the
     * body never met first, else [failure].
     */
    private suspend fun settle(
        submission: Long,
        attempt: Attempt,
        failure: Throwable?,
    ): Throwable? {
        // A cancelled body still ends its attempt, so the pool hears the result and frees its players.
        withContext(NonCancellable) { waitFor(settles, submission) { send(Settle(submission)) } }
        val untaken = attempt.untakenFailures().firstOrNull() ?: return failure
        failure?.let(untaken::addSuppressed)
        return untaken
    }

    /** The kinds of state [player] carries a mark of, as Paper sees them. */
    suspend fun query(player: GamePlayer): List<Kind> {
        val request = requests.incrementAndGet()
        val answer = waitFor(queries, request) { send(Query(request, player.uuid)) }
        answer.failure()?.let { throw ProbeFailed(it) }
        return answer.marked()
    }

    /** Paper runs [action] for [players]; returns, once each of their clients holds its effect, the tick after which it ran. */
    suspend fun probe(
        players: List<GamePlayer>,
        action: ProbeAction,
    ): Int {
        val request = requests.incrementAndGet()
        val done = waitFor(probes, request) { send(Probe(request, players.map { it.uuid }, action)) }
        done.failure()?.let { throw ProbeFailed(it) }
        return done.tick()
    }

    /** [player]'s client runs [steps]; returns the tick after which their first event reached the client. */
    suspend fun input(
        player: GamePlayer,
        steps: List<InputStep>,
    ): Int {
        val request = requests.incrementAndGet()
        val done = waitFor(inputs, request) { send(Input(request, player.uuid, steps)) }
        done.failure()?.let { throw InputFailed(it) }
        return done.tick()
    }

    /** Ends the session: the pool writes this session's cases into the run file. */
    suspend fun end() {
        send(End(settings.run, settings.testRun.toString()))
        ended.await()
        socket.close()
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

            is ProbeDone -> {
                probes[message.request()]?.complete(message)
            }

            is InputDone -> {
                inputs[message.request()]?.complete(message)
            }

            is Marks -> {
                queries[message.request()]?.complete(message)
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
            },
        )
    }

    private fun fail(cause: GameUnavailable) {
        broken = cause
        leases.values.forEach { it.attempt.completeExceptionally(cause) }
        probes.values.forEach { it.completeExceptionally(cause) }
        inputs.values.forEach { it.completeExceptionally(cause) }
        queries.values.forEach { it.completeExceptionally(cause) }
        settles.values.forEach { it.completeExceptionally(cause) }
        attempts.values.forEach { it.fail(cause) }
        ended.completeExceptionally(cause)
    }

    private fun start(
        lease: Lease,
        leasing: Leasing,
    ): Attempt {
        val attempt = Attempt(this, lease.players().map { GamePlayer(it.name(), it.uuid()) }, lease.region(), leasing.requirementCode)
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

        private fun describe(failure: Throwable): String =
            if (failure is AssertionError) failure.message ?: failure.toString() else failure.toString()
    }
}
