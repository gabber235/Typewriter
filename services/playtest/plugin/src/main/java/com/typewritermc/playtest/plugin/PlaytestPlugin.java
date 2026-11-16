package com.typewritermc.playtest.plugin;

import com.destroystokyo.paper.event.server.ServerTickEndEvent;
import com.destroystokyo.paper.event.server.ServerTickStartEvent;
import com.typewritermc.playtest.agent.Step;
import com.typewritermc.playtest.wire.Link;
import com.typewritermc.playtest.wire.Message;
import com.typewritermc.playtest.wire.Message.Claim;
import com.typewritermc.playtest.wire.Message.Claimed;
import com.typewritermc.playtest.wire.Message.ClientStalled;
import com.typewritermc.playtest.wire.Message.Covered;
import com.typewritermc.playtest.wire.Message.Hello;
import com.typewritermc.playtest.wire.Message.HungEnded;
import com.typewritermc.playtest.wire.Message.Kind;
import com.typewritermc.playtest.wire.Message.Marks;
import com.typewritermc.playtest.wire.Message.PlayerLeft;
import com.typewritermc.playtest.wire.Message.Probe;
import com.typewritermc.playtest.wire.Message.ProbeDone;
import com.typewritermc.playtest.wire.Message.Query;
import com.typewritermc.playtest.wire.Message.Region;
import com.typewritermc.playtest.wire.Message.RegionsAhead;
import com.typewritermc.playtest.wire.Message.Release;
import com.typewritermc.playtest.wire.Message.Resume;
import com.typewritermc.playtest.wire.Message.Resumed;
import com.typewritermc.playtest.wire.Message.Role;
import com.typewritermc.playtest.wire.Message.Settle;
import com.typewritermc.playtest.wire.Message.Settled;
import com.typewritermc.playtest.wire.Message.StepUntil;
import com.typewritermc.playtest.wire.Message.Stepping;
import com.typewritermc.playtest.wire.Message.StopStepping;
import com.typewritermc.playtest.wire.Message.WorkHung;
import com.typewritermc.playtest.wire.Payload.StepAck;
import com.typewritermc.playtest.wire.WireException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.List;
import java.util.TreeSet;
import java.util.UUID;
import java.util.concurrent.ThreadPoolExecutor;
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
            this::reportHung,
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
            () -> RT.getAgent().getExecutionData(true), read -> this.pool.send(new Covered(read.attempts(), read.nanos(), read.exec())));
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
        Bukkit.getMessenger().registerIncomingPluginChannel(this, StepAck.CHANNEL, (channel, player, bytes) -> {
            UUID id = player.getUniqueId();
            StepAck ack;
            try {
                ack = StepAck.read(bytes);
            } catch (WireException broken) {
                throw new IllegalArgumentException(player.getName() + "'s client sent a step ack Paper cannot read", broken);
            }
            onMainThread(() -> policy.acked(id, ack.tick(), ack.busy()));
        });
        Step.policy = policy::run;
        // The first tick runs once the server is done starting, so the pool hears from a Paper players can join.
        Bukkit.getScheduler().runTask(this, () -> connect(port));
    }

    private void connect(int port) {
        try {
            String name = System.getProperty("playtest.paper.name", "paper");
            pool = Link.open(port, new Hello(Role.PAPER, name), message -> onMainThread(() -> receive(message)), this::poolLost);
        } catch (IOException unreachable) {
            poolLost(unreachable);
        }
    }

    private void receive(Message message) {
        switch (message) {
            case Stepping stepping -> Step.on = true;
            case Claim claim -> claim(claim);
            case Resume resume -> resume(resume);
            case Release release -> {
                coverage.ended(release.attempt());
                policy.release(attempts.release(release.attempt()));
                ground.release(release.attempt());
            }
            case RegionsAhead ahead -> ground.load(ahead.regions());
            case Probe probe -> {
                int ranAfter = policy.lastEnded();
                var players = online(probe.players());
                String failure = players.failure() != null ? players.failure() : probes.run(players.online(), probe.action());
                // A probe is done once its players' clients have what it caused, so the next stimulus finds it there.
                if (failure == null) policy.deliver(probe.players(), () -> pool.send(new ProbeDone(probe.request(), ranAfter, null)));
                else pool.send(new ProbeDone(probe.request(), ranAfter, failure));
            }
            case Settle settle -> policy.settle(attempts.players(settle.id()), () -> {
                coverage.settled(settle.id());
                pool.send(new Settled(settle.id(), List.of()));
            });
            case Query query -> pool.send(marks(query));
            case StepUntil step -> policy.stepUntil(step.player(), step.tick(), step.barrier());
            case StopStepping stop -> policy.stop(stop.player());
            default -> getLogger().severe("The game pool sent " + message + ", which Paper never receives");
        }
    }

    /**
     * Gives the attempt its players: their counted work holds back ticks from now on, they see only one
     * another, lose what earlier probes gave them alone, are wiped (Paper's state here, each plugin's own on the
     * {@link PlayerWipeEvent}), and stand at the middle of the attempt's region. The claim is done once
     * each of their clients holds all of it.
     */
    private void claim(Claim claim) {
        var players = online(claim.players());
        if (players.failure() != null) {
            pool.send(new Claimed(claim.attempt(), players.failure()));
            return;
        }
        // What plugins do for the attempt from here on, its players' wipe included, counts for it.
        coverage.started(claim.attempt());
        attempts.claim(claim.attempt(), claim.players());
        ground.claim(claim.attempt(), claim.region());
        policy.claim(claim.players());
        probes.forget(players.online());
        for (Player player : players.online()) {
            wipe.wipe(player);
            Bukkit.getPluginManager().callEvent(new PlayerWipeEvent(player));
        }
        Location middle = middle(players.online().getFirst().getWorld(), claim.region());
        for (Player player : players.online()) {
            player.setVelocity(new Vector());
            player.setFallDistance(0);
            player.teleport(middle);
        }
        policy.deliver(claim.players(), () -> pool.send(new Claimed(claim.attempt(), null)));
    }

    /**
     * Gives the attempt its players again after this Paper was killed and booted under it: as a claim
     * does, but without the wipe or the move, so they keep what Paper loaded for them. Resumed once each
     * of their clients holds all Paper sends them.
     */
    private void resume(Resume resume) {
        int ranAfter = policy.lastEnded();
        var players = online(resume.players());
        if (players.failure() != null) {
            pool.send(new Resumed(resume.attempt(), ranAfter, players.failure()));
            return;
        }
        coverage.started(resume.attempt());
        attempts.claim(resume.attempt(), resume.players());
        policy.claim(resume.players());
        policy.deliver(resume.players(), () -> pool.send(new Resumed(resume.attempt(), ranAfter, null)));
    }

    /** Leaves a mark of [kind] on the player: Paper keeps some kinds, this plugin the others. */
    private void mark(Player player, Kind kind) {
        if (Wipe.KINDS.contains(kind)) wipe.mark(player, kind);
        else owned.mark(player, kind);
    }

    /** Answers which kinds the queried player carries a mark of. */
    private Marks marks(Query query) {
        Player player = Bukkit.getPlayer(query.player());
        if (player == null) return new Marks(query.request(), List.of(), "the player " + query.player() + " is not online");
        var marked = new ArrayList<Kind>();
        for (Kind kind : Kind.values()) {
            if (Wipe.KINDS.contains(kind) ? wipe.marked(player, kind) : owned.marked(player, kind)) marked.add(kind);
        }
        return new Marks(query.request(), List.copyOf(marked), null);
    }


    /** Where a claim puts the attempt's players: on the ground at the middle of the region. */
    private static Location middle(World world, Region region) {
        return new Location(world, region.x() + 0.5, world.getHighestBlockYAt(region.x(), region.z()) + 1, region.z() + 0.5);
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
        if (pool != null) pool.send(new PlayerLeft(player.getName(), event.getReason().name()));
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
        pool.send(new WorkHung(hung.playerName(), hung.name(), hung.beganAfter()));
    }

    /** Work reported hung ended; the pool lets its player back. */
    private void reportEnded(WorkLedger.Hung hung) {
        getLogger().info(hung.playerName() + "'s hung work \"" + hung.name() + "\" ended.");
        pool.send(new HungEnded(hung.playerName(), hung.name()));
    }

    /** The client acked nothing for 5 s while behind; it holds back no tick and the pool replaces it. */
    private void reportStalled(Acks.Stalled stalled) {
        Player player = Bukkit.getPlayer(stalled.player());
        if (player == null) return;
        getLogger().warning(player.getName() + "'s client acked no tick for 5 s after tick " + stalled.lastAcked() + "; it holds no more ticks.");
        pool.send(new ClientStalled(player.getName(), stalled.lastAcked()));
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
