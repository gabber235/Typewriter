package com.typewritermc.playtest.plugin;

import com.destroystokyo.paper.event.server.ServerTickEndEvent;
import com.typewritermc.playtest.agent.Step;
import com.typewritermc.playtest.wire.Link;
import com.typewritermc.playtest.wire.Message;
import com.typewritermc.playtest.wire.Message.Claim;
import com.typewritermc.playtest.wire.Message.Claimed;
import com.typewritermc.playtest.wire.Message.Hello;
import com.typewritermc.playtest.wire.Message.Probe;
import com.typewritermc.playtest.wire.Message.ProbeDone;
import com.typewritermc.playtest.wire.Message.Region;
import com.typewritermc.playtest.wire.Message.Release;
import com.typewritermc.playtest.wire.Message.Role;
import com.typewritermc.playtest.wire.Message.StepUntil;
import com.typewritermc.playtest.wire.Message.Stepping;
import com.typewritermc.playtest.wire.Message.StopStepping;
import java.io.IOException;
import java.nio.ByteBuffer;
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
import org.bukkit.plugin.java.JavaPlugin;
import org.bukkit.util.Vector;

/**
 * The framework's side of a Paper the game pool booted: the attempts sharing it, the step policy that
 * grants ticks, the step pings and barriers each client follows, and the probes. Every message from the
 * pool runs on the main thread between ticks.
 */
public final class PlaytestPlugin extends JavaPlugin implements Listener {
    private static final String STEP_ACK = "playtest:step";

    private final StepPolicy policy = new StepPolicy(this::sendBarrier, PlaytestPlugin::nothingLeftToSend, task -> MinecraftServer.getServer().scheduleOnMain(task));
    private final Probes probes = new Probes();
    private final Attempts attempts = new Attempts(this);
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
        int port = Integer.getInteger("playtest.pool.port", -1);
        if (port < 0) throw new IllegalStateException("playtest.pool.port is not set: only the game pool runs this plugin");
        Bukkit.getPluginManager().registerEvents(this, this);
        Bukkit.getPluginManager().registerEvents(probes, this);
        Bukkit.getPluginManager().registerEvents(attempts, this);
        Bukkit.getMessenger().registerIncomingPluginChannel(this, STEP_ACK, (channel, player, bytes) -> {
            UUID id = player.getUniqueId();
            var ack = ByteBuffer.wrap(bytes);
            int tick = ack.getInt();
            boolean busy = ack.get() != 0;
            onMainThread(() -> policy.acked(id, tick, busy));
        });
        Step.policy = policy::run;
        // The first tick runs once the server is done starting, so the pool hears from a Paper players can join.
        Bukkit.getScheduler().runTask(this, () -> connect(port));
    }

    private void connect(int port) {
        try {
            pool = Link.open(port, new Hello(Role.PAPER, "paper"), message -> onMainThread(() -> receive(message)), this::poolLost);
        } catch (IOException unreachable) {
            poolLost(unreachable);
        }
    }

    private void receive(Message message) {
        switch (message) {
            case Stepping stepping -> Step.on = true;
            case Claim claim -> claim(claim);
            case Release release -> policy.release(attempts.release(release.attempt()));
            case Probe probe -> {
                int ranAfter = policy.lastEnded();
                var players = online(probe.players());
                String failure = players.failure() != null ? players.failure() : probes.run(players.online(), probe.action());
                // A probe is done once its players' clients have what it caused, so the next stimulus finds it there.
                if (failure == null) policy.deliver(probe.players(), () -> pool.send(new ProbeDone(probe.request(), ranAfter, null)));
                else pool.send(new ProbeDone(probe.request(), ranAfter, failure));
            }
            case StepUntil step -> policy.stepUntil(step.player(), step.tick(), step.barrier());
            case StopStepping stop -> policy.stop(stop.player());
            default -> getLogger().severe("The game pool sent " + message + ", which Paper never receives");
        }
    }

    /**
     * Gives the attempt its players: they hold back every tick from now on, see only one another, lose
     * what earlier probes gave them alone, and stand at the middle of the attempt's region. The claim is
     * done once each of their clients holds all of it.
     */
    private void claim(Claim claim) {
        var players = online(claim.players());
        if (players.failure() != null) {
            pool.send(new Claimed(claim.attempt(), players.failure()));
            return;
        }
        attempts.claim(claim.attempt(), claim.players());
        policy.claim(claim.players());
        probes.forget(players.online());
        Location middle = middle(players.online().getFirst().getWorld(), claim.region());
        for (Player player : players.online()) {
            player.setVelocity(new Vector());
            player.setFallDistance(0);
            player.teleport(middle);
        }
        policy.deliver(claim.players(), () -> pool.send(new Claimed(claim.attempt(), null)));
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

    @EventHandler
    public void onTickEnd(ServerTickEndEvent event) {
        policy.tickEnded(event.getTickNumber());
        if (!Step.on) return;
        var ping = new ClientboundPingPacket(StepPolicy.STEP_BASE + event.getTickNumber());
        for (Player player : Bukkit.getOnlinePlayers()) ((CraftPlayer) player).getHandle().connection.send(ping);
    }

    private void sendBarrier(UUID id, int barrier) {
        Player player = Bukkit.getPlayer(id);
        if (player != null) ((CraftPlayer) player).getHandle().connection.send(new ClientboundPingPacket(barrier));
    }

    /**
     * Whether Paper has sent the player everything the client shows: every chunk around the player within
     * the client's own view distance, and the command tree, which Paper builds on a pool of its own and
     * sends from a task that pool queues on the main thread once done. Paper may send chunks further out,
     * nearest first; the client draws none of them.
     */
    private static boolean nothingLeftToSend(UUID id) {
        Player player = Bukkit.getPlayer(id);
        if (player == null) return true;
        var commands = (ThreadPoolExecutor) Commands.COMMAND_SENDING_POOL;
        if (commands.getActiveCount() > 0 || !commands.getQueue().isEmpty()) return false;
        // The test Paper's chunk loader applies around the player's chunk, at the distance the client draws.
        int radius = Math.min(player.getSendViewDistance(), player.getClientViewDistance());
        int centerX = player.getLocation().getBlockX() >> 4;
        int centerZ = player.getLocation().getBlockZ() >> 4;
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
