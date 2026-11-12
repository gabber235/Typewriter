package probe.plugin;

import com.destroystokyo.paper.event.server.ServerTickEndEvent;
import java.nio.ByteBuffer;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;
import java.util.concurrent.TimeUnit;
import net.kyori.adventure.text.Component;
import net.minecraft.network.protocol.common.ClientboundPingPacket;
import net.minecraft.server.MinecraftServer;
import org.bukkit.Bukkit;
import org.bukkit.ServerTickManager;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.scheduler.BukkitTask;
import probe.agent.Step;

/**
 * Spike N: the runner decides when a tick happens. The step agent makes Paper's main loop wait for a
 * permit between ticks (packets and tasks keep being handled); this class is the step policy, run on
 * the main thread on every idle pass:
 *
 *   grant the next tick only when the subject's client has acked the previous one (step ping sent at
 *   the end of every tick, acked by the client after its own tick) and the subject's async work is
 *   quiet (running, or handed to the async scheduler by a tick that already ran). Hung work is
 *   cancelled after limitMs of wall clock, the only wall clock limit.
 *
 *   n.mode?on=1&subject=name&ack=1&quiet=1&limitMs=1000&auto=0&lag=tick|wall
 *   n.req?player&kind=chat|late|async|asyncx|asyncsync|hang&token&late&asyncMs&broken   (direct, between ticks)
 *   n.run?max=W&stopOnSeen=1   (blocking: steps up to W ticks under the policy; reports the step the client saw the token)
 *   n.freeze?seconds=2&steps=10   N1: what still runs while vanilla's tick freeze holds
 */
final class N implements Listener {
    private static final int BASE = 1 << 30;
    private static final ExecutorService pool = Executors.newCachedThreadPool(r -> {
        Thread t = new Thread(r, "probe-n-dispatcher");
        t.setDaemon(true);
        return t;
    });

    /** Counted work of one subject. Bukkit async work counts once a tick has run since it was scheduled. */
    private record Work(UUID owner, int submitTick, boolean bukkit, Set<Thread> threads, boolean[] done) {}

    private static final Set<Work> work = ConcurrentHashMap.newKeySet();

    // Policy, main thread only.
    private static boolean ack = true, quiet = true, auto;
    private static long limitMs = 1000;
    private static String subjectName;
    private static UUID subject;
    /** In process input prototype: more clients in lockstep; the next tick waits for every one of them. */
    private static final java.util.List<String> otherNames = new java.util.ArrayList<>();
    private static final Map<UUID, Integer> ackedBy = new ConcurrentHashMap<>();
    private static int awaiting = -1, acked = -1, ackSeen, lastClientTicks;
    private static long quietSince, quietWaitNanos, ackWaitNanos, ackSince;
    private static int hung, stepsTotal, pingsSent, acksReceived;
    private static Run run;
    private static volatile int effectTick = -1;

    private static final class Run {
        final int max;
        final boolean stopOnSeen;
        final CompletableFuture<Map<String, Object>> done = new CompletableFuture<>();
        final long t0 = System.nanoTime();
        final int tick0 = MinecraftServer.getServer().getTickCount();
        final long quiet0 = quietWaitNanos, ack0 = ackWaitNanos;
        final int hung0 = hung;
        int steps, seenStep = -1, seenTick = -1;

        Run(int max, boolean stopOnSeen) {
            this.max = max;
            this.stopOnSeen = stopOnSeen;
        }
    }

    private N() {}

    static void start(ProbePlugin p) {
        try {
            Class.forName("probe.agent.Step", false, ClassLoader.getSystemClassLoader());
        } catch (ClassNotFoundException e) {
            return; // no step agent on this Paper: spike N is off
        }
        Bukkit.getPluginManager().registerEvents(new N(), p);
        Bukkit.getMessenger().registerIncomingPluginChannel(p, "probe:step", (channel, player, bytes) -> {
            ByteBuffer b = ByteBuffer.wrap(bytes);
            int tick = b.getInt(), seen = b.getInt(), clientTicks = b.getInt();
            if (!Bukkit.isPrimaryThread()) {
                MinecraftServer.getServer().execute(() -> onAck(player, tick, seen, clientTicks));
            } else {
                onAck(player, tick, seen, clientTicks);
            }
        });
        Step.hook = N::hook;
    }

    private static void onAck(Player player, int tick, int seen, int clientTicks) {
        acksReceived++;
        if (!otherNames.isEmpty() && otherNames.contains(player.getName())) {
            ackedBy.merge(player.getUniqueId(), tick, Math::max);
            return;
        }
        if (!player.getUniqueId().equals(subject)) return;
        acked = Math.max(acked, tick);
        lastClientTicks = clientTicks;
        if (seen != 0) {
            ackSeen = 1;
            if (run != null && run.seenStep < 0) {
                run.seenStep = run.steps;
                run.seenTick = tick;
            }
        }
    }

    @EventHandler
    public void onTickEnd(ServerTickEndEvent e) {
        if (!Step.on || !ack) return;
        Player p = subject == null ? null : Bukkit.getPlayer(subject);
        if (p == null) return;
        awaiting = e.getTickNumber();
        ackSince = System.nanoTime();
        ((CraftPlayer) p).getHandle().connection.send(new ClientboundPingPacket(BASE + awaiting));
        pingsSent++;
        for (String n : otherNames) {
            Player o = Bukkit.getPlayerExact(n);
            if (o != null) ((CraftPlayer) o).getHandle().connection.send(new ClientboundPingPacket(BASE + awaiting));
        }
    }

    /** Every other subject that is online has acked the awaited tick. */
    private static boolean othersAcked() {
        for (String n : otherNames) {
            Player o = Bukkit.getPlayerExact(n);
            if (o != null && ackedBy.getOrDefault(o.getUniqueId(), -1) < awaiting) return false;
        }
        return true;
    }

    private static boolean subjectOnline() {
        if (subject == null && subjectName != null) {
            Player p = Bukkit.getPlayerExact(subjectName);
            if (p != null) subject = p.getUniqueId();
        }
        return subject != null && Bukkit.getPlayer(subject) != null;
    }

    static int busy(UUID who) {
        int now = MinecraftServer.currentTick, n = 0;
        for (Work w : work) {
            if (w.done[0]) {
                work.remove(w);
                continue;
            }
            if (w.owner.equals(who) && (!w.bukkit || now > w.submitTick)) n++;
        }
        return n;
    }

    /** Main thread, every idle pass between ticks. */
    private static void hook() {
        if (!Step.on || Step.permits() > 0) return;
        if (run == null && !auto) return;
        boolean online = subjectOnline();
        if (ack && online && (acked < awaiting || !othersAcked())) return;
        if (ackSince != 0) {
            ackWaitNanos += System.nanoTime() - ackSince;
            ackSince = 0;
        }
        if (quiet && online && busy(subject) > 0) {
            long now = System.nanoTime();
            if (quietSince == 0) quietSince = now;
            if (now - quietSince < limitMs * 1_000_000L) return;
            for (Work w : work) {
                if (w.owner.equals(subject)) for (Thread t : w.threads) t.interrupt();
            }
            hung++;
            quietWaitNanos += now - quietSince;
            quietSince = 0;
            return; // interrupted work finishes on its own; the next pass sees it quiet
        }
        if (quietSince != 0) {
            quietWaitNanos += System.nanoTime() - quietSince;
            quietSince = 0;
        }
        if (run != null) {
            if ((run.stopOnSeen && run.seenStep >= 0) || run.steps >= run.max) {
                Run r = run;
                run = null;
                Map<String, Object> m = new LinkedHashMap<>();
                m.put("steps", r.steps);
                m.put("seenStep", r.seenStep);
                m.put("seenTick", r.seenTick);
                m.put("tick0", r.tick0);
                m.put("tick", MinecraftServer.getServer().getTickCount());
                m.put("effectTick", effectTick);
                m.put("wallMicros", (System.nanoTime() - r.t0) / 1000);
                m.put("quietWaitMicros", (quietWaitNanos - r.quiet0) / 1000);
                m.put("ackWaitMicros", (ackWaitNanos - r.ack0) / 1000);
                m.put("hung", hung - r.hung0);
                m.put("clientTicks", lastClientTicks);
                r.done.complete(m);
                return;
            }
            r_step(run);
            return;
        }
        Step.grant(1);
        stepsTotal++;
    }

    private static void r_step(Run r) {
        r.steps++;
        stepsTotal++;
        Step.grant(1);
    }

    static boolean run(String name, Map<String, String> q, Player p, Map<String, Object> r) {
        switch (name) {
            case "n.mode" -> {
                if (q.containsKey("ack")) ack = "1".equals(q.get("ack"));
                if (q.containsKey("quiet")) quiet = "1".equals(q.get("quiet"));
                if (q.containsKey("auto")) auto = "1".equals(q.get("auto"));
                if (q.containsKey("limitMs")) limitMs = Long.parseLong(q.get("limitMs"));
                if (q.containsKey("lag")) Step.tickClock = "tick".equals(q.get("lag"));
                if (q.containsKey("subject")) {
                    String[] names = q.get("subject").split(",");
                    subjectName = names[0];
                    subject = null;
                    otherNames.clear();
                    for (int i = 1; i < names.length; i++) otherNames.add(names[i]);
                    ackedBy.clear();
                }
                if (q.containsKey("on")) {
                    boolean on = "1".equals(q.get("on"));
                    if (on && !Step.on) {
                        acked = awaiting = MinecraftServer.getServer().getTickCount();
                        for (String n : otherNames) {
                            Player o = Bukkit.getPlayerExact(n);
                            if (o != null) ackedBy.put(o.getUniqueId(), awaiting);
                        }
                        Step.on = true;
                    } else if (!on && Step.on) {
                        Step.on = false;
                        resetSchedule();
                        Step.grant(1);
                    }
                }
                r.put("on", Step.on);
                r.put("lagTick", Step.tickClock);
                r.put("auto", auto);
            }
            case "n.req" -> req(p, q, r);
            case "n.stats" -> {
                r.put("taken", Step.taken());
                r.put("pingsSent", pingsSent);
                r.put("acksReceived", acksReceived);
                r.put("subject", String.valueOf(subject));
                r.put("subjectName", String.valueOf(subjectName));
                r.put("stepsTotal", stepsTotal);
                r.put("tick", MinecraftServer.getServer().getTickCount());
                r.put("currentTick", MinecraftServer.currentTick);
                r.put("acked", acked);
                r.put("awaiting", awaiting);
                r.put("hung", hung);
                r.put("idleMs", Step.idleNanos() / 1_000_000);
                r.put("lagTick", MinecraftServer.getServer().overworld().getLagCompensationTick());
                r.put("work", work.size());
                r.put("tickRate", Bukkit.getServerTickManager().getTickRate());
            }
            default -> {
                return false;
            }
        }
        return true;
    }

    /**
     * Stepped ticks ran far ahead of Paper's wall clock schedule; without a reset Paper's own loop would
     * now wait until the wall clock catches up (seconds).
     */
    private static void resetSchedule() {
        try {
            MinecraftServer s = MinecraftServer.getServer();
            var next = MinecraftServer.class.getDeclaredField("nextTickTimeNanos");
            next.setAccessible(true);
            next.setLong(s, net.minecraft.util.Util.getNanos());
            var init = MinecraftServer.class.getDeclaredMethod("initTickSchedule");
            init.setAccessible(true);
            init.invoke(s);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException(e);
        }
    }

    /** Off the main thread: hand the run to the policy and wait for it. */
    static Map<String, Object> runBlocking(Map<String, String> q) throws Exception {
        Run r = new Run(Integer.parseInt(q.getOrDefault("max", "1")), !"0".equals(q.get("stopOnSeen")));
        MinecraftServer.getServer().execute(() -> {
            ackSeen = 0;
            run = r;
            Step.grant(0);
        });
        return r.done.get(Long.parseLong(q.getOrDefault("timeoutMs", "60000")), TimeUnit.MILLISECONDS);
    }

    private static void req(Player p, Map<String, String> q, Map<String, Object> r) {
        String kind = q.get("kind"), token = q.get("token");
        boolean broken = "1".equals(q.get("broken"));
        long asyncMs = Long.parseLong(q.getOrDefault("asyncMs", "0"));
        int late = Integer.parseInt(q.getOrDefault("late", "0"));
        UUID id = p.getUniqueId();
        effectTick = -1;
        Runnable chat = () -> {
            effectTick = MinecraftServer.getServer().getTickCount();
            p.sendMessage(Component.text(token));
        };
        Runnable effect = broken ? () -> {} : chat;
        r.put("stimTick", MinecraftServer.getServer().getTickCount());
        switch (kind) {
            case "chat" -> effect.run();
            case "late" -> Bukkit.getScheduler().runTaskLater(ProbeAccess.plugin(), effect, late);
            case "asyncx" -> counted(id, false, asyncMs, effect);
            case "async" -> counted(id, true, asyncMs, effect);
            case "asyncsync" -> counted(id, true, asyncMs, () -> Bukkit.getScheduler().runTask(ProbeAccess.plugin(), effect));
            case "hang" -> counted(id, true, 600_000, effect);
            default -> throw new IllegalArgumentException("kind " + kind);
        }
    }

    private static void counted(UUID owner, boolean bukkit, long ms, Runnable then) {
        Work w = new Work(owner, MinecraftServer.currentTick, bukkit, ConcurrentHashMap.newKeySet(), new boolean[1]);
        work.add(w);
        Runnable body = () -> {
            w.threads.add(Thread.currentThread());
            try {
                Thread.sleep(ms);
                then.run();
            } catch (InterruptedException ignored) {
                // cancelled at the outer limit: abandoned, no effect
            } finally {
                w.threads.remove(Thread.currentThread());
                Thread.interrupted();
                w.done[0] = true;
            }
        };
        if (bukkit) {
            Bukkit.getScheduler().runTaskAsynchronously(ProbeAccess.plugin(), body);
        } else {
            pool.execute(body);
        }
    }

    /** N1: vanilla freeze. What advances during a wall clock wait while frozen, and during a step. */
    static Map<String, Object> freezeProbe(Map<String, String> q) throws Exception {
        long seconds = Long.parseLong(q.getOrDefault("seconds", "2"));
        int steps = Integer.parseInt(q.getOrDefault("steps", "10"));
        ServerTickManager tm = Bukkit.getServerTickManager();
        int[] sched = new int[1];
        Map<String, Object> out = new LinkedHashMap<>();
        BukkitTask counter = Bukkit.getScheduler().runTaskTimer(ProbeAccess.plugin(), () -> sched[0]++, 1, 1);
        try {
            Map<String, Long> a = sync(() -> snapshot(sched[0]));
            sync(() -> { tm.setFrozen(true); return null; });
            Thread.sleep(seconds * 1000);
            Map<String, Long> b = sync(() -> snapshot(sched[0]));
            sync(() -> { tm.stepGameIfFrozen(steps); return null; });
            Thread.sleep(1000);
            Map<String, Long> c = sync(() -> snapshot(sched[0]));
            sync(() -> { tm.setFrozen(false); return null; });
            Map<String, Object> frozen = new LinkedHashMap<>(), step = new LinkedHashMap<>();
            for (String k : a.keySet()) {
                frozen.put(k, b.get(k) - a.get(k));
                step.put(k, c.get(k) - b.get(k));
            }
            out.put("seconds", seconds);
            out.put("frozenDelta", frozen);
            out.put("steps", steps);
            out.put("stepDelta", step);
        } finally {
            counter.cancel();
        }
        return out;
    }

    private static Map<String, Long> snapshot(int sched) {
        Map<String, Long> m = new LinkedHashMap<>();
        MinecraftServer s = MinecraftServer.getServer();
        m.put("serverTickCount", (long) s.getTickCount());
        m.put("bukkitCurrentTick", (long) Bukkit.getCurrentTick());
        m.put("bukkitTaskRuns", (long) sched);
        m.put("worldGameTime", s.overworld().getGameTime());
        m.put("lagCompensationTick", s.overworld().getLagCompensationTick());
        Player p = Bukkit.getOnlinePlayers().stream().findFirst().orElse(null);
        if (p != null) {
            var h = ((CraftPlayer) p).getHandle();
            m.put("playerTickCount", (long) h.tickCount);
            m.put("playerTicksLived", (long) p.getTicksLived());
        }
        return m;
    }

    private static <T> T sync(java.util.concurrent.Callable<T> c) throws Exception {
        CompletableFuture<T> f = new CompletableFuture<>();
        MinecraftServer.getServer().execute(() -> {
            try {
                f.complete(c.call());
            } catch (Throwable t) {
                f.completeExceptionally(t);
            }
        });
        return f.get(30, TimeUnit.SECONDS);
    }
}
