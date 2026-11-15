package com.typewritermc.playtest.pool

import com.typewritermc.playtest.pool.OwnPaper.Do
import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.AttemptStep
import com.typewritermc.playtest.wire.Message.BarrierSeen
import com.typewritermc.playtest.wire.Message.Claim
import com.typewritermc.playtest.wire.Message.Claimed
import com.typewritermc.playtest.wire.Message.ClientLost
import com.typewritermc.playtest.wire.Message.ClientRequest
import com.typewritermc.playtest.wire.Message.ClientStalled
import com.typewritermc.playtest.wire.Message.Connect
import com.typewritermc.playtest.wire.Message.Declined
import com.typewritermc.playtest.wire.Message.Disconnected
import com.typewritermc.playtest.wire.Message.End
import com.typewritermc.playtest.wire.Message.Ended
import com.typewritermc.playtest.wire.Message.Hello
import com.typewritermc.playtest.wire.Message.HungEnded
import com.typewritermc.playtest.wire.Message.Joined
import com.typewritermc.playtest.wire.Message.Lease
import com.typewritermc.playtest.wire.Message.LeaseFailed
import com.typewritermc.playtest.wire.Message.PaperLost
import com.typewritermc.playtest.wire.Message.PaperRequest
import com.typewritermc.playtest.wire.Message.Perceived
import com.typewritermc.playtest.wire.Message.Player
import com.typewritermc.playtest.wire.Message.PlayerLeft
import com.typewritermc.playtest.wire.Message.Probe
import com.typewritermc.playtest.wire.Message.Query
import com.typewritermc.playtest.wire.Message.Queue
import com.typewritermc.playtest.wire.Message.Ready
import com.typewritermc.playtest.wire.Message.Reclaim
import com.typewritermc.playtest.wire.Message.Refused
import com.typewritermc.playtest.wire.Message.Region
import com.typewritermc.playtest.wire.Message.RegionsAhead
import com.typewritermc.playtest.wire.Message.Release
import com.typewritermc.playtest.wire.Message.Reply
import com.typewritermc.playtest.wire.Message.Request
import com.typewritermc.playtest.wire.Message.Reset
import com.typewritermc.playtest.wire.Message.ResetDone
import com.typewritermc.playtest.wire.Message.Restart
import com.typewritermc.playtest.wire.Message.Restarted
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Resume
import com.typewritermc.playtest.wire.Message.Resumed
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

        /** Boot [boot] of the own Paper [name] may have outlived its limit. */
        data class OwnBootTimedOut(
            val name: String,
            val boot: Int,
        ) : Event
    }

    /** A Paper the pool runs: the shared one, or a restart attempt's own, which [own] then describes. */
    private class Server(
        val name: String,
        val port: Int,
    ) {
        var peer: Peer? = null
        var stepping = false
        var own: Own? = null
    }

    /**
     * What makes a Paper a restart attempt's own: the [rules] of its life, its [folder], the [attempt] it
     * serves, its process now, the cache its boot trains, and when its last kill and boot happened.
     */
    private class Own(
        val rules: OwnPaper,
        val folder: OwnFolder,
        val attempt: Attempt,
    ) {
        var part: Part? = null
        var training: AotCache.Boot.Train? = null
        var lost = false
        var killedAt = 0L
        var bootedAt = 0L
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

        /** The Paper the client is on, or is told to join. */
        lateinit var on: Server
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
        val server: Server,
    ) {
        val reset = mutableSetOf<String>()
        val fresh = mutableMapOf<String, Perceived>()
        var started = false

        // While its Paper restarts, only each player's latest record waits, as before the lease.
        var restarting = false
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

    /**
     * The pool's part of one submission's attempt, for the steps of its run file: since when it waited
     * for what comes next (its players, then their wipe), and the steps it took so far.
     */
    private class Timing(
        var since: Long,
    ) {
        val steps = mutableListOf<AttemptStep>()

        /** One step ended now: it began at [since], and the next one begins now. */
        fun took(says: String) {
            val now = System.currentTimeMillis()
            steps += AttemptStep(since, now - since, says)
            since = now
        }
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
    private val regions = Regions(ahead = settings.clients)
    private val runs = RunRecords()
    private val sessions = mutableSetOf<Peer>()
    private val queued = mutableMapOf<Pair<Peer, Long>, Queued>()
    private val timings = mutableMapOf<Pair<Peer, Long>, Timing>()

    // Attempts whose next body waits until nothing holds their players out.
    private val parked = mutableListOf<Attempt>()
    private val hung = mutableMapOf<String, HungWork>()
    private val attempts = mutableMapOf<Long, Attempt>()
    private val attemptOf = mutableMapOf<String, Attempt>()
    private val requests = mutableMapOf<Long, Routed<Long>>()
    private val barriers = mutableMapOf<Int, Routed<Int>>()
    private lateinit var game: Game
    private lateinit var shared: Server
    private val owns = mutableMapOf<String, Server>()
    private val aot = AotCache(settings.aotDir)

    // Every restart Paper of the pool boots the same JDK, class path, plugins and flags.
    private val aotKey by lazy {
        val java = settings.java.toRealPath()
        val release = java.parent.parent.resolve("release")
        val jdk = "$java\n" + if (Files.isRegularFile(release)) Files.readString(release) else ""
        AotCache.key(jdk, PaperServer.of(settings.paperDir).classPath + listOf(settings.agentJar, settings.pluginJar), RESTART_FLAGS)
    }
    private var failure: String? = null
    private var sawSession = false
    private var nextAttempt = 0L
    private var nextTogether = 0L
    private var nextRequest = 0L
    private var nextBarrier = 0

    // Every client was ready once: the game booted, and from then on the pool lends players.
    private var booted = false

    fun run() {
        thread(name = "playtest-pool-accept", isDaemon = true) { accept() }
        game = Game.start(settings, server.localPort, clients.map { it.player.name() })
        shared = Server("paper", game.paperPort)
        clients.forEach { it.on = shared }
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
            // Every attempt ended, so each own Paper halts on its own; one that trained writes its cache as
            // it exits, which the pool keeps only once it hears the exit.
            val ownsEndBy = System.nanoTime() + TimeUnit.SECONDS.toNanos(OWN_EXIT_SECONDS)
            while (owns.isNotEmpty()) handle(events.poll(ownsEndBy - System.nanoTime(), TimeUnit.NANOSECONDS) ?: break)
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

            is Event.OwnBootTimedOut -> {
                owns[event.name]?.let { server -> server.own?.let { act(server, it.rules.bootTimedOut(event.boot)) } }
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
                val server = if (peer.hello.name() == shared.name) shared else owns[peer.hello.name()] ?: return peer.close()
                server.peer = peer
                server.stepping = false
                val own = server.own
                if (own == null) {
                    peer.send(RegionsAhead(regions.ahead()))
                    clients.forEach { connect(it) }
                } else {
                    peer.send(RegionsAhead(listOf(own.attempt.region)))
                    System.err.println("${server.name} is up after ${seconds(own.bootedAt)} of boot ${own.rules.boots}")
                    act(server, own.rules.connected())
                }
            }

            Role.CLIENT -> {
                val client = clients.firstOrNull { it.player.name() == peer.hello.name() } ?: return peer.close()
                client.peer = peer
                connect(client)
            }
        }
    }

    /** Sends [client] to the Paper it is on once both are connected to the pool. */
    private fun connect(client: Client) {
        val server = client.on
        if (server.peer == null) return
        client.peer?.send(Connect("127.0.0.1", server.port))
    }

    private fun received(
        peer: Peer,
        message: Message,
    ) {
        when (peer.role) {
            Role.SESSION -> fromSession(peer, message)
            Role.PAPER -> serverOf(peer)?.let { fromPaper(it, message) }
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
                runs.ended(message.run(), Path.of(message.testRunFile()), message.policy(), stillOut(message.run()))
                session.send(Ended())
            }

            is Reclaim -> {
                reclaim(session, message)
            }

            // A lost own Paper runs no work that could still reach a later attempt.
            is Settle -> {
                attemptOf(session, message.id())?.let { attempt ->
                    attempt.server.peer?.send(Settle(attempt.id)) ?: session.send(Settled(message.id()))
                }
            }

            is Restart -> {
                val attempt = attemptOf(session, message.submission())
                val own =
                    attempt?.server?.own
                        ?: return System.err.println("$session asked to restart the Paper of an attempt that has none of its own")
                act(attempt.server, own.rules.restart(message.request()))
            }

            is Result -> {
                val attempt = attemptOf(session, message.submission()) ?: return
                val claimed = timings.remove(session to message.submission())?.steps.orEmpty()
                runs.record(session.hello.name(), attempt.submit, message, claimed)
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
                runs.record(session.hello.name(), submit, Result(submit.submission(), 0, reason, null, listOf(), "", listOf()))
                session.send(Declined(submit.submission(), reason))
            }
            return
        }
        val key = ++nextTogether
        val now = System.currentTimeMillis()
        together.forEach {
            queued[session to it.submission()] = Queued(it, key)
            timings[session to it.submission()] = Timing(now)
        }
        lend()
    }

    /**
     * What a session sends the game for its attempts' players: probes, queries and steps for Paper;
     * inputs, looks, captures and watches for their clients. A message naming a player no attempt of the session holds reaches neither.
     */
    private fun toGame(
        session: Peer,
        message: Message,
    ) {
        val named = playersNamedBy(message)
        if (named == null) return System.err.println("$session sent ${message.javaClass.simpleName}, which a session never sends")
        if (named.isEmpty() || !named.all { holds(session, it) }) return
        val paper = serverOf(session, named.first())?.peer
        when (message) {
            is PaperRequest -> {
                route(paper, session, message)
            }

            is ClientRequest -> {
                route(clientOf(message.player())?.peer, session, message)
            }

            is StepUntil -> {
                val routed = StepUntil(message.player(), message.tick(), ++nextBarrier)
                barriers[routed.barrier()] = Routed(session, message.barrier())
                paper?.send(routed)
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

    /** Sends [peer] the session's [request] under a pool wide request id, remembering which session asked under which id. */
    private fun route(
        peer: Peer?,
        session: Peer,
        request: Request,
    ) {
        val id = ++nextRequest
        requests[id] = Routed(session, request.request())
        peer?.send(request.withRequest(id))
    }

    /** The players a message for the game acts on, or null for a message a session never sends. */
    private fun playersNamedBy(message: Message): List<UUID>? =
        when (message) {
            is Probe -> message.players()
            is Query -> listOf(message.player())
            is ClientRequest -> listOf(message.player())
            is StepUntil -> listOf(message.player())
            is StopStepping -> listOf(message.player())
            is Watch -> listOf(message.player())
            else -> null
        }

    private fun holds(
        session: Peer,
        player: UUID,
    ) = serverOf(session, player) != null

    /** The Paper of the attempt [session] runs on [player], if it holds that player. */
    private fun serverOf(
        session: Peer,
        player: UUID,
    ): Server? =
        attemptOf.values
            .firstOrNull { attempt ->
                attempt.session == session && attempt.players.any { it.uuid() == player }
            }?.server

    /** The Paper that opened the connection [peer]. */
    private fun serverOf(peer: Peer): Server? = if (shared.peer == peer) shared else owns.values.firstOrNull { it.peer == peer }

    private fun fromPaper(
        server: Server,
        message: Message,
    ) {
        when (message) {
            is Reply -> {
                answer(message.request(), message::withRequest)
            }

            is Claimed -> {
                attempts[message.attempt()]?.let { claimed(it, message.failure()) }
            }

            is Resumed -> {
                resumed(server, message)
            }

            is Settled -> {
                attempts[message.id()]?.let { it.session.send(Settled(it.submit.submission())) }
            }

            is WorkHung -> {
                workHung(message)
            }

            is HungEnded -> {
                hungEnded(message)
            }

            is PlayerLeft -> {
                lostOn(server, message.player(), "its player left Paper (${message.reason().lowercase()})")
            }

            is ClientStalled -> {
                lostOn(server, message.player(), "it acked no tick for 5 s after tick ${message.lastAcked()}")
            }

            else -> {
                System.err.println("${server.name} sent ${message.javaClass.simpleName}, which Paper never sends")
            }
        }
    }

    /** [server], an own Paper, resumed its attempt after a restart, or could not. */
    private fun resumed(
        server: Server,
        message: Resumed,
    ) {
        val own = server.own ?: return
        val failure = message.failure()
        act(
            server,
            if (failure ==
                null
            ) {
                own.rules.resumed(message.tick())
            } else {
                own.rules.failed("${server.name} could not resume its attempt: $failure")
            },
        )
    }

    /** [server] lost [player]'s client for [cause]; a client the pool moved to another Paper left this one on purpose. */
    private fun lostOn(
        server: Server,
        player: String,
        cause: String,
    ) {
        if (clientNamed(player)?.on == server) clientLost(player, cause)
    }

    /** Paper or a client answered [request]: the session that sent it gets [answer] under its own request id. */
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

            is Reply -> {
                answer(message.request(), message::withRequest)
            }

            is Disconnected -> {
                disconnected(client, message)
            }

            else -> {
                System.err.println("${client.player.name()} sent ${message.javaClass.simpleName}, which a client never sends")
            }
        }
    }

    /**
     * Every client joins before a Paper steps: a stepped client draws no frame, so it would never leave
     * the loading screen. A restart attempt's own Paper waits for its attempt's clients alone.
     */
    private fun joined(client: Client) {
        client.joined = true
        client.on.own?.let { return act(client.on, it.rules.joined(client.player.name())) }
        if (shared.stepping || !clients.all { it.joined }) return
        shared.stepping = true
        shared.peer?.send(Stepping())
    }

    /**
     * [client] lost a Paper it was not told to leave. A drop off a Paper the pool already sent it away
     * from, off a killed own Paper, or off an own Paper whose process died is part of what the pool
     * does or reports otherwise; any other drop loses the client.
     */
    private fun disconnected(
        client: Client,
        message: Disconnected,
    ) {
        val server = client.on
        if (message.port() != server.port) return
        client.joined = false
        client.ready = false
        val own = server.own
        if (own != null && (own.rules.dropsExpected || own.part?.process?.isAlive == false)) {
            // Records sent before the drop show the killed Paper; the next ones show the new one.
            attemptOf[client.player.name()]?.fresh?.remove(client.player.name())
            return
        }
        lost(client, "it lost its Paper: ${message.reason()}")
    }

    /** A record reaches the attempt's session once it holds the lease; until then only each player's latest waits. */
    private fun perceived(
        attempt: Attempt,
        player: String,
        message: Perceived,
    ) {
        if (attempt.started && !attempt.restarting) attempt.session.send(message) else attempt.fresh[player] = message
    }

    /** Paper claimed the attempt's players: each client resets, then the session gets the lease. */
    private fun claimed(
        attempt: Attempt,
        failure: String?,
    ) {
        val cause = failure?.let { "${attempt.server.name} could not claim ${attempt.players.joinToString { it.name() }}: $it" }
        if (cause != null) {
            val own = attempt.server.own
            return if (own != null) act(attempt.server, own.rules.failed(cause)) else fail(cause)
        }
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
            timings[attempt.session to attempt.submit.submission()]?.took(
                "wipe ${attempt.players.joinToString { it.name() }} into region (${attempt.region.x()}, ${attempt.region.z()})",
            )
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
                abandon(peer)
                claims.leave(peer)
                queued.keys.removeAll { it.first == peer }
                timings.keys.removeAll { it.first == peer }
                parked.filter { it.session == peer }.forEach { claims.release(it.players) }
                parked.removeAll { it.session == peer }
                attempts.values.filter { it.session == peer }.forEach(::release)
                lend()
            }

            Role.CLIENT -> {
                clients.firstOrNull { it.peer == peer }?.let { lost(it, "its connection to the pool closed") }
            }

            // An own Paper's end shows in its process's exit.
            Role.PAPER -> {
                val server = serverOf(peer)
                if (server == shared) fail("$peer closed its pool connection; see ${game.parts.joinToString { it.log.toString() }}")
                server?.peer = null
            }
        }
    }

    /**
     * [session] left before every attempt it submitted ended, as a killed test JVM does: each such attempt
     * fails in its run's file, so the run never reads as complete without them.
     */
    private fun abandon(session: Peer) {
        val unfinished =
            queued.filterKeys { it.first == session }.values.map { it.submit } +
                (attempts.values + parked).filter { it.session == session }.map { it.submit }
        if (unfinished.isEmpty()) return
        val run = session.hello.name()
        runs.abandoned(
            run,
            unfinished.distinctBy { it.submission() },
            "its test JVM ended before the attempt did; see ${settings.poolDir.resolve("pool.log")}",
            stillOut(run),
        )
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

    /**
     * Paper claims [players] for a new attempt of [submit]: it wipes them and puts them in a region no
     * attempt used before, and hears which regions the claims after it get.
     */
    private fun claim(
        session: Peer,
        submit: Submit,
        players: List<Player>,
    ): Attempt {
        if (submit.restartsPaper()) return claimOwn(session, submit, players)
        val attempt = Attempt(++nextAttempt, session, submit, players, regions.next(), shared)
        timings[session to submit.submission()]?.took("claim ${players.joinToString { it.name() }}")
        attempts[attempt.id] = attempt
        attempt.players.forEach { attemptOf[it.name()] = attempt }
        System.err.println(
            "Attempt ${attempt.id}: ${submit.testId()} on ${attempt.players.joinToString { it.name() }} in ${attempt.region}",
        )
        shared.peer?.send(Claim(attempt.id, attempt.players.map { it.uuid() }, attempt.region))
        shared.peer?.send(RegionsAhead(regions.ahead()))
        return attempt
    }

    /**
     * A restart attempt gets [players] like any claim, on a Paper of its own named after its first
     * player: it boots while they wait on the shared Paper, and they join it once it is up. Alone on its
     * Paper, the attempt stands in the region at the spawn.
     */
    private fun claimOwn(
        session: Peer,
        submit: Submit,
        players: List<Player>,
    ): Attempt {
        val folder = game.ownFolder(Game.OWN_PAPER + players.first().name())
        val server = Server(folder.name, folder.port)
        val attempt = Attempt(++nextAttempt, session, submit, players, Region(0, 0), server)
        timings[session to submit.submission()]?.took("claim ${players.joinToString { it.name() }} on ${server.name}")
        attempts[attempt.id] = attempt
        attempt.players.forEach { attemptOf[it.name()] = attempt }
        System.err.println("Attempt ${attempt.id}: ${submit.testId()} on ${attempt.players.joinToString { it.name() }} on ${server.name}")
        val own = Own(OwnPaper(server.name, players.map { it.name() }.toSet()), folder, attempt)
        server.own = own
        owns[server.name] = server
        act(server, own.rules.start())
        return attempt
    }

    /** Does what the rules of [server], a restart attempt's own Paper, say comes next. */
    private fun act(
        server: Server,
        todo: List<Do>,
    ) {
        val own = server.own ?: return
        todo.forEach { act(server, own, it) }
    }

    private fun act(
        server: Server,
        own: Own,
        next: Do,
    ) {
        val attempt = own.attempt
        when (next) {
            Do.Boot -> {
                bootOwn(server, own)
            }

            Do.Connect -> {
                moveTo(server, attempt)
            }

            Do.Step -> {
                server.stepping = true
                server.peer?.send(Stepping())
            }

            Do.Claim -> {
                server.peer?.send(Claim(attempt.id, attempt.players.map { it.uuid() }, attempt.region))
            }

            Do.Resume -> {
                server.peer?.send(Resume(attempt.id, attempt.players.map { it.uuid() }))
            }

            Do.Kill -> {
                kill(own)
            }

            is Do.Restarted -> {
                restarted(server, own, next)
            }

            is Do.Lost -> {
                lostOwn(server, own, next.cause)
            }

            Do.Return -> {
                sendBack(attempt)
                // Its plugin halts once the pool is gone; a training boot writes its cache as it exits.
                server.peer?.close() ?: own.part?.process?.destroyForcibly()
            }
        }
    }

    /** [attempt]'s players leave the shared Paper for [server], which serves no claim of theirs meanwhile. */
    private fun moveTo(
        server: Server,
        attempt: Attempt,
    ) {
        for (player in attempt.players) {
            val client = clientOf(player.uuid()) ?: continue
            client.on = server
            client.joined = false
            client.ready = false
            claims.holdOut(client.player, Out.AWAY)
            connect(client)
        }
    }

    /** Ends [own]'s Paper as a crash would; what its players perceive waits until it is back. */
    private fun kill(own: Own) {
        val attempt = own.attempt
        attempt.restarting = true
        attempt.fresh.clear()
        own.killedAt = System.nanoTime()
        own.part?.process?.destroyForcibly()
    }

    /** [own]'s Paper is back: the session hears so, then the latest record of each player. */
    private fun restarted(
        server: Server,
        own: Own,
        back: Do.Restarted,
    ) {
        val attempt = own.attempt
        System.err.println("${server.name} is back ${seconds(own.killedAt)} after its kill")
        attempt.restarting = false
        attempt.session.send(Restarted(back.request, back.tick))
        attempt.fresh.values.forEach(attempt.session::send)
        attempt.fresh.clear()
    }

    /** Starts the next boot of [own]'s Paper, with the restart flags and the cache, and its boot limit. */
    private fun bootOwn(
        server: Server,
        own: Own,
    ) {
        val boot = aot.boot(aotKey, server.name)
        own.training = boot as? AotCache.Boot.Train
        own.bootedAt = System.nanoTime()
        own.part = game.bootOwn(own.folder, RESTART_FLAGS + boot.flags, again = own.rules.boots > 1).also(::watch)
        val number = own.rules.boots
        System.err.println(
            "${server.name} boots (${if (boot is AotCache.Boot.Use) "from its cache" else "training its cache"}), boot $number",
        )
        thread(name = "playtest-pool-${server.name}-boot-$number", isDaemon = true) {
            Thread.sleep(TimeUnit.SECONDS.toMillis(OwnPaper.BOOT_SECONDS))
            events.put(Event.OwnBootTimedOut(server.name, number))
        }
    }

    /**
     * [own]'s Paper is lost for [cause]: its process ends, its folder stays for its log, and its players
     * go back to the shared Paper. A leased attempt fails with the cause; one not leased yet is recorded
     * as failed here, as its session never runs it.
     */
    private fun lostOwn(
        server: Server,
        own: Own,
        cause: String,
    ) {
        own.lost = true
        own.part?.process?.let {
            it.destroyForcibly()
            it.waitFor(STOP_SECONDS, TimeUnit.SECONDS)
        }
        val reason = "$cause; see ${game.keepLost(own.folder)}"
        System.err.println("The Paper ${server.name} is lost: $reason")
        val attempt = own.attempt
        sendBack(attempt)
        if (attempt.started) return attempt.session.send(PaperLost(attempt.players.first().name(), reason))
        val submission = attempt.submit.submission()
        val claimed = timings.remove(attempt.session to submission)?.steps.orEmpty()
        runs.record(attempt.session.hello.name(), attempt.submit, Result(submission, 0, reason, null, listOf(), "", listOf()), claimed)
        attempt.session.send(LeaseFailed(submission, reason))
        end(attempt)
        claims.release(attempt.players)
        lend()
    }

    /** [attempt]'s players go back to the shared Paper; each sits out until its client steps there again. */
    private fun sendBack(attempt: Attempt) {
        for (player in attempt.players) {
            val client = clientOf(player.uuid())?.takeIf { it.on == attempt.server } ?: continue
            client.on = shared
            client.joined = false
            client.ready = false
            connect(client)
        }
    }

    /** An own Paper's process ended: a killed one boots again; once its attempt is over its folder goes. */
    private fun ownExited(
        server: Server,
        own: Own,
        part: Part,
    ) {
        game.forget(part)
        val code = part.process.exitValue()
        own.training?.let { aot.trained(it, code) }
        own.training = null
        act(server, own.rules.exited(code))
        if (own.part !== part || !own.rules.over) return
        owns.remove(server.name)
        if (!own.lost) game.removeOwn(own.folder)
    }

    private fun seconds(sinceNanos: Long) = "%.2f s".format((System.nanoTime() - sinceNanos) / 1e9)

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
        timings[session to reclaim.submission()]?.since = System.currentTimeMillis()
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
        attempt.server.own?.let { act(attempt.server, it.rules.ended()) }
        lend()
    }

    /** The attempt is over for Paper: its players' work no longer holds back ticks, and their records reach nobody. */
    private fun end(attempt: Attempt) {
        attempts.remove(attempt.id)
        attempt.players.forEach { attemptOf.remove(it.name()) }
        attempt.server.peer?.send(Release(attempt.id))
    }

    /** A game part ended: a client's is lost and replaced, Paper's ends the game. A replaced client's old part ends unheard. */
    private fun exited(part: Part) {
        owns.values.firstOrNull { it.own?.part === part }?.let { server -> return ownExited(server, checkNotNull(server.own), part) }
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
        // The new client joins the shared Paper.
        client.on = shared
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
                timings[attempt.session to attempt.submit.submission()]?.since = System.currentTimeMillis()
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
        client.on.own?.let { return act(client.on, it.rules.ready(client.player.name())) }
        if (client.lost) {
            client.lost = false
            claims.letBack(client.player, Out.LOST_CLIENT)
        }
        // Back on the shared Paper from a restart attempt's own, the player serves claims again.
        claims.letBack(client.player, Out.AWAY)
        unpark()
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
        const val STOP_SECONDS = 10L

        /** How long the pool waits, once every session left, for its own Papers to exit; a training one assembles its cache meanwhile. */
        const val OWN_EXIT_SECONDS = 60L

        /**
         * How a restart attempt's own Paper boots (spike P7's bestq): C1 only and the serial collector,
         * as a Paper that lives for one requirement never repays C2's warm up, with the ahead of time
         * cache's flags. Java 25 builds no cache of Minecraft's invokedynamic sites, so they stay unlinked.
         */
        val RESTART_FLAGS =
            listOf(
                "-XX:TieredStopAtLevel=1",
                "-XX:+UseSerialGC",
                "-XX:-UsePerfData",
                "-Xss512k",
                "-XX:+UnlockDiagnosticVMOptions",
                "-XX:-AOTInvokeDynamicLinking",
            )
    }
}
