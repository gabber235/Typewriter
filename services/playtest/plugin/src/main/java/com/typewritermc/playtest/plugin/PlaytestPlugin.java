package com.typewritermc.playtest.plugin;

import com.destroystokyo.paper.event.server.ServerTickEndEvent;
import com.destroystokyo.paper.event.server.ServerTickStartEvent;
import com.typewritermc.playtest.agent.Step;
import build.skir.internal.MustNameArguments;
import com.typewritermc.playtest.wire.Link;
import com.typewritermc.playtest.wire.Payload;
import com.typewritermc.playtest.wire.SkirEnums;
import com.typewritermc.playtest.wire.WireException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.TreeSet;
import java.util.UUID;
import java.util.concurrent.ThreadPoolExecutor;
import okio.ByteString;
import skirout.harness.v1.wire.Answer;
import skirout.harness.v1.wire.Ask;
import skirout.harness.v1.wire.Hello;
import skirout.harness.v1.wire.Message;
import skirout.harness.v1.wire.PaperAsk;
import skirout.harness.v1.wire.PlayerEvent;
import skirout.harness.v1.wire.Probe;
import skirout.harness.v1.wire.Region;
import skirout.harness.v1.wire.Reply;
import skirout.harness.v1.wire.Request;
import skirout.harness.v1.wire.Role;
import skirout.harness.v1.wire.StateKind;
import skirout.harness.v1.wire.StepAck;
import net.minecraft.commands.Commands;
import net.minecraft.network.protocol.common.ClientboundPingPacket;
import net.minecraft.server.MinecraftServer;
import net.minecraft.server.level.ChunkTrackingView;
import org.bukkit.Bukkit;
import org.bukkit.Chunk;
import org.bukkit.Location;
import org.bukkit.World;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerQuitEvent;
import org.bukkit.plugin.java.JavaPlugin;
import org.bukkit.util.Vector;
import org.jacoco.agent.rt.RT;

/**
 * The framework's side of a Paper the game pool booted: the attempts sharing it, the step policy that
 * grants ticks, the step pings and barriers each client follows, and the probes. Every message from the
 * pool runs on the main thread between ticks.
 */
public final class PlaytestPlugin extends JavaPlugin implements Listener {
    private final WorkLedger work = PlayerWork.LEDGER;
    private final StepPolicy policy = new StepPolicy(
            Step::pending,
            Step::grant,
            this::sendBarrier,
            PlaytestPlugin::nothingLeftToSend,
            task -> MinecraftServer.getServer().scheduleOnMain(task),
            work,
            this::reportEnded,
            new Acks(System::nanoTime),
            this::reportStalled);
    private final Wipe wipe = new Wipe();
    private final Owned owned = new Owned(this);
    private final Probes probes = new Probes(this, this::mark);
    private final Attempts attempts = new Attempts(this);
    private final GroundAhead ground = new GroundAhead(this);
    private final ChatWork chat = new ChatWork();
    private final SuggestionWork suggestions = new SuggestionWork();
    private final Coverage coverage = new Coverage(
            () -> RT.getAgent().getExecutionData(true), read -> this.pool.send(Message.Companion.createCovered(MustNameArguments.INSTANCE, read.attempts(), read.nanos(), ByteString.of(read.exec()))));
    private Link pool;

    @Override
    public void onEnable() {
        var missing = new TreeSet<>(Step.REQUIRED);
        missing.removeAll(Step.applied);
        if (!missing.isEmpty()) {
            getLogger().severe("The step agent did not prefix " + missing + "; this Paper cannot be stepped. Stopping.");
            Bukkit.shutdown();
            return;
        }
        try {
            RT.getAgent();
        } catch (IllegalStateException | NoClassDefFoundError absent) {
            getLogger().severe("The JaCoCo agent is not running (" + absent.getMessage() + "), so no attempt's coverage can be read. Stopping.");
            Bukkit.shutdown();
            return;
        }
        int port = Integer.getInteger("playtest.pool.port", -1);
        if (port < 0) throw new IllegalStateException("playtest.pool.port is not set: only the game pool runs this plugin");
        Bukkit.getPluginManager().registerEvents(this, this);
        Bukkit.getPluginManager().registerEvents(probes, this);
        Bukkit.getPluginManager().registerEvents(attempts, this);
        Bukkit.getPluginManager().registerEvents(owned, this);
        Bukkit.getPluginManager().registerEvents(chat, this);
        Bukkit.getPluginManager().registerEvents(suggestions, this);
        Bukkit.getMessenger().registerIncomingPluginChannel(this, Payload.STEP_CHANNEL, (channel, player, bytes) -> {
            UUID id = player.getUniqueId();
            StepAck ack;
            try {
                ack = Payload.stepAck(bytes);
            } catch (WireException broken) {
                throw new IllegalArgumentException(player.getName() + "'s client sent a step ack Paper cannot read", broken);
            }
            onMainThread(() -> policy.acked(id, ack.getTick(), ack.getBusy()));
        });
        Step.policy = policy::run;
        // The first tick runs once the server is done starting, so the pool hears from a Paper players can join.
        Bukkit.getScheduler().runTask(this, () -> connect(port));
    }

    private void connect(int port) {
        try {
            String name = System.getProperty("playtest.paper.name", "paper");
            pool = Link.open(port, new Hello(MustNameArguments.INSTANCE, Role.PAPER.INSTANCE, name, null), message -> onMainThread(() -> receive(message)), this::poolLost);
            // Hung work is reported from its deadline's thread, so the report never waits for a long tick.
            work.reportHungTo(this::reportHung);
        } catch (IOException unreachable) {
            poolLost(unreachable);
        }
    }

    private void receive(Message message) {
        switch (message) {
            case Message.STEPPING stepping -> Step.on = true;
            case Message.ClaimWrapper claim -> claim(claim.getValue());
            case Message.ResumeWrapper resume -> resume(resume.getValue());
            case Message.ReleaseWrapper release -> {
                long attempt = release.getValue().getAttempt();
                coverage.ended(attempt);
                policy.release(attempts.release(attempt));
                ground.release(attempt);
            }
            case Message.RegionsAheadWrapper ahead -> ground.load(ahead.getValue().getRegions());
            case Message.RequestWrapper request -> request(request.getValue());
            case Message.SettleWrapper settle -> {
                long id = settle.getValue().getId();
                policy.settle(attempts.players(id), () -> {
                    coverage.settled(id);
                    pool.send(Message.Companion.createSettled(MustNameArguments.INSTANCE, id, List.of()));
                });
            }
            case Message.StepUntilWrapper step ->
                    policy.stepUntil(UUID.fromString(step.getValue().getPlayer()), step.getValue().getTick(), step.getValue().getBarrier());
            case Message.StopSteppingWrapper stop -> policy.stop(UUID.fromString(stop.getValue().getPlayer()));
            default -> getLogger().severe("The game pool sent " + message + ", which Paper never receives");
        }
    }

    /** Answers a session's request to Paper: a probe or a query. */
    private void request(Request request) {
        long id = request.getId();
        PaperAsk ask = request.getAsk() instanceof Ask.PaperWrapper paper ? paper.getValue() : null;
        switch (ask) {
            case PaperAsk.ProbeWrapper probe -> probe(id, probe.getValue());
            case PaperAsk.QueryWrapper query -> pool.send(reply(id, marks(query.getValue().getPlayer())));
            case null, default -> getLogger().severe("The game pool sent " + request + ", which Paper never answers");
        }
    }

    /** Runs the probe between ticks; it is done once its players' clients have what it caused, so the next stimulus finds it there. */
    private void probe(long request, Probe probe) {
        int ranAfter = policy.lastEnded();
        List<UUID> ids = uuids(probe.getPlayers());
        var players = online(ids);
        String failure = players.failure() != null ? players.failure() : probes.run(players.online(), probe.getAction());
        if (failure == null) {
            policy.deliver(ids, () -> pool.send(reply(request, Answer.Companion.createProbeDone(MustNameArguments.INSTANCE, ranAfter, null))));
        } else {
            pool.send(reply(request, Answer.Companion.createProbeDone(MustNameArguments.INSTANCE, ranAfter, failure)));
        }
    }

    private static Message reply(long request, Answer answer) {
        return new Message.ReplyWrapper(new Reply(MustNameArguments.INSTANCE, request, answer, null));
    }

    /**
     * Gives the attempt its players: their counted work holds back ticks from now on, they see only one
     * another, lose what earlier probes gave them alone, are wiped (Paper's state here, each plugin's own on the
     * {@link PlayerWipeEvent}), and stand at the middle of the attempt's region. The claim is done once
     * each of their clients holds all of it.
     */
    private void claim(Message.Claim claim) {
        long attempt = claim.getAttempt();
        List<UUID> ids = uuids(claim.getPlayers());
        var players = online(ids);
        if (players.failure() != null) {
            pool.send(Message.Companion.createClaimed(MustNameArguments.INSTANCE, attempt, players.failure()));
            return;
        }
        // What plugins do for the attempt from here on, its players' wipe included, counts for it.
        coverage.started(attempt);
        attempts.claim(attempt, ids);
        ground.claim(attempt, claim.getRegion());
        policy.claim(ids);
        probes.forget(players.online());
        for (Player player : players.online()) {
            wipe.wipe(player);
            Bukkit.getPluginManager().callEvent(new PlayerWipeEvent(player));
        }
        Location middle = middle(players.online().getFirst().getWorld(), claim.getRegion());
        for (Player player : players.online()) {
            player.setVelocity(new Vector());
            player.setFallDistance(0);
            player.teleport(middle);
        }
        policy.deliver(ids, () -> pool.send(Message.Companion.createClaimed(MustNameArguments.INSTANCE, attempt, null)));
    }

    /**
     * Gives the attempt its players again after this Paper was killed and booted under it: as a claim
     * does, but without the wipe or the move, so they keep what Paper loaded for them. Resumed once each
     * of their clients holds all Paper sends them.
     */
    private void resume(Message.Resume resume) {
        int ranAfter = policy.lastEnded();
        long attempt = resume.getAttempt();
        List<UUID> ids = uuids(resume.getPlayers());
        var players = online(ids);
        if (players.failure() != null) {
            pool.send(Message.Companion.createResumed(MustNameArguments.INSTANCE, attempt, ranAfter, players.failure()));
            return;
        }
        coverage.started(attempt);
        attempts.claim(attempt, ids);
        policy.claim(ids);
        policy.deliver(ids, () -> pool.send(Message.Companion.createResumed(MustNameArguments.INSTANCE, attempt, ranAfter, null)));
    }

    /** Leaves a mark of [kind] on the player: Paper keeps some kinds, this plugin the others. */
    private void mark(Player player, StateKind kind) {
        if (Wipe.KINDS.contains(kind)) wipe.mark(player, kind);
        else owned.mark(player, kind);
    }

    /** Answers which kinds the queried player carries a mark of. */
    private Answer marks(String queried) {
        Player player = Bukkit.getPlayer(UUID.fromString(queried));
        if (player == null) return Answer.Companion.createMarks(MustNameArguments.INSTANCE, List.of(), "the player " + queried + " is not online");
        var marked = new ArrayList<StateKind>();
        for (StateKind kind : SkirEnums.constantsOf(StateKind.Companion.getTypeDescriptor())) {
            if (Wipe.KINDS.contains(kind) ? wipe.marked(player, kind) : owned.marked(player, kind)) marked.add(kind);
        }
        return Answer.Companion.createMarks(MustNameArguments.INSTANCE, marked, null);
    }


    /** Where a claim puts the attempt's players: on the ground at the middle of the region. */
    private static Location middle(World world, Region region) {
        return new Location(world, region.getX() + 0.5, world.getHighestBlockYAt(region.getX(), region.getZ()) + 1, region.getZ() + 0.5);
    }

    /** The players the wire names by their UUID's text. */
    private static List<UUID> uuids(List<String> ids) {
        return ids.stream().map(UUID::fromString).toList();
    }

    private record Online(List<Player> online, String failure) {}

    private static Online online(List<UUID> ids) {
        var online = new ArrayList<Player>(ids.size());
        for (UUID id : ids) {
            Player player = Bukkit.getPlayer(id);
            if (player == null) return new Online(List.of(), "the player " + id + " is not online");
            online.add(player);
        }
        return new Online(List.copyOf(online), null);
    }

    /**
     * A player left: its client crashed, froze until Paper timed it out, or quit. It holds back no tick
     * from now on, and the pool replaces its client.
     */
    @EventHandler
    public void onQuit(PlayerQuitEvent event) {
        Player player = event.getPlayer();
        policy.lose(player.getUniqueId());
        if (pool != null) pool.send(Message.Companion.createPlayerLeft(MustNameArguments.INSTANCE, player.getName(), event.getReason().name()));
    }

    @EventHandler
    public void onTickStart(ServerTickStartEvent event) {
        work.tickStarted(event.getTickNumber());
    }

    @EventHandler
    public void onTickEnd(ServerTickEndEvent event) {
        work.tickEnded(event.getTickNumber());
        policy.tickEnded(event.getTickNumber());
        if (!Step.on) return;
        var ping = new ClientboundPingPacket(StepPolicy.STEP_BASE + event.getTickNumber());
        for (Player player : Bukkit.getOnlinePlayers()) ((CraftPlayer) player).getHandle().connection.send(ping);
    }

    /** The player's attempt fails with the hung work; Paper never cancels it. */
    private void reportHung(WorkLedger.Hung hung) {
        getLogger().warning(hung.playerName() + "'s work \"" + hung.name() + "\" began after tick " + hung.beganAfter() + " and still runs after 1 s; it holds no more ticks.");
        var happened = PlayerEvent.Happened.Companion.createWorkHung(MustNameArguments.INSTANCE, hung.name(), hung.beganAfter());
        pool.send(new Message.PlayerEventWrapper(new PlayerEvent(MustNameArguments.INSTANCE, hung.playerName(), happened, null)));
    }

    /** Work reported hung ended; the pool lets its player back. */
    private void reportEnded(WorkLedger.Hung hung) {
        getLogger().info(hung.playerName() + "'s hung work \"" + hung.name() + "\" ended.");
        pool.send(Message.Companion.createHungEnded(MustNameArguments.INSTANCE, hung.playerName(), hung.name()));
    }

    /** The client acked nothing for 5 s while behind; it holds back no tick and the pool replaces it. */
    private void reportStalled(Acks.Stalled stalled) {
        Player player = Bukkit.getPlayer(stalled.player());
        if (player == null) return;
        getLogger().warning(player.getName() + "'s client acked no tick for 5 s after tick " + stalled.lastAcked() + "; it holds no more ticks.");
        pool.send(Message.Companion.createClientStalled(MustNameArguments.INSTANCE, player.getName(), stalled.lastAcked()));
    }

    private void sendBarrier(UUID id, int barrier) {
        Player player = Bukkit.getPlayer(id);
        if (player != null) ((CraftPlayer) player).getHandle().connection.send(new ClientboundPingPacket(barrier));
    }

    /**
     * Whether Paper has sent the player everything the client shows: every chunk the client draws, the
     * ring of neighbours it needs before it meshes them, and the command tree, which Paper builds on a pool
     * of its own and sends from a task that pool queues on the main thread once done. The client draws as
     * far as the lower of its own render distance and the radius Paper sends it; Paper may send chunks
     * further out, nearest first, which the client never draws.
     */
    private static boolean nothingLeftToSend(UUID id) {
        Player player = Bukkit.getPlayer(id);
        if (player == null) return true;
        var commands = (ThreadPoolExecutor) Commands.COMMAND_SENDING_POOL;
        if (commands.getActiveCount() > 0 || !commands.getQueue().isEmpty()) return false;
        // The client's effective render distance: Options.getEffectiveRenderDistance caps its own by the radius Paper sends.
        int radius = Math.min(player.getSendViewDistance(), player.getClientViewDistance());
        int centerX = player.getLocation().getBlockX() >> 4;
        int centerZ = player.getLocation().getBlockZ() >> 4;
        // With neighbours, the view holds every chunk the client draws and the 8 around each, which it needs to mesh one.
        for (int x = centerX - radius - 1; x <= centerX + radius + 1; x++) {
            for (int z = centerZ - radius - 1; z <= centerZ + radius + 1; z++) {
                if (ChunkTrackingView.isWithinDistance(centerX, centerZ, radius, x, z, true) && !player.isChunkSent(Chunk.getChunkKey(x, z))) return false;
            }
        }
        return true;
    }

    /**
     * The pool is gone, so this Paper serves nobody. It halts instead of stopping: a stepped main loop
     * that stops stepping first waits out the wall time its stepped ticks ran ahead.
     */
    private void poolLost(IOException cause) {
        getLogger().severe("Lost the game pool (" + cause.getMessage() + "); halting.");
        Runtime.getRuntime().halt(1);
    }

    private static void onMainThread(Runnable task) {
        if (Bukkit.isPrimaryThread()) task.run();
        else MinecraftServer.getServer().execute(task);
    }
}
