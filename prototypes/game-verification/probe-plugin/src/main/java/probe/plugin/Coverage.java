package probe.plugin;

import java.lang.reflect.Method;
import java.nio.file.Files;
import java.nio.file.Path;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.LockSupport;
import net.kyori.adventure.text.Component;
import net.minecraft.server.MinecraftServer;
import org.bukkit.Bukkit;
import org.bukkit.entity.Player;
import org.bukkit.plugin.Plugin;
import org.bukkit.scheduler.BukkitTask;
import org.bukkit.scheduler.BukkitWorker;

/**
 * Spike I: coverage per requirement through the JaCoCo agent's in process API, read by
 * reflection from the system class loader (the agent jar sits there with -javaagent).
 *
 * Any line command takes cov=ID: after the command ran, still on the main thread, the agent's
 * probes are read and reset and the dump is kept under ID. covDump waits first: wait=K ticks, or
 * quiet=1 until this plugin has no one shot scheduler task and no async worker left.
 */
final class Coverage {
    private static final Map<String, byte[]> dumps = new LinkedHashMap<>();
    private static Object agent;
    private static Method getData, setSession;
    private static Method period;
    static volatile int sink;

    private static synchronized void init() throws Exception {
        if (agent != null) return;
        Class<?> rt = ClassLoader.getSystemClassLoader().loadClass("org.jacoco.agent.rt.RT");
        Class<?> api = ClassLoader.getSystemClassLoader().loadClass("org.jacoco.agent.rt.IAgent");
        agent = rt.getMethod("getAgent").invoke(null);
        getData = api.getMethod("getExecutionData", boolean.class);
        setSession = api.getMethod("setSessionId", String.class);
    }

    /** Reads and resets the probes; caller is the main thread. */
    static void dump(String id, Map<String, Object> r) throws Exception {
        init();
        long t0 = System.nanoTime();
        setSession.invoke(agent, id);
        byte[] data = (byte[]) getData.invoke(agent, true);
        long ns = System.nanoTime() - t0;
        synchronized (dumps) {
            dumps.put(id, data);
        }
        r.put("covUs", ns / 1000.0);
        r.put("covBytes", data.length);
    }

    /** Runs on the socket thread so it may wait across ticks. */
    static Map<String, Object> waitAndDump(Map<String, String> q) throws Exception {
        String id = q.get("id");
        long t0 = System.nanoTime();
        Map<String, Object> r = new LinkedHashMap<>();
        if (q.containsKey("wait")) {
            CompletableFuture<Void> f = new CompletableFuture<>();
            Bukkit.getScheduler().runTaskLater(ProbeAccess.plugin(), () -> {
                try {
                    dump(id, r);
                    f.complete(null);
                } catch (Throwable e) {
                    f.completeExceptionally(e);
                }
            }, Long.parseLong(q.get("wait")));
            f.get(10, TimeUnit.SECONDS);
        } else {
            int polls = 0;
            long deadline = System.nanoTime() + 5_000_000_000L;
            while (true) {
                polls++;
                CompletableFuture<Boolean> f = new CompletableFuture<>();
                MinecraftServer.getServer().execute(() -> {
                    try {
                        if (busy() > 0) {
                            f.complete(false);
                            return;
                        }
                        dump(id, r);
                        f.complete(true);
                    } catch (Throwable e) {
                        f.completeExceptionally(e);
                    }
                });
                if (f.get(10, TimeUnit.SECONDS)) break;
                if (System.nanoTime() > deadline) {
                    r.put("quietTimeout", true);
                    dump(id, r);
                    break;
                }
                LockSupport.parkNanos(200_000);
            }
            r.put("polls", polls);
        }
        r.put("waitMs", (System.nanoTime() - t0) / 1e6);
        return r;
    }

    /** One shot tasks still pending plus async workers still running, for this plugin only. */
    static int busy() throws Exception {
        Plugin me = ProbeAccess.plugin();
        int n = 0;
        for (BukkitTask t : Bukkit.getScheduler().getPendingTasks()) {
            if (t.getOwner() == me && !t.isCancelled() && periodOf(t) <= 0) n++;
        }
        for (BukkitWorker w : Bukkit.getScheduler().getActiveWorkers()) {
            if (w.getOwner() == me) n++;
        }
        return n;
    }

    private static long periodOf(BukkitTask t) throws Exception {
        if (period == null) {
            Class<?> c = Class.forName("org.bukkit.craftbukkit.scheduler.CraftTask");
            period = c.getDeclaredMethod("getPeriod");
            period.setAccessible(true);
        }
        return (long) period.invoke(t);
    }

    static boolean run(String name, Map<String, String> q, Player p, Map<String, Object> r) throws Exception {
        switch (name) {
            case "tail" -> tail(p, q, r);
            case "covSave" -> {
                Path dir = Path.of(q.get("dir"));
                Files.createDirectories(dir);
                long bytes = 0;
                synchronized (dumps) {
                    for (var e : dumps.entrySet()) {
                        Files.write(dir.resolve(e.getKey() + ".exec"), e.getValue());
                        bytes += e.getValue().length;
                    }
                    r.put("saved", dumps.size());
                    dumps.clear();
                }
                r.put("bytes", bytes);
            }
            case "covBusy" -> r.put("busy", busy());
            default -> {
                return false;
            }
        }
        return true;
    }

    /** The visible effect comes first, the tail after it: one tick later, async, or on a raw pool. */
    private static void tail(Player p, Map<String, String> q, Map<String, Object> r) {
        String kind = q.get("kind");
        String token = q.get("token");
        long ms = Long.parseLong(q.getOrDefault("tailMs", "2"));
        r.put("sentMicros", micros());
        p.sendMessage(Component.text(token));
        switch (kind) {
            case "tailTick" -> Bukkit.getScheduler().runTaskLater(ProbeAccess.plugin(), () -> tailTick(token), 1);
            case "tailAsync" -> Bukkit.getScheduler().runTaskAsynchronously(ProbeAccess.plugin(), () -> {
                sleep(ms);
                tailAsync(token);
            });
            case "tailRaw" -> CompletableFuture.runAsync(() -> {
                sleep(ms);
                tailRaw(token);
            });
            default -> throw new IllegalArgumentException(kind);
        }
    }

    private static void tailTick(String token) {
        int n = token.length();
        sink = sink + n;
    }

    private static void tailAsync(String token) {
        int n = token.hashCode();
        sink = sink ^ n;
    }

    private static void tailRaw(String token) {
        int n = token.length() * 31;
        sink = sink - n;
    }

    private static void sleep(long ms) {
        LockSupport.parkNanos(ms * 1_000_000L);
    }

    private static long micros() {
        java.time.Instant now = java.time.Instant.now();
        return now.getEpochSecond() * 1_000_000L + now.getNano() / 1000;
    }
}
