package com.typewritermc.playtest.pool

import com.typewritermc.playtest.wire.Message
import com.typewritermc.playtest.wire.Message.BarrierSeen
import com.typewritermc.playtest.wire.Message.Connect
import com.typewritermc.playtest.wire.Message.End
import com.typewritermc.playtest.wire.Message.Ended
import com.typewritermc.playtest.wire.Message.Hello
import com.typewritermc.playtest.wire.Message.Joined
import com.typewritermc.playtest.wire.Message.Lease
import com.typewritermc.playtest.wire.Message.Perceived
import com.typewritermc.playtest.wire.Message.Player
import com.typewritermc.playtest.wire.Message.ProbeChat
import com.typewritermc.playtest.wire.Message.ProbeDone
import com.typewritermc.playtest.wire.Message.Ready
import com.typewritermc.playtest.wire.Message.Refused
import com.typewritermc.playtest.wire.Message.Reset
import com.typewritermc.playtest.wire.Message.ResetDone
import com.typewritermc.playtest.wire.Message.Result
import com.typewritermc.playtest.wire.Message.Role
import com.typewritermc.playtest.wire.Message.StepUntil
import com.typewritermc.playtest.wire.Message.Stepping
import com.typewritermc.playtest.wire.Message.StopStepping
import com.typewritermc.playtest.wire.Message.Submit
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
 * touches the pool's state. It boots the game, leases the player to one submitted attempt at a time,
 * routes each attempt's messages, and stops once the last session left.
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

    private class Leased(
        val session: Peer,
        val submit: Submit,
    ) {
        var started = false

        /** The client's fresh record after its reset, held until the session has its lease. */
        var fresh: Perceived? = null
    }

    private class Routed<T>(
        val session: Peer,
        val id: T,
    )

    private val events = LinkedBlockingQueue<Event>()
    private val player = Player(PLAYER, UUID.nameUUIDFromBytes("OfflinePlayer:$PLAYER".toByteArray()))
    private val runs = RunRecords()
    private val sessions = mutableSetOf<Peer>()
    private val waiting = ArrayDeque<Pair<Peer, Submit>>()
    private val probes = mutableMapOf<Long, Routed<Long>>()
    private val barriers = mutableMapOf<Int, Routed<Int>>()
    private lateinit var game: Game
    private var paper: Peer? = null
    private var client: Peer? = null
    private var connected = false
    private var ready = false
    private var failure: String? = null
    private var lease: Leased? = null
    private var sawSession = false
    private var nextProbe = 0L
    private var nextBarrier = 0

    fun run() {
        thread(name = "playtest-pool-accept", isDaemon = true) { accept() }
        game = Game.start(settings, server.localPort, PLAYER)
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
                if (failure ==
                    null
                ) {
                    fail("${event.part.name} exited with code ${event.part.process.exitValue()}; see ${event.part.log}")
                }
            }

            Event.BootTimedOut -> {
                if (!ready) fail("the game was not ready within $BOOT_SECONDS s; see ${game.parts.joinToString { it.log.toString() }}")
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
            }

            Role.CLIENT -> {
                client = peer
            }
        }
        val paper = paper
        val client = client
        if (!connected && paper != null && client != null) {
            connected = true
            client.send(Connect("127.0.0.1", game.paperPort))
        }
    }

    private fun received(
        peer: Peer,
        message: Message,
    ) {
        when (peer.role) {
            Role.SESSION -> fromSession(peer, message)
            Role.PAPER -> fromPaper(message)
            Role.CLIENT -> fromClient(message)
        }
    }

    private fun fromSession(
        session: Peer,
        message: Message,
    ) {
        when (message) {
            is Submit -> {
                waiting += session to message
                lend()
            }

            is End -> {
                runs.write(message.run(), Path.of(message.testRunFile()))
                session.send(Ended())
            }

            is Result -> {
                val leased = lease?.takeIf { it.session == session && it.submit.submission() == message.submission() } ?: return
                runs.record(session.hello.name(), leased.submit, message)
                release()
            }

            is ProbeChat -> {
                forPaper(session) {
                    ProbeChat(++nextProbe, player.uuid(), message.text()).also {
                        probes[it.request()] =
                            Routed(session, message.request())
                    }
                }
            }

            is StepUntil -> {
                forPaper(session) {
                    StepUntil(player.uuid(), message.tick(), ++nextBarrier).also {
                        barriers[it.barrier()] =
                            Routed(session, message.barrier())
                    }
                }
            }

            is StopStepping -> {
                forPaper(session) { StopStepping(player.uuid()) }
            }

            else -> {
                System.err.println("$session sent ${message.javaClass.simpleName}, which a session never sends")
            }
        }
    }

    /** Hands a session's stimulus or step to Paper, but only while the session holds the lease. */
    private fun forPaper(
        session: Peer,
        message: () -> Message,
    ) {
        if (lease?.session != session) return
        paper?.send(message())
    }

    private fun fromPaper(message: Message) {
        when (message) {
            is ProbeDone -> probes.remove(message.request())?.let { it.session.send(ProbeDone(it.id, message.tick())) }
            else -> System.err.println("Paper sent ${message.javaClass.simpleName}, which Paper never sends")
        }
    }

    private fun fromClient(message: Message) {
        when (message) {
            is Joined -> {
                paper?.send(Stepping())
            }

            is Ready -> {
                ready = true
                lend()
            }

            is ResetDone -> {
                lease?.let(::start)
            }

            is Perceived -> {
                lease?.let { perceived(it, message) }
            }

            is BarrierSeen -> {
                lease?.let { barrierSeen(it, message) }
            }

            else -> {
                System.err.println("The client sent ${message.javaClass.simpleName}, which the client never sends")
            }
        }
    }

    /** The client reset for [leased]: its session gets the lease and the client's fresh record. */
    private fun start(leased: Leased) {
        if (leased.started) return
        leased.started = true
        leased.session.send(Lease(leased.submit.submission(), listOf(player)))
        leased.fresh?.let(leased.session::send)
    }

    private fun perceived(
        leased: Leased,
        message: Perceived,
    ) {
        if (leased.started) leased.session.send(message) else leased.fresh = message
    }

    /** Hands a barrier back under the session's own id, unless it belongs to an attempt that already ended. */
    private fun barrierSeen(
        leased: Leased,
        message: BarrierSeen,
    ) {
        val routed = barriers.remove(message.barrier()) ?: return
        if (routed.session == leased.session) routed.session.send(BarrierSeen(message.player(), routed.id))
    }

    private fun left(peer: Peer) {
        when (peer.role) {
            Role.SESSION -> {
                sessions -= peer
                waiting.removeAll { it.first == peer }
                if (lease?.session == peer) release()
            }

            Role.PAPER, Role.CLIENT -> {
                if (failure ==
                    null
                ) {
                    fail("$peer closed its pool connection; see ${game.parts.joinToString { it.log.toString() }}")
                }
            }
        }
    }

    /** Starts the next waiting attempt once the player is free: the client resets, then the session gets the lease. */
    private fun lend() {
        if (failure != null || !ready || lease != null) return
        val (session, submit) = waiting.removeFirstOrNull() ?: return
        lease = Leased(session, submit)
        client?.send(Reset())
    }

    private fun release() {
        lease = null
        paper?.send(StopStepping(player.uuid()))
        lend()
    }

    /** The game cannot run: every session hears why, and the game stops. */
    private fun fail(reason: String) {
        failure = reason
        System.err.println("The game failed: $reason")
        sessions.forEach { it.send(Refused(reason)) }
        waiting.clear()
        lease = null
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
        const val PLAYER = "gv-1"
        const val BOOT_SECONDS = 300L
    }
}
