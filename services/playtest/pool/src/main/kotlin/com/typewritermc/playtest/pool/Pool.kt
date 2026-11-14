package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.BarrierSeen
import com.typewritermc.playtest.wire.Message.Claim
import com.typewritermc.playtest.wire.Message.Claimed
import com.typewritermc.playtest.wire.Message.ClientLost
import com.typewritermc.playtest.wire.Message.ClientStalled
import com.typewritermc.playtest.wire.Message.Connect
import com.typewritermc.playtest.wire.Message.Declined
import com.typewritermc.playtest.wire.Message.End
import com.typewritermc.playtest.wire.Message.Ended
import com.typewritermc.playtest.wire.Message.Hello
import com.typewritermc.playtest.wire.Message.HungEnded
import com.typewritermc.playtest.wire.Message.Input
import com.typewritermc.playtest.wire.Message.InputDone
import com.typewritermc.playtest.wire.Message.Joined
import com.typewritermc.playtest.wire.Message.Lease
import com.typewritermc.playtest.wire.Message.Marks
import com.typewritermc.playtest.wire.Message.Perceived
import com.typewritermc.playtest.wire.Message.Player
import com.typewritermc.playtest.wire.Message.PlayerLeft
import com.typewritermc.playtest.wire.Message.Probe
import com.typewritermc.playtest.wire.Message.ProbeDone
import com.typewritermc.playtest.wire.Message.Query
import com.typewritermc.playtest.wire.Message.Queue
import com.typewritermc.playtest.wire.Message.Ready
import com.typewritermc.playtest.wire.Message.Reclaim
import com.typewritermc.playtest.wire.Message.Refused
import com.typewritermc.playtest.wire.Message.Region
import com.typewritermc.playtest.wire.Message.Release
import com.typewritermc.playtest.wire.Message.Reset
import com.typewritermc.playtest.wire.Message.ResetDone
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Role
import com.typewritermc.playtest.wire.Message.Settle
import com.typewritermc.playtest.wire.Message.Settled
import com.typewritermc.playtest.wire.Message.StepUntil
import com.typewritermc.playtest.wire.Message.Stepping
import com.typewritermc.playtest.wire.Message.StopStepping
import com.typewritermc.playtest.wire.Message.Submit
import com.typewritermc.playtest.wire.Message.Watch
import com.typewritermc.playtest.wire.Message.WorkHung
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

    /**
     * One warm client and its player. A lost client's player waits for a new client of the same name,
     * which is [ready] once it steps with Paper.
     */
    private class Client(
        val player: Player,
    ) {
        var part: Part? = null
        var peer: Peer? = null
        var joined = false
        var ready = false
        var lost = false
    }

    /**
     * One attempt from its claim to its result. Paper claims its players first, then each client resets,
     * then the session gets the lease and the records the clients sent since their reset. Attempts run
     * side by side, its [group], get their leases at the same moment, once every one of them reset.
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
        var group: List<Attempt> = listOf(this)
    }

    /**
     * Work that hung on a player and still runs, keeping the player out of every claim, and the case of
     * [run] whose attempt it hung in.
     */
    private class HungWork(
        val run: String,
        val testId: String,
    ) {
        val works = mutableListOf<String>()
    }

    /** A submitted attempt waiting for its players, with the attempts submitted [together] with it. */
    private class Queued(
        val submit: Submit,
        val together: Long,
    )

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
    private val queued = mutableMapOf<Pair<Peer, Long>, Queued>()

    // Attempts whose next body waits until nothing holds their players out.
    private val parked = mutableListOf<Attempt>()
    private val hung = mutableMapOf<String, HungWork>()
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
    private var nextTogether = 0L
    private var nextRequest = 0L
    private var nextInput = 0L
    private var nextBarrier = 0

    // Every client was ready once: the game booted, and from then on the pool lends players.
    private var booted = false

    fun run() {
        thread(name = "playtest-pool-accept", isDaemon = true) { accept() }
        game = Game.start(settings, server.localPort, clients.map { it.player.name() })
        game.parts.forEach { part ->
            watch(part)
            clients.firstOrNull { it.player.name() == part.player }?.part = part
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
                exited(event.part)
            }

            Event.BootTimedOut -> {
                if (!booted) {
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
            is Queue -> {
                queue(session, message.together())
            }

            is End -> {
                runs.write(message.run(), Path.of(message.testRunFile()), stillOut(message.run()))
                session.send(Ended())
            }

            is Reclaim -> {
                reclaim(session, message)
            }

            is Settle -> {
                attemptOf(session, message.id())?.let { paper?.send(Settle(it.id)) }
            }

            is Result -> {
                val attempt = attemptOf(session, message.submission()) ?: return
                runs.record(session.hello.name(), attempt.submit, message)
                release(attempt)
            }

            else -> {
                toGame(session, message)
            }
        }
    }

    /** Queues the claim of the attempts in [together], side by side, or declines each at once when the pool could never serve them. */
    private fun queue(
        session: Peer,
        together: List<Submit>,
    ) {
        try {
            claims.submit(session, *together.map { it.submission() to it.players() }.toTypedArray())
        } catch (unservable: IllegalArgumentException) {
            for (submit in together) {
                val reason = "${submit.requirement()} cannot run here: ${unservable.message}"
                runs.record(session.hello.name(), submit, Result(submit.submission(), 0, reason, null))
                session.send(Declined(submit.submission(), reason))
            }
            return
        }
        val key = ++nextTogether
        together.forEach { queued[session to it.submission()] = Queued(it, key) }
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
            is ProbeDone -> answer(message.request()) { ProbeDone(it, message.tick(), message.failure()) }
            is Marks -> answer(message.request()) { Marks(it, message.marked(), message.failure()) }
            is Claimed -> attempts[message.attempt()]?.let { claimed(it, message.failure()) }
            is Settled -> attempts[message.id()]?.let { it.session.send(Settled(it.submit.submission())) }
            is WorkHung -> workHung(message)
            is HungEnded -> hungEnded(message)
            is PlayerLeft -> clientLost(message.player(), "its player left Paper (${message.reason().lowercase()})")
            is ClientStalled -> clientLost(message.player(), "it acked no tick for 5 s after tick ${message.lastAcked()}")
            else -> System.err.println("Paper sent ${message.javaClass.simpleName}, which Paper never sends")
        }
    }

    /** Paper answered [request]: the session that sent it gets [answer] under its own request id. */
    private fun answer(
        request: Long,
        answer: (Long) -> Message,
    ) {
        requests.remove(request)?.let { it.session.send(answer(it.id)) }
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
                ready(client)
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

    /** One client of [attempt] reset. */
    private fun reset(
        attempt: Attempt,
        player: String,
    ) {
        attempt.reset += player
        lease(attempt.group)
    }

    /** Once every client of every attempt in [group] reset, each session gets its lease and each client's fresh record. */
    private fun lease(group: List<Attempt>) {
        if (group.any { it.started || it.reset.size < it.players.size }) return
        for (attempt in group) {
            attempt.started = true
            attempt.session.send(Lease(attempt.submit.submission(), attempt.players, attempt.region))
            attempt.fresh.values.forEach(attempt.session::send)
        }
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
                queued.keys.removeAll { it.first == peer }
                parked.filter { it.session == peer }.forEach { claims.release(it.players) }
                parked.removeAll { it.session == peer }
                attempts.values.filter { it.session == peer }.forEach(::release)
                lend()
            }

            Role.CLIENT -> {
                clients.firstOrNull { it.peer == peer }?.let { lost(it, "its connection to the pool closed") }
            }

            Role.PAPER -> {
                fail("$peer closed its pool connection; see ${game.parts.joinToString { it.log.toString() }}")
            }
        }
    }

    /** Starts every attempt whose players are free: Paper claims them in a region no attempt used before. */
    private fun lend() {
        if (failure != null || !booted) return
        val claimed =
            claims.grants().mapNotNull { grant ->
                queued.remove(grant.session to grant.submission)?.let { it.together to claim(grant.session, it.submit, grant.players) }
            }
        claimed.groupBy({ it.first }, { it.second }).values.forEach { group -> group.forEach { it.group = group } }
    }

    /** Paper claims [players] for a new attempt of [submit]: it wipes them and puts them in a region no attempt used before. */
    private fun claim(
        session: Peer,
        submit: Submit,
        players: List<Player>,
    ): Attempt {
        val attempt = Attempt(++nextAttempt, session, submit, players, regions.next())
        attempts[attempt.id] = attempt
        attempt.players.forEach { attemptOf[it.name()] = attempt }
        System.err.println(
            "Attempt ${attempt.id}: ${submit.testId()} on ${attempt.players.joinToString { it.name() }} in ${attempt.region}",
        )
        paper?.send(Claim(attempt.id, attempt.players.map { it.uuid() }, attempt.region))
        return attempt
    }

    /**
     * The submission's attempt goes on with the same players: Paper releases and claims them again, as
     * the next attempt would get them, and the session gets a new lease. Until nothing holds them out,
     * for example hung work of the body before, the attempt waits with its players.
     */
    private fun reclaim(
        session: Peer,
        reclaim: Reclaim,
    ) {
        val attempt = attemptOf(session, reclaim.submission()) ?: return
        end(attempt)
        parked += attempt
        unpark()
    }

    /** Claims again every parked attempt whose players nothing holds out. */
    private fun unpark() {
        val free = parked.filter { attempt -> attempt.players.none(claims::isOut) }
        parked -= free.toSet()
        free.forEach { claim(it.session, it.submit, it.players) }
    }

    /**
     * [message]'s work hung: the attempt holding its player fails, and the player sits out of every claim
     * until the work ends, so none of it reaches a later attempt. Paper never cancels it.
     */
    private fun workHung(message: WorkHung) {
        val attempt = attemptOf[message.player()]
        attempt?.session?.send(message)
        val player = clientNamed(message.player())?.player ?: return
        val held =
            hung.getOrPut(
                message.player(),
            ) {
                HungWork(
                    attempt
                        ?.session
                        ?.hello
                        ?.name()
                        .orEmpty(),
                    attempt?.submit?.testId().orEmpty(),
                )
            }
        held.works += message.work()
        claims.holdOut(player, Out.HUNG_WORK)
    }

    /** Work that hung ended; once none still runs, its player comes back, wiped by its next claim. */
    private fun hungEnded(message: HungEnded) {
        val held = hung[message.player()] ?: return
        held.works -= message.work()
        if (held.works.isNotEmpty()) return
        hung -= message.player()
        clientNamed(message.player())?.let { claims.letBack(it.player, Out.HUNG_WORK) }
        unpark()
        lend()
    }

    /** For each case of [run] whose hung work never ended, the player it keeps out of the pool. */
    private fun stillOut(run: String): Map<String, String> =
        hung
            .filterValues { it.run == run }
            .entries
            .associate { (player, held) ->
                held.testId to
                    "$player stayed out of the pool for the rest of the run: its work ${held.works.joinToString { "\"$it\"" }} never ended."
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

    /** A game part ended: a client's is lost and replaced, Paper's ends the game. A replaced client's old part ends unheard. */
    private fun exited(part: Part) {
        val reason = "${part.name} exited with code ${part.process.exitValue()}; see ${part.log}"
        if (part.player == null) return fail(reason)
        clientNamed(part.player)?.takeIf { it.part === part }?.let { lost(it, "its process exited with code ${part.process.exitValue()}") }
    }

    /**
     * [client] crashed, froze until Paper timed its player out, or left: its attempt fails with [cause]
     * and the lost client's log, Paper already holds back no tick for it, and the pool starts a new
     * client for the player. Until that one is ready, no claim gets the player. An attempt still being
     * claimed goes back in line.
     */
    private fun lost(
        client: Client,
        cause: String,
    ) {
        if (client.lost || failure != null) return
        val name = client.player.name()
        client.lost = true
        client.ready = false
        client.peer?.close()
        client.peer = null
        claims.holdOut(client.player, Out.LOST_CLIENT)
        val replaced = game.replaceClient(name)
        client.part = replaced.replacement.also(::watch)
        val reason = "$cause; see ${replaced.lostLog}"
        System.err.println("The client of $name is lost: $reason. A new one starts.")
        attemptOf[name]?.let { attempt ->
            if (attempt.started) {
                attempt.session.send(ClientLost(name, reason))
            } else {
                // Back in line on its own; the attempts beside it get their leases without it.
                end(attempt)
                claims.release(attempt.players)
                claims.submit(attempt.session, attempt.submit.submission() to attempt.submit.players())
                queued[attempt.session to attempt.submit.submission()] = Queued(attempt.submit, ++nextTogether)
                val rest = attempt.group - attempt
                rest.forEach { it.group = rest }
                lease(rest)
            }
        }
        lend()
    }

    private fun clientLost(
        player: String,
        cause: String,
    ) {
        clientNamed(player)?.let { lost(it, cause) }
    }

    /** [client] steps with Paper: a new client in place of a lost one frees its player again. */
    private fun ready(client: Client) {
        client.ready = true
        if (client.lost) {
            client.lost = false
            claims.letBack(client.player, Out.LOST_CLIENT)
            unpark()
        }
        if (clients.all { it.ready }) booted = true
        lend()
    }

    /** Reports into the loop once [part]'s process ends. */
    private fun watch(part: Part) {
        thread(name = "playtest-pool-${part.name}", isDaemon = true) { part.process.waitFor().also { events.put(Event.Exited(part)) } }
    }

    private fun clientNamed(name: String): Client? = clients.firstOrNull { it.player.name() == name }

    /** The attempt [session] runs for [submission], if it still runs. */
    private fun attemptOf(
        session: Peer,
        submission: Long,
    ): Attempt? = attempts.values.firstOrNull { it.session == session && it.submit.submission() == submission }

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
