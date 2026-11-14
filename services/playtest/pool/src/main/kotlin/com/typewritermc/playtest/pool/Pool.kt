package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.BarrierSeen
import com.typewritermc.playtest.wire.Message.Claim
import com.typewritermc.playtest.wire.Message.Claimed
import com.typewritermc.playtest.wire.Message.Connect
import com.typewritermc.playtest.wire.Message.Declined
import com.typewritermc.playtest.wire.Message.End
import com.typewritermc.playtest.wire.Message.Ended
import com.typewritermc.playtest.wire.Message.Hello
import com.typewritermc.playtest.wire.Message.Input
import com.typewritermc.playtest.wire.Message.InputDone
import com.typewritermc.playtest.wire.Message.Joined
import com.typewritermc.playtest.wire.Message.Lease
import com.typewritermc.playtest.wire.Message.Marks
import com.typewritermc.playtest.wire.Message.Perceived
import com.typewritermc.playtest.wire.Message.Player
import com.typewritermc.playtest.wire.Message.Probe
import com.typewritermc.playtest.wire.Message.ProbeDone
import com.typewritermc.playtest.wire.Message.Query
import com.typewritermc.playtest.wire.Message.Ready
import com.typewritermc.playtest.wire.Message.Reclaim
import com.typewritermc.playtest.wire.Message.Refused
import com.typewritermc.playtest.wire.Message.Region
import com.typewritermc.playtest.wire.Message.Release
import com.typewritermc.playtest.wire.Message.Reset
import com.typewritermc.playtest.wire.Message.ResetDone
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Role
import com.typewritermc.playtest.wire.Message.StepUntil
import com.typewritermc.playtest.wire.Message.Stepping
import com.typewritermc.playtest.wire.Message.StopStepping
import com.typewritermc.playtest.wire.Message.Submit
import com.typewritermc.playtest.wire.Message.Watch
import com.typewritermc.playtest.wire.Wire
import java.io.BufferedInputStream
import java.io.DataInputStream
import java.io.IOException
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException
import java.nio.channels.FileChannel
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.StandardOpenOption
import java.util.UUID
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread
import kotlin.system.exitProcess

/**
 * Starts the pool for the pool folder. The lock file makes it the only pool there; another pool that
 * holds it already serves this run, so this one exits at once. Test JVMs find the pool by its port file.
 */
fun main() {
    val settings = PoolSettings.fromSystemProperties()
    Files.createDirectories(settings.poolDir)
    val lockFile = FileChannel.open(settings.poolDir.resolve("pool.lock"), StandardOpenOption.CREATE, StandardOpenOption.WRITE)
    val lock = lockFile.tryLock() ?: exitProcess(0)
    // Every starter appends its output to the log; the pool that holds the lock empties it, so the log holds this run alone.
    FileChannel.open(settings.poolDir.resolve("pool.log"), StandardOpenOption.CREATE, StandardOpenOption.WRITE).use { it.truncate(0) }
    val portFile = settings.poolDir.resolve("pool.port")
    ServerSocket(0, BACKLOG, InetAddress.getLoopbackAddress()).use { server ->
        val pool = Pool(settings, server)
        val partial = settings.poolDir.resolve("pool.port.partial")
        Files.writeString(partial, server.localPort.toString())
        Files.move(partial, portFile, StandardCopyOption.REPLACE_EXISTING, StandardCopyOption.ATOMIC_MOVE)
        try {
            pool.run()
        } finally {
            Files.deleteIfExists(portFile)
            lock.release()
        }
    }
    exitProcess(0)
}

private const val BACKLOG = 16

/**
 * The pool's single loop: every connection and process reports into one queue, and only this loop
 * touches the pool's state. It boots the game, hands each submitted attempt the players it claims once
 * they are free, wiped and in a region of its own, routes each attempt's messages, and stops once the
 * last session left.
 */
internal class Pool(
    private val settings: PoolSettings,
    private val server: ServerSocket,
) {
    private sealed interface Event {
        data class Joined(
            val peer: Peer,
        ) : Event

        data class Received(
            val peer: Peer,
            val message: Message,
        ) : Event

        data class Left(
            val peer: Peer,
        ) : Event

        data class Exited(
            val part: Part,
        ) : Event

        data object BootTimedOut : Event
    }

    /** One warm client and its player. */
    private class Client(
        val player: Player,
    ) {
        var peer: Peer? = null
        var joined = false
        var ready = false
    }

    /**
     * One attempt from its claim to its result. Paper claims its players first, then each client resets,
     * then the session gets the lease and the records the clients sent since their reset.
     */
    private class Attempt(
        val id: Long,
        val session: Peer,
        val submit: Submit,
        val players: List<Player>,
        val region: Region,
    ) {
        val reset = mutableSetOf<String>()
        val fresh = mutableMapOf<String, Perceived>()
        var started = false
    }

    private class Routed<T>(
        val session: Peer,
        val id: T,
    )

    private val events = LinkedBlockingQueue<Event>()
    private val clients =
        (1..settings.clients).map { Client(Player("gv-$it", UUID.nameUUIDFromBytes("OfflinePlayer:gv-$it".toByteArray()))) }
    private val claims = Claims<Peer, Player>(clients.map { it.player })
    private val regions = Regions()
    private val runs = RunRecords()
    private val sessions = mutableSetOf<Peer>()
    private val waiting = mutableMapOf<Pair<Peer, Long>, Submit>()
    private val attempts = mutableMapOf<Long, Attempt>()
    private val attemptOf = mutableMapOf<String, Attempt>()
    private val requests = mutableMapOf<Long, Routed<Long>>()
    private val inputs = mutableMapOf<Long, Routed<Long>>()
    private val barriers = mutableMapOf<Int, Routed<Int>>()
    private lateinit var game: Game
    private var paper: Peer? = null
    private var stepping = false
    private var failure: String? = null
    private var sawSession = false
    private var nextAttempt = 0L
    private var nextRequest = 0L
    private var nextInput = 0L
    private var nextBarrier = 0

    private val ready: Boolean get() = clients.all { it.ready }

    fun run() {
        thread(name = "playtest-pool-accept", isDaemon = true) { accept() }
        game = Game.start(settings, server.localPort, clients.map { it.player.name() })
        game.parts.forEach { part ->
            thread(name = "playtest-pool-${part.name}", isDaemon = true) { part.process.waitFor().also { events.put(Event.Exited(part)) } }
        }
        thread(name = "playtest-pool-boot", isDaemon = true) {
            Thread.sleep(TimeUnit.SECONDS.toMillis(BOOT_SECONDS))
            events.put(Event.BootTimedOut)
        }
        try {
            while (!sawSession || sessions.isNotEmpty()) handle(events.take())
        } finally {
            game.stop()
        }
    }

    private fun handle(event: Event) {
        when (event) {
            is Event.Joined -> {
                joined(event.peer)
            }

            is Event.Received -> {
                received(event.peer, event.message)
            }

            is Event.Left -> {
                left(event.peer)
            }

            is Event.Exited -> {
                fail("${event.part.name} exited with code ${event.part.process.exitValue()}; see ${event.part.log}")
            }

            Event.BootTimedOut -> {
                if (!ready) {
                    fail(
                        "the game was not ready within $BOOT_SECONDS s; see ${game.parts.joinToString { it.log.toString() }}",
                    )
                }
            }
        }
    }

    private fun joined(peer: Peer) {
        when (peer.role) {
            Role.SESSION -> {
                sessions += peer
                sawSession = true
                runs.started(peer.hello.name())
                failure?.let { peer.send(Refused(it)) }
            }

            Role.PAPER -> {
                paper = peer
                clients.forEach { connect(it) }
            }

            Role.CLIENT -> {
                val client = clients.firstOrNull { it.player.name() == peer.hello.name() } ?: return peer.close()
                client.peer = peer
                connect(client)
            }
        }
    }

    /** Sends [client] to Paper once both are connected to the pool. */
    private fun connect(client: Client) {
        if (paper == null) return
        client.peer?.send(Connect("127.0.0.1", game.paperPort))
    }

    private fun received(
        peer: Peer,
        message: Message,
    ) {
        when (peer.role) {
            Role.SESSION -> fromSession(peer, message)
            Role.PAPER -> fromPaper(message)
            Role.CLIENT -> clients.firstOrNull { it.peer == peer }?.let { fromClient(it, message) }
        }
    }

    private fun fromSession(
        session: Peer,
        message: Message,
    ) {
        when (message) {
            is Submit -> {
                submit(session, message)
            }

            is End -> {
                runs.write(message.run(), Path.of(message.testRunFile()))
                session.send(Ended())
            }

            is Reclaim -> {
                reclaim(session, message)
            }

            is Result -> {
                val attempt =
                    attempts.values.firstOrNull { it.session == session && it.submit.submission() == message.submission() } ?: return
                runs.record(session.hello.name(), attempt.submit, message)
                release(attempt)
            }

            else -> {
                toGame(session, message)
            }
        }
    }

    /** Queues [submit]'s claim, or declines it at once when the pool could never serve it. */
    private fun submit(
        session: Peer,
        submit: Submit,
    ) {
        try {
            claims.submit(session, submit.submission(), submit.players())
        } catch (unservable: IllegalArgumentException) {
            val reason = "${submit.requirement()} cannot run here: ${unservable.message}"
            runs.record(session.hello.name(), submit, Result(submit.submission(), 0, reason, null))
            session.send(Declined(submit.submission(), reason))
            return
        }
        waiting[session to submit.submission()] = submit
        lend()
    }

    /**
     * What a session sends the game for its attempts' players: probes and steps for Paper, inputs and
     * watches for their clients. A message naming a player no attempt of the session holds reaches neither.
     */
    private fun toGame(
        session: Peer,
        message: Message,
    ) {
        val named = playersNamedBy(message)
        if (named == null) return System.err.println("$session sent ${message.javaClass.simpleName}, which a session never sends")
        if (named.isEmpty() || !named.all { holds(session, it) }) return
        when (message) {
            is Probe -> {
                toPaper(session, message.request()) { Probe(it, message.players(), message.action()) }
            }

            is Query -> {
                toPaper(session, message.request()) { Query(it, message.player()) }
            }

            is StepUntil -> {
                val routed = StepUntil(message.player(), message.tick(), ++nextBarrier)
                barriers[routed.barrier()] = Routed(session, message.barrier())
                paper?.send(routed)
            }

            is Input -> {
                val routed = Input(++nextInput, message.player(), message.steps())
                inputs[routed.request()] = Routed(session, message.request())
                clientOf(message.player())?.peer?.send(routed)
            }

            is StopStepping -> {
                paper?.send(message)
            }

            is Watch -> {
                clientOf(message.player())?.peer?.send(message)
            }

            // playersNamedBy turned every other message away above.
            else -> {}
        }
    }

    /** Sends Paper the message [routed] builds with a pool wide request id, remembering which session asked as [request]. */
    private fun toPaper(
        session: Peer,
        request: Long,
        routed: (Long) -> Message,
    ) {
        val id = ++nextRequest
        requests[id] = Routed(session, request)
        paper?.send(routed(id))
    }

    /** The players a message for the game acts on, or null for a message a session never sends. */
    private fun playersNamedBy(message: Message): List<UUID>? =
        when (message) {
            is Probe -> message.players()
            is Query -> listOf(message.player())
            is StepUntil -> listOf(message.player())
            is StopStepping -> listOf(message.player())
            is Input -> listOf(message.player())
            is Watch -> listOf(message.player())
            else -> null
        }

    private fun holds(
        session: Peer,
        player: UUID,
    ) = attemptOf.values.any { attempt -> attempt.session == session && attempt.players.any { it.uuid() == player } }

    private fun fromPaper(message: Message) {
        when (message) {
            is ProbeDone -> requests.remove(message.request())?.let { it.session.send(ProbeDone(it.id, message.tick(), message.failure())) }
            is Marks -> requests.remove(message.request())?.let { it.session.send(Marks(it.id, message.marked(), message.failure())) }
            is Claimed -> attempts[message.attempt()]?.let { claimed(it, message.failure()) }
            else -> System.err.println("Paper sent ${message.javaClass.simpleName}, which Paper never sends")
        }
    }

    private fun fromClient(
        client: Client,
        message: Message,
    ) {
        val name = client.player.name()
        when (message) {
            is Joined -> {
                joined(client)
            }

            is Ready -> {
                client.ready = true
                lend()
            }

            is ResetDone -> {
                attemptOf[name]?.let { reset(it, name) }
            }

            is Perceived -> {
                attemptOf[name]?.let { perceived(it, name, message) }
            }

            is BarrierSeen -> {
                barrierSeen(message)
            }

            is InputDone -> {
                inputs.remove(message.request())?.let { it.session.send(InputDone(it.id, message.tick(), message.failure())) }
            }

            else -> {
                System.err.println("${client.player.name()} sent ${message.javaClass.simpleName}, which a client never sends")
            }
        }
    }

    /** Every client joins before Paper steps: a stepped client draws no frame, so it would never leave the loading screen. */
    private fun joined(client: Client) {
        client.joined = true
        if (stepping || !clients.all { it.joined }) return
        stepping = true
        paper?.send(Stepping())
    }

    /** A record reaches the attempt's session once it holds the lease; until then only each player's latest waits. */
    private fun perceived(
        attempt: Attempt,
        player: String,
        message: Perceived,
    ) {
        if (attempt.started) attempt.session.send(message) else attempt.fresh[player] = message
    }

    /** Paper claimed the attempt's players: each client resets, then the session gets the lease. */
    private fun claimed(
        attempt: Attempt,
        failure: String?,
    ) {
        if (failure != null) return fail("Paper could not claim ${attempt.players.joinToString { it.name() }}: $failure")
        attempt.players.forEach { clientOf(it.uuid())?.peer?.send(Reset()) }
    }

    /** One client of [attempt] reset; once every one did, the session gets the lease and each client's fresh record. */
    private fun reset(
        attempt: Attempt,
        player: String,
    ) {
        attempt.reset += player
        if (attempt.started || attempt.reset.size < attempt.players.size) return
        attempt.started = true
        attempt.session.send(Lease(attempt.submit.submission(), attempt.players, attempt.region))
        attempt.fresh.values.forEach(attempt.session::send)
    }

    /** Hands a barrier back under the session's own id, unless it belongs to an attempt that already ended. */
    private fun barrierSeen(message: BarrierSeen) {
        val routed = barriers.remove(message.barrier()) ?: return
        val attempt = attemptOf[message.player()] ?: return
        if (routed.session == attempt.session) routed.session.send(BarrierSeen(message.player(), routed.id))
    }

    private fun left(peer: Peer) {
        when (peer.role) {
            Role.SESSION -> {
                sessions -= peer
                claims.leave(peer)
                waiting.keys.removeAll { it.first == peer }
                attempts.values.filter { it.session == peer }.forEach(::release)
            }

            Role.PAPER, Role.CLIENT -> {
                fail("$peer closed its pool connection; see ${game.parts.joinToString { it.log.toString() }}")
            }
        }
    }

    /** Starts every attempt whose players are free: Paper claims them in a region no attempt used before. */
    private fun lend() {
        if (failure != null || !ready) return
        for (grant in claims.grants()) {
            val submit = waiting.remove(grant.session to grant.submission) ?: continue
            claim(grant.session, submit, grant.players)
        }
    }

    /** Paper claims [players] for a new attempt of [submit]: it wipes them and puts them in a region no attempt used before. */
    private fun claim(
        session: Peer,
        submit: Submit,
        players: List<Player>,
    ) {
        val attempt = Attempt(++nextAttempt, session, submit, players, regions.next())
        attempts[attempt.id] = attempt
        attempt.players.forEach { attemptOf[it.name()] = attempt }
        System.err.println(
            "Attempt ${attempt.id}: ${submit.testId()} on ${attempt.players.joinToString { it.name() }} in ${attempt.region}",
        )
        paper?.send(Claim(attempt.id, attempt.players.map { it.uuid() }, attempt.region))
    }

    /**
     * The submission's attempt goes on with the same players: Paper releases and claims them again, as
     * the next attempt would get them, and the session gets a new lease.
     */
    private fun reclaim(
        session: Peer,
        reclaim: Reclaim,
    ) {
        val attempt = attempts.values.firstOrNull { it.session == session && it.submit.submission() == reclaim.submission() } ?: return
        end(attempt)
        claim(session, attempt.submit, attempt.players)
    }

    private fun release(attempt: Attempt) {
        end(attempt)
        claims.release(attempt.players)
        lend()
    }

    /** The attempt is over for Paper: its players no longer hold back ticks, and their records reach nobody. */
    private fun end(attempt: Attempt) {
        attempts.remove(attempt.id)
        attempt.players.forEach { attemptOf.remove(it.name()) }
        paper?.send(Release(attempt.id))
    }

    private fun clientOf(player: UUID): Client? = clients.firstOrNull { it.player.uuid() == player }

    /** The game cannot run: every session hears why, and the game stops. */
    private fun fail(reason: String) {
        if (failure != null) return
        failure = reason
        System.err.println("The game failed: $reason")
        sessions.forEach { it.send(Refused(reason)) }
        game.stop()
    }

    /** Accepts connections until the pool closes its socket on the way out. */
    private fun accept() {
        while (!server.isClosed) {
            val socket =
                try {
                    server.accept()
                } catch (closed: SocketException) {
                    if (server.isClosed) return
                    throw closed
                }
            thread(name = "playtest-pool-peer", isDaemon = true) { serve(socket) }
        }
    }

    private fun serve(socket: Socket) {
        socket.tcpNoDelay = true
        val input = DataInputStream(BufferedInputStream(socket.getInputStream()))
        val hello = Wire.read(input) as? Hello ?: return socket.close()
        val peer = Peer(socket, hello)
        events.put(Event.Joined(peer))
        try {
            while (true) events.put(Event.Received(peer, Wire.read(input)))
        } catch (closed: IOException) {
            System.err.println("$peer left: ${closed.message}")
            events.put(Event.Left(peer))
        }
    }

    private companion object {
        const val BOOT_SECONDS = 300L
    }
}
