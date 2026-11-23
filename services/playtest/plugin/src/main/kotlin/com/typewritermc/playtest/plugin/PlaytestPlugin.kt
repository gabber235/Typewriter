package com.typewritermc.playtest.plugin

import com.destroystokyo.paper.event.server.ServerTickEndEvent
import com.destroystokyo.paper.event.server.ServerTickStartEvent
import com.typewritermc.playtest.agent.Step
import com.typewritermc.playtest.wire.Link
import com.typewritermc.playtest.wire.Payload
import com.typewritermc.playtest.wire.WireException
import com.typewritermc.playtest.wire.entries
import net.minecraft.commands.Commands
import net.minecraft.network.protocol.common.ClientboundPingPacket
import net.minecraft.server.MinecraftServer
import net.minecraft.server.level.ChunkTrackingView
import okio.ByteString.Companion.toByteString
import org.bukkit.Bukkit
import org.bukkit.Chunk
import org.bukkit.Location
import org.bukkit.World
import org.bukkit.craftbukkit.entity.CraftPlayer
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerJoinEvent
import org.bukkit.event.player.PlayerQuitEvent
import org.bukkit.plugin.java.JavaPlugin
import org.bukkit.util.Vector
import org.jacoco.agent.rt.RT
import skirout.harness.v1.wire.Answer
import skirout.harness.v1.wire.Ask
import skirout.harness.v1.wire.Hello
import skirout.harness.v1.wire.Message
import skirout.harness.v1.wire.PaperAsk
import skirout.harness.v1.wire.PlayerEvent
import skirout.harness.v1.wire.Probe
import skirout.harness.v1.wire.Region
import skirout.harness.v1.wire.Request
import skirout.harness.v1.wire.Role
import skirout.harness.v1.wire.StateKind
import java.io.IOException
import java.util.TreeSet
import java.util.UUID
import java.util.concurrent.ThreadPoolExecutor
import kotlin.math.min

/**
 * The framework's side of a Paper the game pool booted: the attempts sharing it, the step policy that
 * grants ticks, the step pings and barriers each client follows, and the probes. Every message from the
 * pool runs on the main thread between ticks.
 */
class PlaytestPlugin :
    JavaPlugin(),
    Listener {
    private val work: WorkLedger = PlayerWork.LEDGER
    private val policy =
        StepPolicy(
            Step::pending,
            Step::grant,
            ::sendBarrier,
            ::nothingLeftToSend,
            { task -> MinecraftServer.getServer().scheduleOnMain(task) },
            work,
            ::reportEnded,
            Acks(System::nanoTime),
            ::reportStalled,
            ::connected,
        )
    private val wipe = Wipe()
    private val owned = Owned(this)
    private val probes = Probes(this, ::mark)
    private val attempts = Attempts(this)
    private val ground = GroundAhead(this)
    private val chat = ChatWork()
    private val suggestions = SuggestionWork()

    /** Each online player's join: the last tick that ended before Paper took it in. Main thread. */
    private val joinedAfter = mutableMapOf<UUID, Int>()
    private val coverage =
        Coverage(
            { RT.getAgent().getExecutionData(true) },
            { read ->
                pool.send(Message.createCovered(attempts = read.attempts(), readNanos = read.nanos(), exec = read.exec().toByteString()))
            },
        )
    private lateinit var pool: Link

    override fun onEnable() {
        val missing = TreeSet(Step.REQUIRED)
        missing.removeAll(Step.applied)
        if (missing.isNotEmpty()) {
            logger.severe("The step agent did not prefix $missing; this Paper cannot be stepped. Stopping.")
            Bukkit.shutdown()
            return
        }
        val absent: Throwable? =
            try {
                RT.getAgent()
                null
            } catch (notStarted: IllegalStateException) {
                notStarted
            } catch (notLoaded: NoClassDefFoundError) {
                notLoaded
            }
        if (absent != null) {
            logger.severe("The JaCoCo agent is not running (${absent.message}), so no attempt's coverage can be read. Stopping.")
            Bukkit.shutdown()
            return
        }
        val port = Integer.getInteger("playtest.pool.port", -1)
        check(port >= 0) { "playtest.pool.port is not set: only the game pool runs this plugin" }
        Bukkit.getPluginManager().registerEvents(this, this)
        Bukkit.getPluginManager().registerEvents(probes, this)
        Bukkit.getPluginManager().registerEvents(attempts, this)
        Bukkit.getPluginManager().registerEvents(owned, this)
        Bukkit.getPluginManager().registerEvents(chat, this)
        Bukkit.getPluginManager().registerEvents(suggestions, this)
        Bukkit.getMessenger().registerIncomingPluginChannel(this, Payload.STEP_CHANNEL) { _, player, bytes ->
            val id = player.uniqueId
            val ack =
                try {
                    Payload.stepAck(bytes)
                } catch (broken: WireException) {
                    throw IllegalArgumentException("${player.name}'s client sent a step ack Paper cannot read", broken)
                }
            onMainThread { policy.acked(id, ack.tick, ack.busy) }
        }
        Step.policy = Runnable(policy::run)
        // The first tick runs once the server is done starting, so the pool hears from a Paper players can join.
        Bukkit.getScheduler().runTask(this, Runnable { connect(port) })
    }

    private fun connect(port: Int) {
        try {
            val name = System.getProperty("playtest.paper.name", "paper")
            pool = Link.open(port, Hello(role = Role.PAPER, name = name), { message -> onMainThread { receive(message) } }, ::poolLost)
            // Hung work is reported from its deadline's thread, so the report never waits for a long tick.
            work.reportHungTo(::reportHung)
        } catch (unreachable: IOException) {
            poolLost(unreachable)
        }
    }

    private fun receive(message: Message) {
        when (message) {
            Message.STEPPING -> {
                Step.on = true
            }

            is Message.ClaimWrapper -> {
                claim(message.value)
            }

            is Message.ResumeWrapper -> {
                resume(message.value)
            }

            is Message.ReleaseWrapper -> {
                val attempt = message.value.attempt
                coverage.ended(attempt)
                policy.release(attempts.release(attempt))
                ground.release(attempt)
            }

            is Message.RegionsAheadWrapper -> {
                ground.load(message.value.regions)
            }

            is Message.RequestWrapper -> {
                request(message.value)
            }

            is Message.SettleWrapper -> {
                val id = message.value.id
                policy.settle(attempts.players(id)) {
                    coverage.settled(id)
                    pool.send(Message.createSettled(id = id, covered = listOf()))
                }
            }

            is Message.StepUntilWrapper -> {
                policy.stepUntil(UUID.fromString(message.value.player), message.value.tick, message.value.barrier)
            }

            is Message.StopSteppingWrapper -> {
                policy.stop(UUID.fromString(message.value.player))
            }

            else -> {
                logger.severe("The game pool sent $message, which Paper never receives")
            }
        }
    }

    /** Answers a session's request to Paper: a probe, a query, or what the Typewriter engine applies. */
    private fun request(request: Request) {
        val id = request.id
        when (val ask = (request.ask as? Ask.PaperWrapper)?.value) {
            is PaperAsk.ProbeWrapper -> probe(id, ask.value)
            is PaperAsk.QueryWrapper -> pool.send(reply(id, marks(ask.value.player)))
            is PaperAsk.AppliedWrapper -> pool.send(reply(id, applied()))
            else -> logger.severe("The game pool sent $request, which Paper never answers")
        }
    }

    /** Runs the probe between ticks; it is done once its players' clients have what it caused, so the next stimulus finds it there. */
    private fun probe(
        request: Long,
        probe: Probe,
    ) {
        val ranAfter = policy.lastEnded()
        val ids = uuids(probe.players)
        val players = online(ids)
        val failure = players.failure ?: probes.run(players.online, probe.action)
        if (failure == null) {
            policy.deliver(ids) { pool.send(reply(request, Answer.createProbeDone(tick = ranAfter, failure = null))) }
        } else {
            pool.send(reply(request, Answer.createProbeDone(tick = ranAfter, failure = failure)))
        }
    }

    /**
     * Gives the attempt its players: their counted work holds back ticks from now on, they see only one
     * another, lose what earlier probes gave them alone, are wiped (Paper's state here, each plugin's own on the
     * [PlayerWipeEvent]), and stand at the middle of the attempt's region. The claim is done once
     * each of their clients holds all of it.
     */
    private fun claim(claim: Message.Claim) {
        val attempt = claim.attempt
        val ids = uuids(claim.players)
        val players = online(ids)
        if (players.failure != null) {
            pool.send(Message.createClaimed(attempt = attempt, failure = players.failure))
            return
        }
        // What plugins do for the attempt from here on, its players' wipe included, counts for it.
        coverage.started(attempt)
        attempts.claim(attempt, ids)
        ground.claim(attempt, claim.region)
        policy.claim(ids)
        probes.forget(players.online)
        for (player in players.online) {
            wipe.wipe(player)
            Bukkit.getPluginManager().callEvent(PlayerWipeEvent(player))
        }
        val middle = middle(players.online.first().world, claim.region)
        for (player in players.online) {
            player.velocity = Vector()
            player.fallDistance = 0f
            player.teleport(middle)
        }
        policy.deliver(ids) { pool.send(Message.createClaimed(attempt = attempt, failure = null)) }
    }

    /**
     * Gives the attempt its players again after this Paper was killed and booted under it, or after an
     * away player of it joined again: as a claim does, but without the wipe or the move, so they keep what
     * Paper loaded for them. Resumed once each of their clients holds all Paper sends them.
     */
    private fun resume(resume: Message.Resume) {
        val ranAfter = policy.lastEnded()
        val attempt = resume.attempt
        val ids = uuids(resume.players)
        val players = online(ids)
        if (players.failure != null) {
            pool.send(Message.createResumed(attempt = attempt, tick = ranAfter, failure = players.failure, joinedAfter = ranAfter))
            return
        }
        coverage.started(attempt)
        attempts.claim(attempt, ids)
        policy.claim(ids)
        val joined = ids.maxOf { joinedAfter[it] ?: ranAfter }
        policy.deliver(ids) { pool.send(Message.createResumed(attempt = attempt, tick = ranAfter, failure = null, joinedAfter = joined)) }
    }

    /** Leaves a mark of [kind] on the player: Paper keeps some kinds, this plugin the others. */
    private fun mark(
        player: Player,
        kind: StateKind,
    ) {
        if (kind in Wipe.KINDS) wipe.mark(player, kind) else owned.mark(player, kind)
    }

    /** Answers which kinds the queried player carries a mark of. */
    private fun marks(queried: String): Answer {
        val player =
            Bukkit.getPlayer(UUID.fromString(queried))
                ?: return Answer.createMarks(marked = listOf(), failure = "the player $queried is not online")
        val marked = StateKind.entries.filter { kind -> if (kind in Wipe.KINDS) wipe.marked(player, kind) else owned.marked(player, kind) }
        return Answer.createMarks(marked = marked, failure = null)
    }

    /**
     * Answers which publication the Typewriter engine on this Paper applies, as its [AppliedContent] reports it.
     *
     * TODO(node 9): temporary test only signal; replace with the engine's reported active publication ("applied on N of M").
     */
    private fun applied(): Answer {
        val reporter =
            Bukkit.getServicesManager().load(AppliedContent::class.java)
                ?: return Answer.createApplied(
                    publication = null,
                    failure = "no Typewriter engine on this Paper reports what it applies: is the playtest bridge deployed to it?",
                )
        return Answer.createApplied(publication = reporter.publication(), failure = null)
    }

    /** A player joined: what its join causes from now on shows from the tick after the last one that ended. */
    @EventHandler(priority = EventPriority.LOWEST)
    fun onJoin(event: PlayerJoinEvent) {
        joinedAfter[event.player.uniqueId] = policy.lastEnded()
    }

    /**
     * A player left: its client crashed, froze until Paper timed it out, or its attempt sent it away as a
     * person quits. It holds back no tick from now on; the pool, which knows which, replaces a lost client.
     */
    @EventHandler
    fun onQuit(event: PlayerQuitEvent) {
        val player = event.player
        joinedAfter.remove(player.uniqueId)
        policy.lose(player.uniqueId)
        if (::pool.isInitialized) {
            pool.send(Message.createPlayerLeft(player = player.name, reason = event.reason.name, tick = policy.lastEnded()))
        }
    }

    @EventHandler
    fun onTickStart(event: ServerTickStartEvent) {
        work.tickStarted(event.tickNumber)
    }

    @EventHandler
    fun onTickEnd(event: ServerTickEndEvent) {
        work.tickEnded(event.tickNumber)
        policy.tickEnded(event.tickNumber)
        if (!Step.on) return
        val ping = ClientboundPingPacket(StepPolicy.STEP_BASE + event.tickNumber)
        for (player in Bukkit.getOnlinePlayers()) (player as CraftPlayer).handle.connection.send(ping)
    }

    /** The player's attempt fails with the hung work; Paper never cancels it. */
    private fun reportHung(hung: WorkLedger.Hung) {
        logger.warning(
            "${hung.playerName()}'s work \"${hung.name()}\" began after tick ${hung.beganAfter()} and still runs after 1 s; it holds no more ticks.",
        )
        val happened = PlayerEvent.Happened.createWorkHung(work = hung.name(), beganAfter = hung.beganAfter())
        pool.send(Message.PlayerEventWrapper(PlayerEvent(player = hung.playerName(), happened = happened)))
    }

    /** Work reported hung ended; the pool lets its player back. */
    private fun reportEnded(hung: WorkLedger.Hung) {
        logger.info("${hung.playerName()}'s hung work \"${hung.name()}\" ended.")
        pool.send(Message.createHungEnded(player = hung.playerName(), work = hung.name()))
    }

    /** The client acked nothing for 5 s while behind; it holds back no tick and the pool replaces it. */
    private fun reportStalled(stalled: Acks.Stalled) {
        val player = Bukkit.getPlayer(stalled.player()) ?: return
        logger.warning("${player.name}'s client acked no tick for 5 s after tick ${stalled.lastAcked()}; it holds no more ticks.")
        pool.send(Message.createClientStalled(player = player.name, lastAcked = stalled.lastAcked()))
    }

    private fun sendBarrier(
        id: UUID,
        barrier: Int,
    ) {
        val player = Bukkit.getPlayer(id)
        if (player != null) (player as CraftPlayer).handle.connection.send(ClientboundPingPacket(barrier))
    }

    /**
     * The pool is gone, so this Paper serves nobody. It halts instead of stopping: a stepped main loop
     * that stops stepping first waits out the wall time its stepped ticks ran ahead.
     */
    private fun poolLost(cause: IOException) {
        logger.severe("Lost the game pool (${cause.message}); halting.")
        Runtime.getRuntime().halt(1)
    }
}

private fun reply(
    request: Long,
    answer: Answer,
): Message = Message.createReply(request = request, answer = answer)

/** Where a claim puts the attempt's players: on the ground at the middle of the region. */
private fun middle(
    world: World,
    region: Region,
): Location = Location(world, region.x + 0.5, (world.getHighestBlockYAt(region.x, region.z) + 1).toDouble(), region.z + 0.5)

/** The players the wire names by their UUID's text. */
private fun uuids(ids: List<String>): List<UUID> = ids.map(UUID::fromString)

private data class Online(
    val online: List<Player>,
    val failure: String?,
)

private fun online(ids: List<UUID>): Online {
    val online = ArrayList<Player>(ids.size)
    for (id in ids) {
        val player = Bukkit.getPlayer(id) ?: return Online(listOf(), "the player $id is not online")
        online.add(player)
    }
    return Online(online.toList(), null)
}

/**
 * Whether Paper has sent the player everything the client shows: every chunk the client draws, the
 * ring of neighbours it needs before it meshes them, and the command tree, which Paper builds on a pool
 * of its own and sends from a task that pool queues on the main thread once done. The client draws as
 * far as the lower of its own render distance and the radius Paper sends it; Paper may send chunks
 * further out, nearest first, which the client never draws.
 */
private fun nothingLeftToSend(id: UUID): Boolean {
    val player = Bukkit.getPlayer(id) ?: return true
    val commands = Commands.COMMAND_SENDING_POOL as ThreadPoolExecutor
    if (commands.activeCount > 0 || !commands.queue.isEmpty()) return false
    // The client's effective render distance: Options.getEffectiveRenderDistance caps its own by the radius Paper sends.
    val radius = min(player.sendViewDistance, player.clientViewDistance)
    val centerX = player.location.blockX shr 4
    val centerZ = player.location.blockZ shr 4
    // With neighbours, the view holds every chunk the client draws and the 8 around each, which it needs to mesh one.
    for (x in centerX - radius - 1..centerX + radius + 1) {
        for (z in centerZ - radius - 1..centerZ + radius + 1) {
            if (ChunkTrackingView.isWithinDistance(centerX, centerZ, radius, x, z, true) &&
                !player.isChunkSent(Chunk.getChunkKey(x, z))
            ) {
                return false
            }
        }
    }
    return true
}

/** Whether the player's client is still connected; Paper notices a closed connection only in its next tick. */
private fun connected(id: UUID): Boolean {
    val player = Bukkit.getPlayer(id) ?: return false
    return (player as CraftPlayer)
        .handle.connection.connection.isConnected
}

private fun onMainThread(task: () -> Unit) {
    if (Bukkit.isPrimaryThread()) task() else MinecraftServer.getServer().execute(task)
}
