package com.typewritermc.playtest.plugin;

import com.destroystokyo.paper.event.server.ServerTickEndEvent;
import com.typewritermc.playtest.agent.Step;
import com.typewritermc.playtest.wire.Link;
import com.typewritermc.playtest.wire.Message;
import com.typewritermc.playtest.wire.Message.Hello;
import com.typewritermc.playtest.wire.Message.Probe;
import com.typewritermc.playtest.wire.Message.ProbeDone;
import com.typewritermc.playtest.wire.Message.Role;
import com.typewritermc.playtest.wire.Message.StepUntil;
import com.typewritermc.playtest.wire.Message.Stepping;
import com.typewritermc.playtest.wire.Message.StopStepping;
import java.io.IOException;
import java.nio.ByteBuffer;
import java.util.TreeSet;
import java.util.UUID;
import net.minecraft.network.protocol.common.ClientboundPingPacket;
import net.minecraft.server.MinecraftServer;
import org.bukkit.Bukkit;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.plugin.java.JavaPlugin;

/**
 * The framework's side of a Paper the game pool booted: the step policy that grants ticks, the step
 * pings and barriers each client follows, and the probes. Every message from the pool runs on the
 * main thread between ticks.
 */
public final class PlaytestPlugin extends JavaPlugin implements Listener {
    private static final String STEP_ACK = "playtest:step";

    private final StepPolicy policy = new StepPolicy(this::sendBarrier);
    private final Probes probes = new Probes();
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
            case Probe probe -> {
                Player player = Bukkit.getPlayer(probe.player());
                String failure = player == null ? "the player " + probe.player() + " is not online" : probes.run(player, probe.action());
                pool.send(new ProbeDone(probe.request(), policy.lastEnded(), failure));
            }
            case StepUntil step -> policy.stepUntil(step.player(), step.tick(), step.barrier());
            case StopStepping stop -> policy.stop(stop.player());
            default -> getLogger().severe("The game pool sent " + message + ", which Paper never receives");
        }
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
