package probe.plugin;

import com.destroystokyo.paper.event.server.ServerTickEndEvent;
import java.nio.ByteBuffer;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.Iterator;
import java.util.LinkedHashMap;
import java.util.List;
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
 * Topology spike, built on spike N: the runner decides when a tick happens. The step agent makes Paper's
 * main loop wait for a permit between ticks; this class is the step policy, widened from one subject to
 * a set of attempts that run at the same time on this Paper. It runs on the main thread on every idle pass:
 *
 *   a step ping goes to every online player at the end of each tick. Tick n+1 is granted only when every
 *   claimed player (a member of a running attempt) acked tick n and every claimed player's counted async
 *   work is quiet. Hung work is cancelled after limitMs of wall clock. An attempt ends between ticks, once
 *   its members acked the last tick and are quiet, either because every member saw its token (pass) or
 *   because its window of ticks has run (fail). Ticks run only while an attempt wants them, or in auto mode
 *   (a client joining) paced at autoMinMicros.
 *
 *   n.mode?on=1|0&limitMs=1000&lag=tick|wall&autoMinMicros=1000
 *   n.auto?on=1|0          reference counted: ticks run while any join is in progress
 *   n.sync?player          the player's client just started stepping: its acks count from the current tick
 *   n.att?players=a,b&max=W&kind=chat|late|asyncsync|async|hang&token&late&asyncMs&broken   (blocking)
 *   n.stats
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
    private static long limitMs = 1000, autoMinNanos = 1_000_000L;
    private static int awaiting = -1, autoRefs, hung, stepsTotal, pingsSent, acksReceived;
    private static long lastPass, lastAutoGrant;
    private static int idleTicks;
    private static final Map<UUID, Integer> acked = new HashMap<>();
    private static final Map<UUID, Long> busySince = new HashMap<>();
    private static final List<Attempt> attempts = new ArrayList<>();

    private static final class Attempt {
        final List<UUID> members;
        final List<String> names;
        final int max;
        final Map<UUID, Integer> seenTick = new HashMap<>();
        final CompletableFuture<Map<String, Object>> done = new CompletableFuture<>();
        final long t0 = System.nanoTime();
        int startTick, hung;
        long lostQuiet, lostAck, ownQuiet, ownAck;
        Map<String, Object> stim;

        Attempt(List<UUID> members, List<String> names, int max) {
            this.members = members;
            this.names = names;
            this.max = max;
        }
    }

    private N() {}

    static void start(ProbePlugin p) {
        try {
            Class.forName("probe.agent.Step", false, ClassLoader.getSystemClassLoader());
        } catch (ClassNotFoundException e) {
            return; // no step agent on this Paper: stepping is off
        }
        Bukkit.getPluginManager().registerEvents(new N(), p);
        Bukkit.getMessenger().registerIncomingPluginChannel(p, "probe:step", (channel, player, bytes) -> {
            ByteBuffer b = ByteBuffer.wrap(bytes);
            int tick = b.getInt(), seen = b.getInt(), clientTicks = b.getInt();
            if (!Bukkit.isPrimaryThread()) {
                MinecraftServer.getServer().execute(() -> onAck(player.getUniqueId(), tick, seen));
            } else {
                onAck(player.getUniqueId(), tick, seen);
            }
        });
        Step.hook = N::hook;
    }

    private static void onAck(UUID id, int tick, int seen) {
        acksReceived++;
        acked.merge(id, tick, Math::max);
        if (seen == 0) return;
        for (Attempt a : attempts) {
            // Only acks of ticks after the stimulus: an ack in flight from the previous attempt reports the previous
            // token as seen (one false pass in 18,000, CI run 42342290365).
            if (a.members.contains(id) && tick > a.startTick) a.seenTick.putIfAbsent(id, tick);
        }
    }

    @EventHandler
    public void onTickEnd(ServerTickEndEvent e) {
        if (!Step.on) return;
        awaiting = e.getTickNumber();
        for (Player p : Bukkit.getOnlinePlayers()) {
            ((CraftPlayer) p).getHandle().connection.send(new ClientboundPingPacket(BASE + awaiting));
            pingsSent++;
        }
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

    private static boolean online(UUID id) {
        return Bukkit.getPlayer(id) != null;
    }

    private static boolean lagging(UUID id) {
        return online(id) && acked.getOrDefault(id, -1) < awaiting;
    }

    /** Main thread, every idle pass between ticks. */
    private static void hook() {
        long now = System.nanoTime(), dt = lastPass == 0 ? 0 : Math.min(now - lastPass, 5_000_000L);
        lastPass = now;
        if (!Step.on || Step.permits() > 0) return;
        if (attempts.isEmpty() && autoRefs == 0) {
            // Idle keepalive: without ticks Paper's watchdog stops the server after 60 s and keepalives (sent from
            // the tick) stop, so a Paper with no attempt still ticks once a second. No attempt counts these ticks.
            if (now - lastAutoGrant >= 1_000_000_000L) {
                lastAutoGrant = now;
                idleTicks++;
                Step.grant(1);
            }
            return;
        }
        // Attempts whose members are caught up and quiet may end now, before any further tick.
        for (Iterator<Attempt> it = attempts.iterator(); it.hasNext(); ) {
            Attempt a = it.next();
            boolean ready = true;
            for (UUID m : a.members) {
                if (lagging(m) || busy(m) > 0) {
                    ready = false;
                    break;
                }
            }
            if (!ready) continue;
            boolean allSeen = a.seenTick.keySet().containsAll(a.members);
            if (allSeen || awaiting - a.startTick >= a.max) {
                it.remove();
                finish(a, allSeen);
            }
        }
        Set<UUID> lag = new HashSet<>(), busyNow = new HashSet<>();
        for (Attempt a : attempts) {
            for (UUID m : a.members) {
                if (lagging(m)) lag.add(m);
                else if (busy(m) > 0) busyNow.add(m);
            }
        }
        if (!lag.isEmpty() || !busyNow.isEmpty()) {
            for (Attempt a : attempts) {
                boolean ownLag = false, ownBusy = false;
                for (UUID m : a.members) {
                    ownLag |= lag.contains(m);
                    ownBusy |= busyNow.contains(m);
                }
                if (ownLag) a.ownAck += dt;
                else if (ownBusy) a.ownQuiet += dt;
                else if (!lag.isEmpty()) a.lostAck += dt;
                else a.lostQuiet += dt;
            }
        }
        // Hung work: cancelled at the wall clock limit, per subject.
        for (UUID m : busyNow) {
            long since = busySince.computeIfAbsent(m, k -> now);
            if (now - since >= limitMs * 1_000_000L) {
                for (Work w : work) {
                    if (w.owner.equals(m)) for (Thread t : w.threads) t.interrupt();
                }
                hung++;
                for (Attempt a : attempts) if (a.members.contains(m)) a.hung++;
                busySince.remove(m);
            }
        }
        busySince.keySet().retainAll(busyNow);
        if (!lag.isEmpty() || !busyNow.isEmpty()) return;
        if (attempts.isEmpty()) {
            if (autoRefs == 0 || now - lastAutoGrant < autoMinNanos) return;
            lastAutoGrant = now;
        }
        Step.grant(1);
        stepsTotal++;
    }

    private static void finish(Attempt a, boolean pass) {
        Map<String, Object> m = new LinkedHashMap<>(a.stim);
        m.put("pass", pass);
        m.put("ticks", awaiting - a.startTick);
        List<Integer> seen = new ArrayList<>();
        for (UUID u : a.members) seen.add(a.seenTick.containsKey(u) ? a.seenTick.get(u) - a.startTick : -1);
        m.put("seen", seen);
        m.put("wallMicros", (System.nanoTime() - a.t0) / 1000);
        m.put("lostQuietMicros", a.lostQuiet / 1000);
        m.put("lostAckMicros", a.lostAck / 1000);
        m.put("ownQuietMicros", a.ownQuiet / 1000);
        m.put("ownAckMicros", a.ownAck / 1000);
        m.put("hung", a.hung);
        m.put("concurrent", attempts.size());
        a.done.complete(m);
    }

    static boolean run(String name, Map<String, String> q, Player p, Map<String, Object> r) {
        switch (name) {
            case "n.mode" -> {
                if (q.containsKey("limitMs")) limitMs = Long.parseLong(q.get("limitMs"));
                if (q.containsKey("autoMinMicros")) autoMinNanos = Long.parseLong(q.get("autoMinMicros")) * 1000;
                if (q.containsKey("lag")) Step.tickClock = "tick".equals(q.get("lag"));
                if (q.containsKey("on")) {
                    boolean on = "1".equals(q.get("on"));
                    if (on && !Step.on) {
                        awaiting = MinecraftServer.getServer().getTickCount();
                        for (Player o : Bukkit.getOnlinePlayers()) acked.put(o.getUniqueId(), awaiting);
                        Step.on = true;
                    } else if (!on && Step.on) {
                        Step.on = false;
                        resetSchedule();
                        Step.grant(1);
                    }
                }
                r.put("on", Step.on);
                r.put("lagTick", Step.tickClock);
            }
            case "n.auto" -> {
                autoRefs = Math.max(0, autoRefs + ("1".equals(q.get("on")) ? 1 : -1));
                r.put("autoRefs", autoRefs);
            }
            case "n.sync" -> {
                acked.merge(p.getUniqueId(), awaiting, Math::max);
                r.put("tick", awaiting);
            }
            case "n.stats" -> {
                r.put("taken", Step.taken());
                r.put("pingsSent", pingsSent);
                r.put("acksReceived", acksReceived);
                r.put("stepsTotal", stepsTotal);
                r.put("tick", MinecraftServer.getServer().getTickCount());
                r.put("awaiting", awaiting);
                r.put("attempts", attempts.size());
                r.put("autoRefs", autoRefs);
                r.put("hung", hung);
                r.put("idleMs", Step.idleNanos() / 1_000_000);
                r.put("work", work.size());
                r.put("idleTicks", idleTicks);
                r.put("permits", Step.permits());
                StringBuilder b = new StringBuilder();
                for (Attempt a : attempts) {
                    b.append(a.names).append(" start=").append(a.startTick).append(" max=").append(a.max).append(" seen=").append(a.seenTick.size());
                    for (UUID m : a.members) b.append(" [acked=").append(acked.get(m)).append(" online=").append(online(m)).append(" busy=").append(busy(m)).append(']');
                    b.append("; ");
                }
                r.put("detail", b.toString());
                StringBuilder o = new StringBuilder();
                for (Player pl : Bukkit.getOnlinePlayers()) o.append(pl.getName()).append('=').append(acked.get(pl.getUniqueId())).append(' ');
                r.put("acked", o.toString());
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

    /** Off the main thread: register the attempt and apply its stimulus between ticks, then wait for its verdict. */
    static Map<String, Object> attemptBlocking(Map<String, String> q) throws Exception {
        List<String> names = List.of(q.get("players").split(","));
        CompletableFuture<Attempt> reg = new CompletableFuture<>();
        MinecraftServer.getServer().execute(() -> {
            try {
                List<UUID> ids = new ArrayList<>();
                List<Player> ps = new ArrayList<>();
                for (String n : names) {
                    Player p = Bukkit.getPlayerExact(n);
                    if (p == null) throw new IllegalStateException("offline " + n);
                    ids.add(p.getUniqueId());
                    ps.add(p);
                }
                Attempt a = new Attempt(ids, names, Integer.parseInt(q.getOrDefault("max", "2")));
                a.startTick = awaiting;
                a.stim = new LinkedHashMap<>();
                boolean broken = "1".equals(q.get("broken"));
                for (int i = 0; i < ps.size(); i++) {
                    // Broken: the last member never gets the effect (for one player, nobody does).
                    req(ps.get(i), q, broken && i == ps.size() - 1, a.stim);
                }
                attempts.add(a);
                Step.grant(0);
                reg.complete(a);
            } catch (Throwable t) {
                reg.completeExceptionally(t);
            }
        });
        Attempt a = reg.get(30, TimeUnit.SECONDS);
        return a.done.get(Long.parseLong(q.getOrDefault("timeoutMs", "60000")), TimeUnit.MILLISECONDS);
    }

    private static void req(Player p, Map<String, String> q, boolean broken, Map<String, Object> r) {
        String kind = q.get("kind"), token = q.get("token");
        long asyncMs = Long.parseLong(q.getOrDefault("asyncMs", "0"));
        int late = Integer.parseInt(q.getOrDefault("late", "0"));
        UUID id = p.getUniqueId();
        Runnable chat = () -> p.sendMessage(Component.text(token));
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
