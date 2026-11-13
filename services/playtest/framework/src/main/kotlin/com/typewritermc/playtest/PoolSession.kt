package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.BarrierSeen
import com.typewritermc.playtest.wire.Message.End
import com.typewritermc.playtest.wire.Message.Ended
import com.typewritermc.playtest.wire.Message.Hello
import com.typewritermc.playtest.wire.Message.Input
import com.typewritermc.playtest.wire.Message.InputDone
import com.typewritermc.playtest.wire.Message.InputStep
import com.typewritermc.playtest.wire.Message.Lease
import com.typewritermc.playtest.wire.Message.Perceived
import com.typewritermc.playtest.wire.Message.Probe
import com.typewritermc.playtest.wire.Message.ProbeAction
import com.typewritermc.playtest.wire.Message.ProbeDone
import com.typewritermc.playtest.wire.Message.Refused
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Role
import com.typewritermc.playtest.wire.Message.Submit
import com.typewritermc.playtest.wire.Wire
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CompletableDeferred
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

    /** Runs one attempt of a requirement: waits for its lease, runs [body] and reports the outcome. */
    suspend fun attempt(
        testId: String,
        requirement: String,
        body: suspend RequirementScope.() -> Unit,
    ) {
        val submission = submissions.incrementAndGet()
        val leasing =
            Leasing(
                body.javaClass.protectionDomain.codeSource
                    ?.location,
            )
        leases[submission] = leasing
        broken?.let { leasing.attempt.completeExceptionally(it) }
        val attempt =
            try {
                send(Submit(submission, testId, requirement))
                leasing.attempt.await()
            } finally {
                leases.remove(submission)
            }
        val started = System.nanoTime()
        val failure =
            try {
                RequirementScope(attempt.players, attempt).body()
                null
            } catch (cancelled: CancellationException) {
                cancelled
            } catch (
                @Suppress("TooGenericExceptionCaught") failed: Throwable,
            ) {
                failed
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

    /** Paper runs [action] for [player]; returns, once [player]'s client holds its effect, the tick after which it ran. */
    suspend fun probe(
        player: GamePlayer,
        action: ProbeAction,
    ): Int {
        val request = requests.incrementAndGet()
        val done = waitFor(probes, request) { send(Probe(request, player.uuid, action)) }
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

            is ProbeDone -> {
                probes[message.request()]?.complete(message)
            }

            is InputDone -> {
                inputs[message.request()]?.complete(message)
            }

            is Perceived -> {
                attempts[message.player()]?.let {
                    it.deliver(
                        Attempt.Event.Perceived(it.player(message.player()), message.perception()),
                    )
                }
            }

            is BarrierSeen -> {
                attempts[message.player()]?.let {
                    it.deliver(
                        Attempt.Event.Barrier(it.player(message.player()), message.barrier()),
                    )
                }
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

    private fun fail(cause: GameUnavailable) {
        broken = cause
        leases.values.forEach { it.attempt.completeExceptionally(cause) }
        probes.values.forEach { it.completeExceptionally(cause) }
        inputs.values.forEach { it.completeExceptionally(cause) }
        attempts.values.forEach { it.fail(cause) }
        ended.completeExceptionally(cause)
    }

    private fun start(
        lease: Lease,
        leasing: Leasing,
    ): Attempt {
        val attempt = Attempt(this, lease.players().map { GamePlayer(it.name(), it.uuid()) }, leasing.requirementCode)
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
