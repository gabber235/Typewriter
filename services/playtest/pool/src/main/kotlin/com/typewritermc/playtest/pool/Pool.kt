package com.typewritermc.playtest.pool

import com.typewritermc.playtest.pool.PaperRules.Do
import com.typewritermc.playtest.wire.HeapShare
import com.typewritermc.playtest.wire.PoolFile
import com.typewritermc.playtest.wire.Wire
import skirout.harness.v1.test_run.Step
import skirout.harness.v1.wire.Answer
import skirout.harness.v1.wire.Ask
import skirout.harness.v1.wire.ClientLoss
import skirout.harness.v1.wire.ClientLossKind
import skirout.harness.v1.wire.Lease
import skirout.harness.v1.wire.Message
import skirout.harness.v1.wire.PaperAsk
import skirout.harness.v1.wire.PaperLoss
import skirout.harness.v1.wire.PaperLossKind
import skirout.harness.v1.wire.Player
import skirout.harness.v1.wire.PlayerEvent
import skirout.harness.v1.wire.Region
import skirout.harness.v1.wire.Reply
import skirout.harness.v1.wire.Request
import skirout.harness.v1.wire.Result
import skirout.harness.v1.wire.Role
import skirout.harness.v1.wire.Submit
import java.io.BufferedInputStream
import java.io.DataInputStream
import java.io.IOException
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import java.net.SocketException
import java.nio.channels.FileChannel
import java.nio.file.Files
import java.nio.file.StandardOpenOption
import java.util.UUID
import java.util.concurrent.LinkedBlockingQueue
import java.util.concurrent.TimeUnit
import kotlin.concurrent.thread
import kotlin.system.exitProcess

/**
 * Starts the pool for the pool folder. The lock file makes it the only pool there; another pool that
 * holds it serves this run, or is being stopped by the test JVM that started this one, so this one
 * exits at once. Test JVMs find the pool by the pool file it writes once it listens and removes as it
 * exits.
 */
fun main() {
    val settings = PoolSettings.fromSystemProperties()
    Files.createDirectories(settings.poolDir)
    val lockFile = FileChannel.open(settings.poolDir.resolve("pool.lock"), StandardOpenOption.CREATE, StandardOpenOption.WRITE)
    val lock = lockFile.tryLock() ?: exitProcess(0)
    Files.createDirectories(settings.logs)
    val poolFile = settings.poolDir.resolve(PoolFile.NAME)
    ServerSocket(0, BACKLOG, InetAddress.getLoopbackAddress()).use { server ->
        val pool = Pool(settings, server)
        // Every starter appends its output to the log. A pool that starts its run empties it, so the log
        // holds this run alone; one that continues its run adds to what the earlier pool of it logged.
        if (!pool.continuing) FileChannel.open(settings.poolLog, StandardOpenOption.CREATE, StandardOpenOption.WRITE).use { it.truncate(0) }
        // The test JVM that started this pool says it exited while starting, and points at this log.
        HeapShare.overLimit(settings.clients)?.let { reason ->
            pool.couldNotRun(reason)
            exitProcess(1)
        }
        PoolFile.of(server.localPort, settings.run).write(poolFile)
        try {
            pool.run()
        } finally {
            Files.deleteIfExists(poolFile)
            lock.release()
        }
    }
    exitProcess(0)
}

private const val BACKLOG = 16

/**
 * The pool's single loop: every connection and process reports into one queue, and only this loop
 * touches the pool's state. It boots the game, hands each submitted attempt the players it claims once
 * they are free, wiped and in a region of its own, routes each attempt's messages, and stops once its
 * run is over: the last session left, or none came while its owner could open one. A lease that runs
 * out before its session sends the result ends the attempt, so a stuck session cannot keep players.
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
        val id: AttemptId,
        val submission: Submission,
        val players: List<Player>,
        val region: Region,
        val server: Server,
    ) {
        val session: Peer get() = submission.session
        val submit: Submit get() = submission.submit

        val reset = mutableSetOf<String>()

        // The latest record each player perceived, as its player event.
        val fresh = mutableMapOf<String, Message>()
        var started = false

        // While its Paper restarts, only each player's latest record waits, as before the lease.
        var restarting = false
        var group: List<Attempt> = listOf(this)
    }

    /**
     * One attempt a session submitted, from its submit until it finishes, across every body it runs:
     * waiting for its players, running an [Attempt] on them, or parked with them until nothing holds
     * them out. It keeps the pool's steps for its run file, and its coverage is kept under it, so what
     * its bodies covered adds up. It ends one way: [finish].
     */
    private class Submission(
        val session: Peer,
        val submit: Submit,
        var state: State,
    ) {
        val id = SubmissionId(submit.submission)
        val key: Pair<Peer, SubmissionId> get() = session to id
        val timing = Timing(System.currentTimeMillis())

        sealed interface State {
            /** Waiting for its players, with the submissions submitted [together] with it. */
            data class Queued(
                val together: Long,
            ) : State

            data class Running(
                val attempt: Attempt,
            ) : State

            /** Between bodies, holding [players] until nothing holds them out. */
            data class Parked(
                val players: List<Player>,
            ) : State
        }

        val running: Attempt? get() = (state as? State.Running)?.attempt
    }

    /** Work that hung on a player and still runs, keeping the player out of every claim, and the case whose attempt it hung in. */
    private class HungWork(
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
        val steps = mutableListOf<Step>()

        /** One step ended now: it began at [since], and the next one begins now. */
        fun took(says: String) {
            val now = System.currentTimeMillis()
            steps += Step(atMillis = since, actor = null, says = says, durationMillis = now - since)
            since = now
        }
    }

    private val events = LinkedBlockingQueue<Event>()
    private val clients =
        (1..settings.clients).map {
            Client(Player(name = "gv-$it", uuid = UUID.nameUUIDFromBytes("OfflinePlayer:gv-$it".toByteArray()).toString()))
        }
    private val claims = Claims<Peer, Player>(clients.map { it.player })
    private val runs = RunRecords(settings.run, settings.testRun, settings.policy, stillOut = { stillOut() })

    /** Whether an earlier pool of this run left its file, which this pool takes up and adds to. */
    val continuing = runs.continueFrom()

    /** Sessions the pool refused as they joined: what they still send is dropped until they leave. */
    private val refused = mutableSetOf<Peer>()

    private val lifetime =
        Lifetime<Peer>(System.currentTimeMillis(), TimeUnit.SECONDS.toMillis(OWNER_SECONDS), TimeUnit.SECONDS.toMillis(GRACE_SECONDS))

    // What each submission's attempts covered: its Paper's reads, and the lines they came to at its last settle.
    private val coverage = Coverage<Submission>()

    // Every submission that has not finished, in the order its session submitted it.
    private val submissions = linkedMapOf<Pair<Peer, SubmissionId>, Submission>()
    private val hung = mutableMapOf<String, HungWork>()
    private val attempts = Attempts<Attempt>()
    private val requests = Routes<Peer, Long>()
    private val barriers = Routes<Peer, Int>()
    private lateinit var game: Game
    private lateinit var shared: Server

    // Every Paper the pool runs, the shared one included, each under a name and in a folder of its own.
    private val papers = Papers(folderOf = { game.ownFolder(it) }, remove = { game.removeOwn(it) })
    private val aot = AotCache(settings.aotDir)

    // Every restart Paper of the pool boots the same JDK, class path, plugins and flags, its heap share included.
    private val aotKey by lazy {
        val java = settings.java.toRealPath()
        val release = java.parent.parent.resolve("release")
        val jdk = "$java\n" + if (Files.isRegularFile(release)) Files.readString(release) else ""
        AotCache.key(
            jdk,
            PaperServer.of(settings.paperDir).classPath + listOf(settings.agentJar, settings.coverageAgentJar, settings.pluginJar),
            listOf(HeapShare.OWN_PAPER.flag()) + RESTART_FLAGS,
        )
    }
    private var failure: String? = null
    private var nextAttempt = 0L
    private var nextTogether = 0L

    // Every client was ready once: the game booted, and from then on the pool lends players.
    private var booted = false

    fun run() {
        thread(name = "playtest-pool-accept", isDaemon = true) { accept() }
        val startedAt = System.nanoTime()
        game =
            try {
                Game.start(settings, server.localPort, clients.map { it.player.name }, continuing)
            } catch (cannot: Exception) {
                // The pool exits with the cause in its log, so the test JVM that started it says it exited while starting.
                couldNotRun("the game could not start: $cannot; see ${settings.poolLog}")
                throw cannot
            }
        shared = Server(game.paper, SharedPaper(game.paper.name, clients.map { it.player.name }.toSet()))
        shared.part = game.paperPart
        shared.boots = 1
        shared.bootedAt = startedAt
        papers.add(shared)
        clients.forEach { it.on = shared }
        game.parts.forEach { part ->
            watch(part)
            clients.firstOrNull { it.player.name == part.player }?.part = part
        }
        bootLimit(shared)
        try {
            while (!lifetime.over(System.currentTimeMillis())) {
                next()?.let(::handle)
                attempts.overdue(System.currentTimeMillis()).forEach(::expire)
            }
            // A session that comes now finds the pool on its way out, and waits for the next one.
            server.close()
            // Every attempt ended, so each own Paper halts on its own; one that trained writes its cache as
            // it exits, which the pool keeps only once it hears the exit.
            val ownsEndBy = System.nanoTime() + TimeUnit.SECONDS.toNanos(OWN_EXIT_SECONDS)
            while (papers.all.any { it !== shared }) handle(events.poll(ownsEndBy - System.nanoTime(), TimeUnit.NANOSECONDS) ?: break)
        } finally {
            game.stop()
        }
    }

    /** The next event, or null once the lifetime or a lease may have run out first. */
    private fun next(): Event? {
        val wakeAt = listOfNotNull(lifetime.wakeAt(), attempts.nextDeadline()).minOrNull() ?: return events.take()
        return events.poll(maxOf(0, wakeAt - System.currentTimeMillis()), TimeUnit.MILLISECONDS)
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
                lifetime.joined(peer)
                failure?.let { peer.send(Message.createRefused(reason = it)) }
            }

            Role.PAPER -> {
                val server = papers[peer.hello.name] ?: return peer.close()
                server.peer = peer
                System.err.println("${server.name} is up after ${seconds(server.bootedAt)} of boot ${server.boots}")
                act(server, server.rules.connected())
            }

            Role.CLIENT -> {
                val client = clients.firstOrNull { it.player.name == peer.hello.name } ?: return peer.close()
                client.peer = peer
                connect(client)
            }

            // serve takes no hello of a role this build does not know.
            else -> {}
        }
    }

    /** Sends [client] to the Paper it is on once both are connected to the pool. */
    private fun connect(client: Client) {
        val server = client.on
        if (server.peer == null) return
        client.peer?.send(Message.createConnect(host = "127.0.0.1", port = server.port))
    }

    private fun received(
        peer: Peer,
        message: Message,
    ) {
        when (peer.role) {
            // What a refused session still sends is dropped until it leaves.
            Role.SESSION -> {
                if (peer !in refused) fromSession(peer, message)
            }

            Role.PAPER -> {
                serverOf(peer)?.let { fromPaper(it, message) }
            }

            Role.CLIENT -> {
                clients.firstOrNull { it.peer == peer }?.let { fromClient(it, message) }
            }

            // serve takes no hello of a role this build does not know.
            else -> {}
        }
    }

    private fun fromSession(
        session: Peer,
        message: Message,
    ) {
        when (message) {
            is Message.JoinWrapper -> {
                join(session, message.value)
            }

            is Message.QueueWrapper -> {
                queue(session, message.value.together)
            }

            Message.END -> {
                runs.ended(session)
                session.send(Message.ENDED)
            }

            is Message.ReclaimWrapper -> {
                reclaim(session, message.value)
            }

            // A lost own Paper runs no work that could still reach a later attempt, nor does an attempt whose lease ran out.
            is Message.SettleWrapper -> {
                val id = message.value.id
                val attempt = attemptOf(session, id) ?: return session.send(Message.createSettled(id = id, covered = listOf()))
                attempt.server.peer?.send(Message.createSettle(id = attempt.id.value))
                    ?: session.send(Message.createSettled(id = id, covered = coverage.latest(attempt.submission)))
            }

            is Message.RestartWrapper -> {
                val restart = message.value
                val attempt =
                    attemptOf(session, restart.submission)
                        ?: return System.err.println("$session asked to restart the Paper of an attempt that no longer runs")
                act(attempt.server, attempt.server.rules.restart(restart.request))
            }

            is Message.ResultWrapper -> {
                result(session, message.value)
            }

            else -> {
                toGame(session, message)
            }
        }
    }

    /**
     * [session] joins the pool's run. A session of another run is refused: its test JVM found this pool
     * through the pool file of its own run, so it reaches this pool only when its own pool exited between
     * that read and its connection and this pool took up the port.
     */
    private fun join(
        session: Peer,
        join: Message.Join,
    ) {
        if (join.run == settings.run) return runs.joined(session)
        refused += session
        session.sendLast(Message.createRefused(reason = "this pool serves the run ${settings.run}, not the run ${join.run}"))
    }

    /** [session]'s attempt ended with [result]: the run records it and its players serve the next claims. */
    private fun result(
        session: Peer,
        result: Result,
    ) {
        val attempt = attemptOf(session, result.submission) ?: return
        finish(attempt.submission, result, "its session sent its result")
    }

    /** Queues the claim of the attempts in [together], side by side, or declines each at once when the pool could never serve them. */
    private fun queue(
        session: Peer,
        together: List<Submit>,
    ) {
        try {
            claims.submit(session, *together.map { Claim(it.submission, it.players, it.restartsPaper) }.toTypedArray())
        } catch (unservable: IllegalArgumentException) {
            for (submit in together) {
                val reason = "${submit.requirement} cannot run here: ${unservable.message}"
                session.send(Message.createDeclined(submission = submit.submission, reason = reason))
                finish(Submission(session, submit, Submission.State.Queued(0)), failed(submit, 0, reason), "the pool can never serve it")
            }
            return
        }
        val key = ++nextTogether
        together.forEach { submit ->
            Submission(session, submit, Submission.State.Queued(key)).also { submissions[it.key] = it }
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
        if (named == null) return System.err.println("$session sent ${message.kind}, which a session never sends")
        if (named.isEmpty() || !named.all { holds(session, it) }) return
        val paper = serverOf(session, named.first())?.peer
        when (message) {
            is Message.RequestWrapper -> {
                val request = message.value
                val ask = request.ask
                if (ask is Ask.ClientWrapper) route(clientOf(ask.value.player)?.peer, session, request) else route(paper, session, request)
            }

            is Message.StepUntilWrapper -> {
                val step = message.value
                paper?.send(step.copy(barrier = barriers.route(session, step.barrier).toInt()).let(Message::StepUntilWrapper))
            }

            is Message.StopSteppingWrapper -> {
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
        peer?.send(Message.RequestWrapper(request.copy(id = requests.route(session, request.id))))
    }

    /** The players a message for the game acts on, or null for a message a session never sends. */
    private fun playersNamedBy(message: Message): List<String>? =
        when (message) {
            is Message.RequestWrapper -> playersAskedOf(message.value.ask)
            is Message.StepUntilWrapper -> listOf(message.value.player)
            is Message.StopSteppingWrapper -> listOf(message.value.player)
            else -> null
        }

    /** The players [ask] acts on, or null for an ask this build does not know. */
    private fun playersAskedOf(ask: Ask): List<String>? =
        when (ask) {
            is Ask.ClientWrapper -> {
                listOf(ask.value.player)
            }

            is Ask.PaperWrapper -> {
                when (val paper = ask.value) {
                    is PaperAsk.ProbeWrapper -> paper.value.players
                    is PaperAsk.QueryWrapper -> listOf(paper.value.player)
                    else -> null
                }
            }

            else -> {
                null
            }
        }

    private fun holds(
        session: Peer,
        player: String,
    ) = serverOf(session, player) != null

    /** The Paper of the attempt [session] runs on [player], if it holds that player. */
    private fun serverOf(
        session: Peer,
        player: String,
    ): Server? =
        attempts.all
            .firstOrNull { attempt ->
                attempt.session == session && attempt.players.any { it.uuid == player }
            }?.server

    /** The Paper that opened the connection [peer]. */
    private fun serverOf(peer: Peer): Server? = papers.all.firstOrNull { it.peer == peer }

    private fun fromPaper(
        server: Server,
        message: Message,
    ) {
        when (message) {
            is Message.ReplyWrapper -> {
                answer(message.value)
            }

            is Message.ClaimedWrapper -> {
                attempts[message.value.attempt]?.let { claimed(it, message.value.failure) }
            }

            is Message.ResumedWrapper -> {
                resumed(server, message.value)
            }

            is Message.CoveredWrapper -> {
                covered(message.value)
            }

            is Message.SettledWrapper -> {
                attempts[message.value.id]?.let(::settled)
            }

            is Message.PlayerEventWrapper -> {
                fromPaper(server, message.value)
            }

            is Message.HungEndedWrapper -> {
                hungEnded(message.value)
            }

            is Message.PlayerLeftWrapper -> {
                lostOn(
                    server,
                    message.value.player,
                    ClientLossKind.LEFT_PAPER,
                    "its player left Paper (${message.value.reason.lowercase()})",
                )
            }

            is Message.ClientStalledWrapper -> {
                lostOn(
                    server,
                    message.value.player,
                    ClientLossKind.STALLED,
                    "it acked no tick for 5 s after tick ${message.value.lastAcked}",
                )
            }

            else -> {
                System.err.println("${server.name} sent ${message.kind}, which Paper never sends")
            }
        }
    }

    private fun fromPaper(
        server: Server,
        event: PlayerEvent,
    ) {
        when (event.happened) {
            is PlayerEvent.Happened.WorkHungWrapper -> workHung(event)
            else -> System.err.println("${server.name} sent ${event.happened.kind}, which Paper never sends")
        }
    }

    /** Paper read and reset the counts [message] holds: each attempt it names ran since the read before. */
    private fun covered(message: Message.Covered) {
        message.attempts.forEach { id ->
            val attempt = attempts[id] ?: return@forEach
            coverage.add(attempt.submission, message.exec.toByteArray(), message.readNanos)
        }
    }

    /** Paper read [attempt]'s last counts just before: its session hears all the attempt covered so far. */
    private fun settled(attempt: Attempt) {
        val lines = coverage.covered(attempt.submission, attempt.server.folder.classes)
        attempt.session.send(Message.createSettled(id = attempt.submit.submission, covered = lines))
    }

    /** [server] resumed its attempt after a restart, or could not. */
    private fun resumed(
        server: Server,
        message: Message.Resumed,
    ) {
        val failure = message.failure
        val rules = server.rules
        if (failure != null) {
            val cause = "${server.name} could not resume its attempt: $failure"
            return act(server, rules.failed(PaperLossKind.RESUME_FAILED, cause))
        }
        act(server, rules.resumed(message.tick))
    }

    /** [server] lost [player]'s client, as [kind] says, for [cause]; a client the pool moved to another Paper left this one on purpose. */
    private fun lostOn(
        server: Server,
        player: String,
        kind: ClientLossKind,
        cause: String,
    ) {
        if (clientNamed(player)?.on == server) clientLost(player, kind, cause)
    }

    /** Paper or a client answered a request with [reply]: the session that sent it gets it under its own request id. */
    private fun answer(reply: Reply) {
        requests.answer(reply.request)?.let { it.session.send(Message.ReplyWrapper(reply.copy(request = it.id))) }
    }

    private fun fromClient(
        client: Client,
        message: Message,
    ) {
        val name = client.player.name
        when (message) {
            Message.JOINED -> {
                joined(client)
            }

            Message.READY -> {
                ready(client)
            }

            Message.RESET_DONE -> {
                attempts.of(name)?.let { reset(it, name) }
            }

            is Message.PlayerEventWrapper -> {
                fromClient(client, message)
            }

            is Message.ReplyWrapper -> {
                answer(message.value)
            }

            is Message.DisconnectedWrapper -> {
                disconnected(client, message.value)
            }

            else -> {
                System.err.println("$name sent ${message.kind}, which a client never sends")
            }
        }
    }

    private fun fromClient(
        client: Client,
        message: Message.PlayerEventWrapper,
    ) {
        val name = client.player.name
        when (val happened = message.value.happened) {
            is PlayerEvent.Happened.PerceivedWrapper -> attempts.of(name)?.let { perceived(it, name, message) }
            is PlayerEvent.Happened.BarrierSeenWrapper -> barrierSeen(message.value.player, happened.value.barrier)
            else -> System.err.println("$name sent ${happened.kind}, which a client never sends")
        }
    }

    /** [client] is in the world of the Paper it is on. */
    private fun joined(client: Client) {
        act(client.on, client.on.rules.joined(client.player.name))
    }

    /** [client] lost a Paper it was not told to leave; a drop off a Paper the pool already sent it away from is no news. */
    private fun disconnected(
        client: Client,
        message: Message.Disconnected,
    ) {
        val server = client.on
        if (message.port != server.port) return
        // The client may tell before the pool hears the process exit.
        act(server, server.rules.dropped(client.player.name, message.reason, paperAlive = server.part?.process?.isAlive != false))
    }

    /** A record, the player event [message], reaches the attempt's session once it holds the lease; until then only each player's latest waits. */
    private fun perceived(
        attempt: Attempt,
        player: String,
        message: Message,
    ) {
        if (attempt.started && !attempt.restarting) attempt.session.send(message) else attempt.fresh[player] = message
    }

    /** Paper claimed the attempt's players: each client resets, then the session gets the lease. */
    private fun claimed(
        attempt: Attempt,
        failure: String?,
    ) {
        val server = attempt.server
        val names = attempt.players.joinToString { it.name }
        if (failure != null) {
            val cause = "${server.name} could not claim $names: $failure"
            return act(server, server.rules.failed(PaperLossKind.CLAIM_FAILED, cause))
        }
        attempt.players.forEach { clientOf(it.uuid)?.peer?.send(Message.RESET) }
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
            attempts.leased(attempt.id.value, System.currentTimeMillis() + TimeUnit.SECONDS.toMillis(LEASE_SECONDS))
            attempt.submission.timing.took(
                "wipe ${attempt.players.joinToString { it.name }} into region (${attempt.region.x}, ${attempt.region.z})",
            )
            attempt.session.send(
                Message.LeaseWrapper(
                    Lease(
                        submission = attempt.submit.submission,
                        players = attempt.players,
                        region = attempt.region,
                        paper = attempt.server.name,
                    ),
                ),
            )
            attempt.fresh.values.forEach(attempt.session::send)
        }
    }

    /** Hands [player]'s [barrier] back under the session's own id, unless it belongs to an attempt that already ended. */
    private fun barrierSeen(
        player: String,
        barrier: Int,
    ) {
        val routed = barriers.answer(barrier.toLong()) ?: return
        val attempt = attempts.of(player) ?: return
        if (routed.session == attempt.session) {
            routed.session.send(
                Message.PlayerEventWrapper(
                    PlayerEvent(player = player, happened = PlayerEvent.Happened.createBarrierSeen(barrier = routed.id)),
                ),
            )
        }
    }

    private fun left(peer: Peer) {
        when (peer.role) {
            // What it asked gets no answers, and what its attempts covered goes with it.
            Role.SESSION -> {
                lifetime.left(peer, at = System.currentTimeMillis())
                val unfinished = submissions.values.filter { it.session == peer }
                // A refused session never joined its run, so it leaves nothing in the run's file.
                if (!refused.remove(peer)) abandon(peer, unfinished)
                claims.leave(peer)
                unfinished.forEach { forget(it, "its session left") }
                requests.leave(peer)
                barriers.leave(peer)
                lend()
            }

            Role.CLIENT -> {
                clients.firstOrNull { it.peer == peer }?.let { lost(it, ClientLossKind.LEFT_POOL, "its connection to the pool closed") }
            }

            Role.PAPER -> {
                val server = serverOf(peer) ?: return
                server.peer = null
                act(server, server.rules.closed())
            }

            // serve takes no hello of a role this build does not know.
            else -> {}
        }
    }

    /**
     * [session] left. Each attempt it submitted that had not ended, as a killed test JVM leaves them,
     * fails in its run's file, so the run never reads as complete without them.
     */
    private fun abandon(
        session: Peer,
        unfinished: List<Submission>,
    ) {
        // The game failed, so the attempts it never ran are no failures of their own: the run's file says why it failed.
        if (failure != null) return runs.ended(session)
        runs.abandoned(
            session,
            unfinished.map { it.submit },
            "its test JVM ended before the attempt did; see ${settings.poolLog}",
        )
    }

    /** Starts every attempt whose players are free: Paper claims them in a region no attempt used before. */
    private fun lend() {
        if (failure != null || !booted) return
        val claimed =
            claims.grants().mapNotNull { grant ->
                val submission = submissions[grant.session to SubmissionId(grant.submission)] ?: return@mapNotNull null
                val queued = submission.state as? Submission.State.Queued ?: return@mapNotNull null
                queued.together to claim(submission, grant.players)
            }
        claimed.groupBy({ it.first }, { it.second }).values.forEach { group -> group.forEach { it.group = group } }
    }

    /**
     * The Paper of a new attempt of [submission] claims [players]: it wipes them and puts them in a region
     * no attempt on it used before. A restart attempt gets a Paper of its own, named after the attempt:
     * it boots while they wait on the shared Paper, and they join it once it is up.
     */
    private fun claim(
        submission: Submission,
        players: List<Player>,
    ): Attempt {
        val id = AttemptId(++nextAttempt)
        val submit = submission.submit
        val server = if (submit.restartsPaper) papers.restart(id.value, players.map { it.name }.toSet()) else shared
        val claiming = server.rules.claim(id.value)
        val attempt = Attempt(id, submission, players, claiming.region, server)
        submission.state = Submission.State.Running(attempt)
        val names = players.joinToString { it.name }
        submission.timing.took("claim $names on ${server.name}")
        attempts.start(id.value, attempt, attempt.players.map { it.name }, server.rules)
        System.err.println("Attempt $id: ${submit.testId} on $names on ${server.name} in region (${attempt.region.x}, ${attempt.region.z})")
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
                is Do.RegionsAhead -> {
                    Message.createRegionsAhead(regions = next.regions)
                }

                Do.Step -> {
                    Message.STEPPING
                }

                is Do.Claim -> {
                    attempts[next.attempt]?.let {
                        Message.createClaim(attempt = it.id.value, players = it.players.map { player -> player.uuid }, region = it.region)
                    }
                }

                is Do.Resume -> {
                    attempts[next.attempt]?.let {
                        Message.createResume(
                            attempt = it.id.value,
                            players =
                                it.players.map { player ->
                                    player.uuid
                                },
                        )
                    }
                }
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

            is Do.Lose -> clientLost(next.player, ClientLossKind.DROPPED, next.cause)

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
            is Do.Lost -> lostPaper(server, next.attempt, next.kind, next.cause)
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
        act(server, server.rules.arriving(client.player.name))
    }

    /** The players of [attempt] leave the shared Paper for [server], its own; they serve no other claim meanwhile. */
    private fun gather(
        server: Server,
        attempt: Long,
    ) {
        for (player in running(attempt).players) {
            val client = clientOf(player.uuid) ?: continue
            moveTo(client, server)
            claims.holdOut(client.player, Out.AWAY)
        }
    }

    /**
     * Ends [server]'s process as a crash would; what the players of [id] perceive waits until it is back,
     * and the Paper's rules forget what each recorded until it steps with the new boot.
     */
    private fun kill(
        server: Server,
        id: Long,
    ) {
        val attempt = running(id)
        attempt.restarting = true
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
        attempt.session.send(Message.createReply(request = back.request, answer = Answer.createRestarted(tick = back.tick)))
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
     * [server] is lost for [cause]: its process ends, its log stays in the run's logs, and its players go
     * back to the shared Paper. A leased attempt fails with the cause; one not leased yet is recorded as
     * failed here, as its session never runs it.
     */
    private fun lostPaper(
        server: Server,
        id: Long,
        kind: PaperLossKind,
        cause: String,
    ) {
        server.part?.process?.let {
            it.destroyForcibly()
            it.waitFor(STOP_SECONDS, TimeUnit.SECONDS)
        }
        val loss = PaperLoss(kind = kind, detail = cause, log = server.folder.log.toString())
        val reason = "$cause; see ${loss.log}"
        System.err.println("The Paper ${server.name} is lost: $reason")
        val attempt = running(id)
        sendBack(attempt)
        if (attempt.started) {
            return attempt.session.send(
                playerEvent(attempt.players.first().name, PlayerEvent.Happened.PaperLostWrapper(loss)),
            )
        }
        attempt.session.send(Message.createLeaseFailed(submission = attempt.submission.id.value, loss = loss))
        finish(attempt.submission, failed(attempt.submit, 0, reason), "its Paper was lost")
    }

    /** [attempt]'s players go back to the shared Paper; each sits out until its client steps there again. */
    private fun sendBack(attempt: Attempt) {
        for (player in attempt.players) {
            val client = clientOf(player.uuid)?.takeIf { it.on == attempt.server } ?: continue
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

    /**
     * [server], an own Paper, ended for good: the pool forgets it, its folder goes, and a restart attempt
     * that waited for it to go is claimed.
     */
    private fun gone(server: Server) {
        papers.gone(server)
        claims.ownPaperGone()
        lend()
    }

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
        reclaim: Message.Reclaim,
    ) {
        val attempt = attemptOf(session, reclaim.submission) ?: return
        end(attempt, "its session claims its players again for its next body")
        attempt.submission.timing.since = System.currentTimeMillis()
        attempt.submission.state = Submission.State.Parked(attempt.players)
        unpark()
    }

    /** Claims again every parked submission whose players nothing holds out. */
    private fun unpark() {
        submissions.values
            .mapNotNull { submission -> (submission.state as? Submission.State.Parked)?.let { submission to it.players } }
            .filter { (_, players) -> players.none(claims::isOut) }
            .forEach { (submission, players) -> claim(submission, players) }
    }

    /**
     * The work [event] names hung: the attempt holding its player fails, and the player sits out of every
     * claim until the work ends, so none of it reaches a later attempt. Paper never cancels it.
     */
    private fun workHung(event: PlayerEvent) {
        val work = (event.happened as PlayerEvent.Happened.WorkHungWrapper).value.work
        val attempt = attempts.of(event.player)
        attempt?.session?.send(Message.PlayerEventWrapper(event))
        val player = clientNamed(event.player)?.player ?: return
        val held = hung.getOrPut(event.player) { HungWork(attempt?.submit?.testId.orEmpty()) }
        held.works += work
        claims.holdOut(player, Out.HUNG_WORK)
    }

    /** Work that hung ended; once none still runs, its player comes back, wiped by its next claim. */
    private fun hungEnded(message: Message.HungEnded) {
        val held = hung[message.player] ?: return
        held.works -= message.work
        if (held.works.isNotEmpty()) return
        hung -= message.player
        clientNamed(message.player)?.let { claims.letBack(it.player, Out.HUNG_WORK) }
        unpark()
        lend()
    }

    /** For each case whose hung work never ended, the player it keeps out of the pool. */
    private fun stillOut(): Map<String, String> =
        hung.entries
            .associate { (player, held) ->
                held.testId to
                    "$player stayed out of the pool for the rest of the run: its work ${held.works.joinToString { "\"$it\"" }} never ended."
            }

    /**
     * [attempt]'s lease ran out before its session sent the result, as a session stuck in its body or
     * its test JVM frozen: the attempt fails in its run's file, its players serve the next claims, and
     * the session hears so, which fails what its body waits for. Its result, should it still come, finds
     * no attempt.
     */
    private fun expire(attempt: Attempt) {
        val names = attempt.players.joinToString { it.name }
        val reason = "its lease ran out after $LEASE_SECONDS s while its session still held $names; see ${settings.poolLog}"
        System.err.println("Attempt ${attempt.id}: ${attempt.submit.testId} $reason")
        attempt.session.send(playerEvent(attempt.players.first().name, PlayerEvent.Happened.createLeaseExpired(reason = reason)))
        finish(attempt.submission, failed(attempt.submit, TimeUnit.SECONDS.toMillis(LEASE_SECONDS), reason), reason)
    }

    /**
     * [submission] ended with [result], for [why]: the one way a submission ends. Its run records it with
     * the pool's steps and what its attempts covered, and the players it holds serve the next claims.
     */
    private fun finish(
        submission: Submission,
        result: Result,
        why: String,
    ) {
        runs.record(
            submission.submit,
            result,
            submission.timing.steps + listOfNotNull(coverage.cost(submission)),
            coverage.latest(submission),
        )
        forget(submission, why)
    }

    /** [submission] is gone for [why], as when it finished or its session left: its coverage goes, and the players it holds serve the next claims. */
    private fun forget(
        submission: Submission,
        why: String,
    ) {
        coverage.forget(submission)
        submissions.remove(submission.key)
        when (val state = submission.state) {
            is Submission.State.Running -> {
                release(state.attempt, why)
            }

            is Submission.State.Parked -> {
                claims.release(state.players)
            }

            is Submission.State.Queued -> {}
        }
    }

    /** A failed result of [submit] the session never sent: [reason] after [durationMillis]. */
    private fun failed(
        submit: Submit,
        durationMillis: Long,
        reason: String,
    ) = Result(
        submission = submit.submission,
        durationMillis = durationMillis,
        failure = reason,
        firstBroken = null,
        steps = listOf(),
        folder = "",
        artifacts = listOf(),
    )

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
        attempt.server.peer?.send(Message.createRelease(attempt = attempt.id.value))
        attempts.end(attempt.id.value, why) { act(attempt.server, it) }
    }

    /** The attempt [id], which the rules of its Paper name only while it runs. */
    private fun running(id: Long): Attempt = checkNotNull(attempts[id]) { "attempt $id no longer runs" }

    /** A game part ended: a Paper's rules say what follows, a client's is lost and replaced, a display's ends the game. A replaced client's old part ends unheard. */
    private fun exited(part: Part) {
        papers.all.firstOrNull { it.part === part }?.let { return paperExited(it, part) }
        val reason = "${part.name} exited with code ${part.process.exitValue()}; see ${part.log}"
        if (part.player == null) return fail(reason)
        clientNamed(part.player)?.takeIf { it.part === part }?.let {
            lost(it, ClientLossKind.EXITED, "its process exited with code ${part.process.exitValue()}")
        }
    }

    /**
     * [client] crashed, froze until Paper timed its player out, or left, as [kind] says: its attempt fails
     * with [cause] and the lost client's log, Paper already holds back no tick for it, and the pool starts a new
     * client for the player. Until that one is ready, no claim gets the player. An attempt still being
     * claimed goes back in line.
     */
    private fun lost(
        client: Client,
        kind: ClientLossKind,
        cause: String,
    ) {
        if (client.lost || failure != null) return
        val name = client.player.name
        client.lost = true
        client.peer?.close()
        client.peer = null
        // The new client joins the shared Paper.
        moveTo(client, shared)
        claims.holdOut(client.player, Out.LOST_CLIENT)
        val replaced = game.replaceClient(name)
        client.part = replaced.replacement.also(::watch)
        val loss = ClientLoss(kind = kind, detail = cause, log = replaced.lostLog.toString())
        System.err.println("The client of $name is lost: $cause; see ${loss.log}. A new one starts.")
        attempts.of(name)?.let { attempt ->
            if (attempt.started) {
                attempt.session.send(playerEvent(name, PlayerEvent.Happened.ClientLostWrapper(loss)))
            } else {
                // Back in line on its own; the attempts beside it get their leases without it.
                end(attempt, "the client of $name was lost before its lease")
                claims.release(attempt.players)
                claims.submit(attempt.session, Claim(attempt.submit.submission, attempt.submit.players, attempt.submit.restartsPaper))
                attempt.submission.state = Submission.State.Queued(++nextTogether)
                attempt.submission.timing.since = System.currentTimeMillis()
                val rest = attempt.group - attempt
                rest.forEach { it.group = rest }
                lease(rest)
            }
        }
        lend()
    }

    private fun clientLost(
        player: String,
        kind: ClientLossKind,
        cause: String,
    ) {
        clientNamed(player)?.let { lost(it, kind, cause) }
    }

    /** [client] steps with the Paper it is on. */
    private fun ready(client: Client) {
        act(client.on, client.on.rules.ready(client.player.name))
    }

    /** Reports into the loop once [part]'s process ends. */
    private fun watch(part: Part) {
        thread(name = "playtest-pool-${part.name}", isDaemon = true) { part.process.waitFor().also { events.put(Event.Exited(part)) } }
    }

    private fun clientNamed(name: String): Client? = clients.firstOrNull { it.player.name == name }

    /** The attempt [session] runs for [submission], if it still runs. */
    private fun attemptOf(
        session: Peer,
        submission: Long,
    ): Attempt? = submissions[session to SubmissionId(submission)]?.running

    private fun clientOf(player: String): Client? = clients.firstOrNull { it.player.uuid == player }

    /** What happened to [player], as the message that tells the session holding it. */
    private fun playerEvent(
        player: String,
        happened: PlayerEvent.Happened,
    ): Message = Message.PlayerEventWrapper(PlayerEvent(player = player, happened = happened))

    /** The game cannot run: every session hears why, and the game stops. */
    private fun fail(reason: String) {
        if (failure != null) return
        couldNotRun(reason)
        lifetime.sessions.forEach { it.send(Message.createRefused(reason = reason)) }
        game.stop()
    }

    /** The game cannot serve the run, for [reason]: the pool's log and the run's file say why, also before the game started. */
    fun couldNotRun(reason: String) {
        failure = reason
        System.err.println("The game failed: $reason")
        runs.failed(reason)
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
        val hello = (Wire.read(input) as? Message.HelloWrapper)?.value ?: return socket.close()
        if (hello.role.kind == Role.Kind.UNKNOWN) return socket.close()
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

        /**
         * How long a leased attempt may hold its players before its session sends the result: well over
         * the longest attempt seen, a restart that trains its boot cache (47 s on a loaded Mac).
         */
        const val LEASE_SECONDS = 300L

        /** How long the test JVM that starts the pool has to open its session; it opens it as soon as the pool listens. */
        const val OWNER_SECONDS = 60L

        /** How long the pool waits after its run's last session left for another session of the run, as a module whose tests start later. */
        const val GRACE_SECONDS = 60L

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
