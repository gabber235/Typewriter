package com.typewritermc.playtest.pool

import com.typewritermc.playtest.pool.PaperRules.Do
import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.AttemptStep
import com.typewritermc.playtest.wire.Message.BarrierSeen
import com.typewritermc.playtest.wire.Message.Claim
import com.typewritermc.playtest.wire.Message.Claimed
import com.typewritermc.playtest.wire.Message.ClientLost
import com.typewritermc.playtest.wire.Message.ClientRequest
import com.typewritermc.playtest.wire.Message.ClientStalled
import com.typewritermc.playtest.wire.Message.Connect
import com.typewritermc.playtest.wire.Message.Covered
import com.typewritermc.playtest.wire.Message.CoveredClass
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

        /** Boot [boot] of the Paper [name] may have outlived its limit. */
        data class BootTimedOut(
            val name: String,
            val boot: Int,
        ) : Event
    }

    /** One warm client and its player. A lost client's player waits for a new client of the same name. */
    private class Client(
        val player: Player,
    ) {
        var part: Part? = null
        var peer: Peer? = null
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

        /** The submission this attempt runs, which keeps what it covered across its bodies. */
        val key: Pair<Peer, Long> get() = session to submit.submission()
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
    private val runs = RunRecords()

    // What each submission's attempt covered: its Paper's reads, and the lines they came to at its last settle.
    private val coverage = Coverage<Pair<Peer, Long>>()
    private val covered = mutableMapOf<Pair<Peer, Long>, List<CoveredClass>>()
    private val coverageCosts = mutableMapOf<Pair<Peer, Long>, CoverageCost>()

    /**
     * What one submission's coverage cost: the main thread time of each Paper read handed to it (a read
     * two attempts share counts for each), and the pool's analyses at its settles.
     */
    private class CoverageCost {
        var reads = 0
        var readNanos = 0L
        var analyses = 0
        var analysisNanos = 0L
        var lastAnalysisAt = 0L

        /** The cost as one step of the attempt's record. */
        fun step(): AttemptStep =
            AttemptStep(
                lastAnalysisAt,
                analysisNanos / 1_000_000,
                "coverage: $reads reads held Paper's main thread %.3f ms; $analyses analyses took %.1f ms"
                    .format(java.util.Locale.ROOT, readNanos / 1e6, analysisNanos / 1e6),
            )
    }

    private val sessions = mutableSetOf<Peer>()
    private val queued = mutableMapOf<Pair<Peer, Long>, Queued>()
    private val timings = mutableMapOf<Pair<Peer, Long>, Timing>()

    // Attempts whose next body waits until nothing holds their players out.
    private val parked = mutableListOf<Attempt>()
    private val hung = mutableMapOf<String, HungWork>()
    private val attempts = Attempts<Attempt>()
    private val requests = mutableMapOf<Long, Routed<Long>>()
    private val barriers = mutableMapOf<Int, Routed<Int>>()
    private lateinit var game: Game
    private lateinit var shared: Server

    // Every Paper the pool runs, the shared one included, each under a name and in a folder of its own.
    private val papers = Papers(folderOf = { game.ownFolder(it) }, remove = { game.removeOwn(it) })
    private val aot = AotCache(settings.aotDir)

    // Every restart Paper of the pool boots the same JDK, class path, plugins and flags.
    private val aotKey by lazy {
        val java = settings.java.toRealPath()
        val release = java.parent.parent.resolve("release")
        val jdk = "$java\n" + if (Files.isRegularFile(release)) Files.readString(release) else ""
        AotCache.key(
            jdk,
            PaperServer.of(settings.paperDir).classPath + listOf(settings.agentJar, settings.coverageAgentJar, settings.pluginJar),
            RESTART_FLAGS,
        )
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
        val startedAt = System.nanoTime()
        game = Game.start(settings, server.localPort, clients.map { it.player.name() })
        shared = Server(game.paper, SharedPaper(game.paper.name, clients.map { it.player.name() }.toSet()))
        shared.part = game.paperPart
        shared.boots = 1
        shared.bootedAt = startedAt
        papers.add(shared)
        clients.forEach { it.on = shared }
        game.parts.forEach { part ->
            watch(part)
            clients.firstOrNull { it.player.name() == part.player }?.part = part
        }
        bootLimit(shared)
        try {
            while (!sawSession || sessions.isNotEmpty()) handle(events.take())
            // Every attempt ended, so each own Paper halts on its own; one that trained writes its cache as
            // it exits, which the pool keeps only once it hears the exit.
            val ownsEndBy = System.nanoTime() + TimeUnit.SECONDS.toNanos(OWN_EXIT_SECONDS)
            while (papers.all.any { it !== shared }) handle(events.poll(ownsEndBy - System.nanoTime(), TimeUnit.NANOSECONDS) ?: break)
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

            is Event.BootTimedOut -> {
                papers[event.name]?.let { act(it, it.rules.bootTimedOut(event.boot)) }
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
                val server = papers[peer.hello.name()] ?: return peer.close()
                server.peer = peer
                System.err.println("${server.name} is up after ${seconds(server.bootedAt)} of boot ${server.boots}")
                act(server, server.rules.connected())
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
                    attempt.server.peer?.send(Settle(attempt.id)) ?: session.send(Settled(message.id(), covered[attempt.key].orEmpty()))
                }
            }

            is Restart -> {
                val attempt =
                    attemptOf(session, message.submission())
                        ?: return System.err.println("$session asked to restart the Paper of an attempt that no longer runs")
                act(attempt.server, attempt.server.rules.restart(message.request()))
            }

            is Result -> {
                val attempt = attemptOf(session, message.submission()) ?: return
                val claimed = timings.remove(session to message.submission())?.steps.orEmpty()
                val cost = coverageCosts.remove(attempt.key)?.step()
                runs.record(
                    session.hello.name(),
                    attempt.submit,
                    message,
                    claimed + listOfNotNull(cost),
                    covered.remove(attempt.key).orEmpty(),
                )
                coverage.forget(attempt.key)
                release(attempt, "its session sent its result")
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
                runs.record(session.hello.name(), submit, Result(submit.submission(), 0, reason, null, listOf(), "", listOf(), listOf()))
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
     * inputs and captures for their clients. A message naming a player no attempt of the session holds reaches neither.
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
        attempts.all
            .firstOrNull { attempt ->
                attempt.session == session && attempt.players.any { it.uuid() == player }
            }?.server

    /** The Paper that opened the connection [peer]. */
    private fun serverOf(peer: Peer): Server? = papers.all.firstOrNull { it.peer == peer }

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

            // Paper read the attempt's last counts just before; the session hears all the attempt covered so far.
            is Covered -> {
                message.attempts().forEach { id ->
                    attempts[id]?.let {
                        coverage.add(it.key, message.exec())
                        val cost = coverageCosts.getOrPut(it.key, ::CoverageCost)
                        cost.reads++
                        cost.readNanos += message.readNanos()
                    }
                }
            }

            is Settled -> {
                attempts[message.id()]?.let {
                    val start = System.nanoTime()
                    val lines = coverage.covered(it.key, it.server.folder.classes)
                    val cost = coverageCosts.getOrPut(it.key, ::CoverageCost)
                    cost.analyses++
                    cost.analysisNanos += System.nanoTime() - start
                    cost.lastAnalysisAt = System.currentTimeMillis()
                    covered[it.key] = lines
                    it.session.send(Settled(it.submit.submission(), lines))
                }
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

    /** [server] resumed its attempt after a restart, or could not. */
    private fun resumed(
        server: Server,
        message: Resumed,
    ) {
        val failure = message.failure()
        val rules = server.rules
        if (failure != null) return act(server, rules.failed("${server.name} could not resume its attempt: $failure"))
        act(server, rules.resumed(message.tick()))
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
                attempts.of(name)?.let { reset(it, name) }
            }

            is Perceived -> {
                attempts.of(name)?.let { perceived(it, name, message) }
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

    /** [client] is in the world of the Paper it is on. */
    private fun joined(client: Client) {
        act(client.on, client.on.rules.joined(client.player.name()))
    }

    /** [client] lost a Paper it was not told to leave; a drop off a Paper the pool already sent it away from is no news. */
    private fun disconnected(
        client: Client,
        message: Disconnected,
    ) {
        val server = client.on
        if (message.port() != server.port) return
        // The client may tell before the pool hears the process exit.
        act(server, server.rules.dropped(client.player.name(), message.reason(), paperAlive = server.part?.process?.isAlive != false))
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
        val server = attempt.server
        val names = attempt.players.joinToString { it.name() }
        if (failure != null) return act(server, server.rules.failed("${server.name} could not claim $names: $failure"))
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
            attempt.session.send(Lease(attempt.submit.submission(), attempt.players, attempt.region, attempt.server.name))
            attempt.fresh.values.forEach(attempt.session::send)
        }
    }

    /** Hands a barrier back under the session's own id, unless it belongs to an attempt that already ended. */
    private fun barrierSeen(message: BarrierSeen) {
        val routed = barriers.remove(message.barrier()) ?: return
        val attempt = attempts.of(message.player()) ?: return
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
                attempts.all.filter { it.session == peer }.forEach { release(it, "its session left") }
                lend()
            }

            Role.CLIENT -> {
                clients.firstOrNull { it.peer == peer }?.let { lost(it, "its connection to the pool closed") }
            }

            Role.PAPER -> {
                val server = serverOf(peer) ?: return
                server.peer = null
                act(server, server.rules.closed())
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
                (attempts.all + parked).filter { it.session == session }.map { it.submit }
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
     * The Paper of a new attempt of [submit] claims [players]: it wipes them and puts them in a region no
     * attempt on it used before. A restart attempt gets a Paper of its own, named after the attempt:
     * it boots while they wait on the shared Paper, and they join it once it is up.
     */
    private fun claim(
        session: Peer,
        submit: Submit,
        players: List<Player>,
    ): Attempt {
        val id = ++nextAttempt
        val server = if (submit.restartsPaper()) papers.restart(id, players.map { it.name() }.toSet()) else shared
        val claiming = server.rules.claim(id)
        val attempt = Attempt(id, session, submit, players, claiming.region, server)
        val names = players.joinToString { it.name() }
        timings[session to submit.submission()]?.took("claim $names on ${server.name}")
        attempts.start(attempt.id, attempt, attempt.players.map { it.name() }, server.rules)
        System.err.println("Attempt ${attempt.id}: ${submit.testId()} on $names on ${server.name} in ${attempt.region}")
        act(server, claiming.todo)
        return attempt
    }

    /** Does what the rules of [server] say comes next. */
    private fun act(
        server: Server,
        todo: List<Do>,
    ) {
        for (next in todo) {
            when (next) {
                is Do.ToPaper -> toPaper(server, next)
                is Do.ToPlayers -> toPlayers(server, next)
                is Do.Life -> life(server, next)
                is Do.ToGame -> toGame(server, next)
            }
        }
    }

    private fun toPaper(
        server: Server,
        next: Do.ToPaper,
    ) {
        val message =
            when (next) {
                is Do.RegionsAhead -> RegionsAhead(next.regions)
                Do.Step -> Stepping()
                is Do.Claim -> attempts[next.attempt]?.let { Claim(it.id, it.players.map { player -> player.uuid() }, it.region) }
                is Do.Resume -> attempts[next.attempt]?.let { Resume(it.id, it.players.map { player -> player.uuid() }) }
            }
        message?.let { server.peer?.send(it) }
    }

    private fun toPlayers(
        server: Server,
        next: Do.ToPlayers,
    ) {
        when (next) {
            is Do.Gather -> gather(server, next.attempt)

            Do.Connect -> clients.filter { it.on === server }.forEach(::connect)

            is Do.Free -> clientNamed(next.player)?.let(::free)

            is Do.Lose -> clientLost(next.player, next.cause)

            // Records sent before the drop show the Paper that is gone; the next ones show the new one.
            is Do.Forget -> attempts.of(next.player)?.fresh?.remove(next.player)
        }
    }

    private fun life(
        server: Server,
        next: Do.Life,
    ) {
        when (next) {
            is Do.Boot -> boot(server, next.number)
            is Do.Kill -> kill(server, next.attempt)
            is Do.Restarted -> restarted(server, next)
            is Do.Lost -> lostPaper(server, next.attempt, next.cause)
            is Do.Return -> returnFrom(server, next.attempt)
            Do.Gone -> gone(server)
        }
    }

    private fun toGame(
        server: Server,
        next: Do.ToGame,
    ) {
        when (next) {
            Do.Booted -> {
                booted = true
                lend()
            }

            // The Paper's own log leads, also once its process ended and left the game's parts.
            is Do.Fail -> {
                val logs = (listOfNotNull(server.part) + game.parts).distinct().joinToString { it.log.toString() }
                fail("${next.cause}; see $logs")
            }

            is Do.Note -> {
                System.err.println("${server.name}: ${next.text}")
            }
        }
    }

    /** [client]'s player serves claims again: a new client in place of a lost one frees it, as does one back from a restart attempt's Paper. */
    private fun free(client: Client) {
        if (client.lost) {
            client.lost = false
            claims.letBack(client.player, Out.LOST_CLIENT)
        }
        claims.letBack(client.player, Out.AWAY)
        unpark()
        lend()
    }

    /** [client] is on [server] from now on, as a client that comes anew. */
    private fun moveTo(
        client: Client,
        server: Server,
    ) {
        client.on = server
        act(server, server.rules.arriving(client.player.name()))
    }

    /** The players of [attempt] leave the shared Paper for [server], its own; they serve no other claim meanwhile. */
    private fun gather(
        server: Server,
        attempt: Long,
    ) {
        for (player in running(attempt).players) {
            val client = clientOf(player.uuid()) ?: continue
            moveTo(client, server)
            claims.holdOut(client.player, Out.AWAY)
        }
    }

    /** Ends [server]'s process as a crash would; what the players of [id] perceive waits until it is back. */
    private fun kill(
        server: Server,
        id: Long,
    ) {
        val attempt = running(id)
        attempt.restarting = true
        attempt.fresh.clear()
        server.killedAt = System.nanoTime()
        server.part?.process?.destroyForcibly()
    }

    /** [server] is back: the session hears so, then the latest record of each player. */
    private fun restarted(
        server: Server,
        back: Do.Restarted,
    ) {
        val attempt = running(back.attempt)
        System.err.println("${server.name} is back ${seconds(server.killedAt)} after its kill")
        attempt.restarting = false
        attempt.session.send(Restarted(back.request, back.tick))
        attempt.fresh.values.forEach(attempt.session::send)
        attempt.fresh.clear()
    }

    /** Starts boot [number] of [server], with the restart flags and the cache, and its boot limit. */
    private fun boot(
        server: Server,
        number: Int,
    ) {
        val boot = aot.boot(aotKey, server.name)
        server.boots = number
        server.training = boot as? AotCache.Boot.Train
        server.bootedAt = System.nanoTime()
        server.part = game.bootOwn(server.folder, RESTART_FLAGS + boot.flags, again = number > 1).also(::watch)
        System.err.println(
            "${server.name} boots (${if (boot is AotCache.Boot.Use) "from its cache" else "training its cache"}), boot $number",
        )
        bootLimit(server)
    }

    /** Reports into the loop once [server]'s boot now may have outlived its limit. */
    private fun bootLimit(server: Server) {
        val number = server.boots
        thread(name = "playtest-pool-${server.name}-boot-$number", isDaemon = true) {
            Thread.sleep(TimeUnit.SECONDS.toMillis(server.rules.bootSeconds))
            events.put(Event.BootTimedOut(server.name, number))
        }
    }

    /**
     * [server] is lost for [cause]: its process ends, its folder stays for its log, and its players go
     * back to the shared Paper. A leased attempt fails with the cause; one not leased yet is recorded as
     * failed here, as its session never runs it.
     */
    private fun lostPaper(
        server: Server,
        id: Long,
        cause: String,
    ) {
        server.lost = true
        server.part?.process?.let {
            it.destroyForcibly()
            it.waitFor(STOP_SECONDS, TimeUnit.SECONDS)
        }
        val reason = "$cause; see ${game.keepLost(server.folder)}"
        System.err.println("The Paper ${server.name} is lost: $reason")
        val attempt = running(id)
        sendBack(attempt)
        if (attempt.started) return attempt.session.send(PaperLost(attempt.players.first().name(), reason))
        val submission = attempt.submit.submission()
        val claimed = timings.remove(attempt.session to submission)?.steps.orEmpty()
        runs.record(
            attempt.session.hello.name(),
            attempt.submit,
            Result(submission, 0, reason, null, listOf(), "", listOf(), listOf()),
            claimed,
        )
        attempt.session.send(LeaseFailed(submission, reason))
        release(attempt, "its Paper was lost")
    }

    /** [attempt]'s players go back to the shared Paper; each sits out until its client steps there again. */
    private fun sendBack(attempt: Attempt) {
        for (player in attempt.players) {
            val client = clientOf(player.uuid())?.takeIf { it.on == attempt.server } ?: continue
            moveTo(client, shared)
            connect(client)
        }
    }

    /** [attempt] ended: its players go back and [server] stops; its plugin halts once the pool is gone, and a training boot writes its cache as it exits. */
    private fun returnFrom(
        server: Server,
        attempt: Long,
    ) {
        sendBack(running(attempt))
        server.peer?.close() ?: server.part?.process?.destroyForcibly()
    }

    /** [server]'s process ended for good: the pool forgets it, and its folder goes unless it was lost. */
    private fun gone(server: Server) = papers.gone(server)

    /** [server]'s process ended; a boot that trained a cache keeps it only if it ended cleanly. */
    private fun paperExited(
        server: Server,
        part: Part,
    ) {
        game.forget(part)
        val code = part.process.exitValue()
        server.training?.let { aot.trained(it, code) }
        server.training = null
        act(server, server.rules.exited(code))
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
        end(attempt, "its session claims its players again for its next body")
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
        val attempt = attempts.of(message.player())
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

    /** [attempt] ended for [why], and its players serve the next claims. */
    private fun release(
        attempt: Attempt,
        why: String,
    ) {
        end(attempt, why)
        claims.release(attempt.players)
        lend()
    }

    /**
     * [attempt] ended for [why], the one way every attempt ends: its Paper releases the players, so their
     * work no longer holds back ticks, then the Paper's rules say what follows while the attempt can still
     * be found. After that, the players' records reach nobody.
     */
    private fun end(
        attempt: Attempt,
        why: String,
    ) {
        attempt.server.peer?.send(Release(attempt.id))
        attempts.end(attempt.id, why) { act(attempt.server, it) }
    }

    /** The attempt [id], which the rules of its Paper name only while it runs. */
    private fun running(id: Long): Attempt = checkNotNull(attempts[id]) { "attempt $id no longer runs" }

    /** A game part ended: a Paper's rules say what follows, a client's is lost and replaced, a display's ends the game. A replaced client's old part ends unheard. */
    private fun exited(part: Part) {
        papers.all.firstOrNull { it.part === part }?.let { return paperExited(it, part) }
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
        client.peer?.close()
        client.peer = null
        // The new client joins the shared Paper.
        moveTo(client, shared)
        claims.holdOut(client.player, Out.LOST_CLIENT)
        val replaced = game.replaceClient(name)
        client.part = replaced.replacement.also(::watch)
        val reason = "$cause; see ${replaced.lostLog}"
        System.err.println("The client of $name is lost: $reason. A new one starts.")
        attempts.of(name)?.let { attempt ->
            if (attempt.started) {
                attempt.session.send(ClientLost(name, reason))
            } else {
                // Back in line on its own; the attempts beside it get their leases without it.
                end(attempt, "the client of $name was lost before its lease")
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

    /** [client] steps with the Paper it is on. */
    private fun ready(client: Client) {
        act(client.on, client.on.rules.ready(client.player.name()))
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
    ): Attempt? = attempts.all.firstOrNull { it.session == session && it.submit.submission() == submission }

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
