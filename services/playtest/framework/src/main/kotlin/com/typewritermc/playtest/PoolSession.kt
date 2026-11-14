package com.typewritermc.playtest

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.AttemptStep
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
import com.typewritermc.playtest.wire.Message.Look
import com.typewritermc.playtest.wire.Message.Looked
import com.typewritermc.playtest.wire.Message.Marks
import com.typewritermc.playtest.wire.Message.Perceived
import com.typewritermc.playtest.wire.Message.Probe
import com.typewritermc.playtest.wire.Message.ProbeAction
import com.typewritermc.playtest.wire.Message.ProbeDone
import com.typewritermc.playtest.wire.Message.Query
import com.typewritermc.playtest.wire.Message.Queue
import com.typewritermc.playtest.wire.Message.Reclaim
import com.typewritermc.playtest.wire.Message.Refused
import com.typewritermc.playtest.wire.Message.Reply
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Role
import com.typewritermc.playtest.wire.Message.Settle
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
    private val ended = CompletableDeferred<Unit>()

    @Volatile
    private var broken: GameUnavailable? = null

    /**
     * A submission waiting for its lease. The reader thread starts its [Attempt] as the lease arrives,
     * so the records that follow the lease find it.
     */
    private class Leasing(
        val requirementCode: RequirementCode,
    ) {
        val attempt = CompletableDeferred<Attempt>()
    }

    fun send(message: Message) {
        broken?.let { throw it }
        synchronized(output) { Wire.write(output, message) }
    }

    fun nextBarrier(): Int = barriers.incrementAndGet()

    /** One attempt of a requirement to run: [bodies] in order on [players] players. */
    class Planned(
        val testId: String,
        val requirement: String,
        val players: Int,
        val demonstrates: Demonstrates,
        val bodies: List<suspend RequirementScope.() -> Unit>,
    )

    /**
     * Runs one attempt of a requirement: waits for its lease and runs its bodies in order, then reports
     * the outcome. Before each body after the first, the pool releases and claims the same players
     * again, as the next attempt would get them: wiped and in a new region. Returns why it failed, or
     * null.
     */
    suspend fun attempt(planned: Planned): Throwable? = sideBySide(listOf(planned)).single()

    /**
     * Runs [planned] side by side, each as an attempt of its own: the pool claims and leases all their
     * players at the same moment. Every attempt runs to its own end; returns why each failed, or null.
     */
    suspend fun sideBySide(planned: List<Planned>): List<Throwable?> {
        val leasings =
            planned.map { submissions.incrementAndGet() to Leasing(RequirementCode.of(it.bodies.first())) }
        for ((submission, leasing) in leasings) {
            leases[submission] = leasing
            broken?.let(leasing.attempt::completeExceptionally)
        }
        try {
            send(
                Queue(
                    planned.zip(
                        leasings,
                    ) { it, (submission, _) -> Submit(submission, it.testId, it.requirement, it.players, it.demonstrates) },
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

    /** Runs [planned]'s bodies once [leasing] holds its lease; returns why the attempt failed, or null. */
    private suspend fun runAttempt(
        submission: Long,
        leasing: Leasing,
        planned: Planned,
    ): Throwable? {
        var attempt =
            try {
                leasing.attempt.await()
            } catch (
                @Suppress("TooGenericExceptionCaught") unleased: Throwable,
            ) {
                return unleased
            } finally {
                leases.remove(submission)
            }
        val started = System.nanoTime()
        var failure: Throwable? = null
        val steps = mutableListOf<AttemptStep>()
        for ((index, body) in planned.bodies.withIndex()) {
            if (index > 0) {
                attempt.players.forEach { attempts.remove(it.name) }
                attempt = lease(submission, leasing.requirementCode) { send(Reclaim(submission)) }
            }
            failure = settle(submission, attempt, run(attempt, body))?.let(attempt::located)
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
            ),
        )
        return failure
    }

    /** Waits for the lease of [submission] that [ask] asks the pool for. */
    private suspend fun lease(
        submission: Long,
        code: RequirementCode,
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
        val at = System.currentTimeMillis()
        withContext(NonCancellable) { waitFor(settles, submission) { send(Settle(submission)) } }
        attempt.took(at, "settle ${attempt.players.joinToString { it.name }}")
        val untaken = attempt.untakenFailures().firstOrNull() ?: return failure
        failure?.let(untaken::addSuppressed)
        return untaken
    }

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
     * [player]'s client counts the pixels each of [entities] owns in every record from now on, until
     * the next look; returns once a record measured that way went out, so every later one does too.
     */
    suspend fun look(
        player: GamePlayer,
        entities: List<EntityRef>,
    ) {
        request<Looked> { request -> Look(request, player.uuid, entities.map { it.uuid }) }
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
    }
}
