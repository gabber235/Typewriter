package probe.plugin;

import java.time.Duration;
import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.Set;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.locks.LockSupport;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.title.Title;
import net.minecraft.network.protocol.common.ClientboundPingPacket;
import net.minecraft.server.MinecraftServer;
import org.bukkit.Bukkit;
import org.bukkit.GameMode;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.World;
import org.bukkit.block.Block;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Display;
import org.bukkit.entity.Player;
import org.bukkit.entity.TextDisplay;
import org.bukkit.scheduler.BukkitTask;
import org.bukkit.scheduler.BukkitWorker;
import org.bukkit.util.Transformation;
import org.joml.Quaternionf;
import org.joml.Vector3f;

/**
 * Spike E: lying timing scenes. Each scene sends its effect (now, later, async, under lag) and three
 * barriers on the player's connection: base+1 right after the command, base+2 after the declared
 * window in ticks, base+3 once this plugin has no task pending or running (quiet).
 */
final class Ready {
    private static final int Y = 64;
    static final int REGION_A = 4096, REGION_B = 8192;
    static final Set<Integer> harness = ConcurrentHashMap.newKeySet();
    private static final Map<String, Long> effectAt = new ConcurrentHashMap<>();
    private static final Map<String, Object[]> quietInfo = new ConcurrentHashMap<>();
    private static TextDisplay walker;
    private static Location fake;
    private static Block real;
    private static int region;

    private Ready() {}

    static boolean run(String name, Map<String, String> q, Player p, Map<String, Object> r) throws Exception {
        switch (name) {
            case "e.home" -> home(p, r);
            case "e.scene" -> scene(p, q, r);
            case "e.clean" -> clean(p, q, r);
            case "e.info" -> {
                String t = q.get("token");
                Long at = effectAt.remove(t);
                r.put("effectMicros", at == null ? -1 : at);
                Object[] qi = quietInfo.remove(t);
                if (qi != null) {
                    r.put("quietMicros", qi[0]);
                    r.put("quietPolls", qi[1]);
                    r.put("quietTimeout", qi[2]);
                }
            }
            case "e.busy" -> r.put("busy", busy());
            case "e.calm" -> {
                // Every world, not only the main one: a running day clock moves the sky colour in every frame.
                int n = 0;
                for (World w : Bukkit.getWorlds()) {
                    for (String rule : new String[] {"minecraft:advance_time false", "minecraft:advance_weather false"}) {
                        Bukkit.dispatchCommand(Bukkit.getConsoleSender(), "execute in " + w.getKey() + " run gamerule " + rule);
                    }
                    try {
                        w.setTime(6000);
                    } catch (IllegalArgumentException e) {
                        r.put("noClock" + n, w.getKey().toString());
                    }
                    w.setStorm(false);
                    w.setThundering(false);
                    n++;
                }
                r.put("worlds", n);
            }
            default -> {
                return false;
            }
        }
        return true;
    }

    static void platform(World w, int cx, int cz) {
        for (int x = -8; x <= 8; x++) for (int z = -8; z <= 8; z++) {
            Block b = w.getBlockAt(cx + x, Y, cz + z);
            if (b.getType() != Material.STONE) b.setType(Material.STONE, false);
        }
    }

    private static void home(Player p, Map<String, Object> r) {
        World w = p.getWorld();
        platform(w, 0, 0);
        platform(w, REGION_A, 0);
        platform(w, REGION_B, 0);
        p.setGameMode(GameMode.CREATIVE);
        p.setFlying(false);
        p.getInventory().clear();
        p.teleport(new Location(w, 0.5, Y + 1, 0.5, 0f, 0f));
        region = 0;
        r.put("ok", true);
    }

    private static void ping(Player p, int id) {
        ((CraftPlayer) p).getHandle().connection.send(new ClientboundPingPacket(id));
    }

    private static void effectChat(Player p, String token) {
        effectAt.put(token, micros());
        p.sendMessage(Component.text(token));
    }

    private static void scene(Player p, Map<String, String> q, Map<String, Object> r) {
        String kind = q.get("kind"), token = q.get("token");
        boolean broken = "1".equals(q.get("broken"));
        int base = Integer.parseInt(q.get("base"));
        int window = Integer.parseInt(q.get("w"));
        long lagMs = Long.parseLong(q.getOrDefault("lagMs", "0"));
        Plugin plugin = new Plugin();
        r.put("sentMicros", micros());
        r.put("serverTick", Bukkit.getCurrentTick());
        World w = p.getWorld();
        switch (kind) {
            case "now", "clientlag" -> {
                if (!broken) effectChat(p, token);
            }
            case "late1" -> {
                if (!broken) plugin.later(() -> effectChat(p, token), 1);
            }
            case "late2" -> {
                if (!broken) plugin.later(() -> plugin.later(() -> effectChat(p, token), 1), 1);
            }
            case "async" -> {
                if (!broken) Bukkit.getScheduler().runTaskAsynchronously(ProbeAccess.plugin(), () -> {
                    sleep(ThreadLocalRandom.current().nextLong(0, 20));
                    effectChat(p, token);
                });
            }
            case "serverlag" -> {
                if (!broken) plugin.later(() -> effectChat(p, token), 1);
                sleep(lagMs);
            }
            case "section" -> {
                // A 2x2x2 fake cube in an empty section two chunks ahead: the client holds it at once and meshes it later.
                Material m = Material.valueOf(q.get("material"));
                fake = new Location(w, 0, 66, 18);
                if (!broken) {
                    effectAt.put(token, micros());
                    for (int x = -1; x <= 0; x++) for (int y = 66; y <= 67; y++) for (int z = 18; z <= 19; z++)
                        p.sendBlockChange(new Location(w, x, y, z), m.createBlockData());
                }
            }
            case "walk" -> {
                // Spawned outside the view cone to the left, then one block per tick into the middle.
                Location start = new Location(w, -13.5, 66, 6.5, 180f, 0f);
                walker = w.spawn(start, TextDisplay.class, e -> {
                    e.text(Component.text(broken ? "hidden" : token));
                    e.customName(Component.text(token));
                    e.setCustomNameVisible(false);
                    e.setPersistent(false);
                    e.setBillboard(Display.Billboard.FIXED);
                    e.setRotation(180f, 0f);
                    e.setBackgroundColor(org.bukkit.Color.fromARGB(255, 200, 30, 30));
                    e.setTransformation(new Transformation(new Vector3f(), new Quaternionf(), new Vector3f(4, 4, 4), new Quaternionf()));
                    e.setTeleportDuration(1);
                });
                effectAt.put(token, micros());
                if (!broken) {
                    TextDisplay me = walker;
                    int[] n = {0};
                    BukkitTask[] task = new BukkitTask[1];
                    task[0] = Bukkit.getScheduler().runTaskTimer(ProbeAccess.plugin(), () -> {
                        n[0]++;
                        me.teleport(start.clone().add(n[0], 0, 0));
                        if (n[0] >= 13) task[0].cancel();
                    }, 1L, 1L);
                } else {
                    // Broken: it never comes in.
                }
            }
            case "chunk" -> {
                // Move far away, then a real block next to the player in a chunk the client does not hold yet.
                region = region == REGION_A ? REGION_B : REGION_A;
                Material m = Material.valueOf(q.get("material"));
                p.teleport(new Location(w, region + 0.5, Y + 1, 0.5, 0f, 0f));
                real = w.getBlockAt(region + 2, Y + 1, 2);
                if (!broken) {
                    effectAt.put(token, micros());
                    real.setType(m, false);
                }
                r.put("region", region);
            }
            case "title" -> {
                if (!broken) {
                    effectAt.put(token, micros());
                    p.showTitle(Title.title(Component.text(token), Component.empty(),
                        Title.Times.times(Duration.ofMillis(500), Duration.ofMillis(3000), Duration.ZERO)));
                }
            }
            default -> throw new IllegalArgumentException(kind);
        }
        ping(p, base + 1);
        BukkitTask wt = Bukkit.getScheduler().runTaskLater(ProbeAccess.plugin(), () -> ping(p, base + 2), window);
        harness.add(wt.getTaskId());
        quiet(p, base + 3, token);
    }

    /** Polls between ticks until this plugin is quiet, then sends the barrier. */
    private static void quiet(Player p, int id, String token) {
        Thread t = new Thread(() -> {
            long t0 = micros();
            int polls = 0;
            boolean timeout = false;
            long deadline = System.nanoTime() + 10_000_000_000L;
            while (true) {
                polls++;
                CompletableFuture<Boolean> f = new CompletableFuture<>();
                MinecraftServer.getServer().execute(() -> {
                    try {
                        if (busy() > 0) {
                            f.complete(false);
                            return;
                        }
                        ping(p, id);
                        f.complete(true);
                    } catch (Throwable e) {
                        f.completeExceptionally(e);
                    }
                });
                try {
                    if (f.get(20, TimeUnit.SECONDS)) break;
                } catch (Exception e) {
                    break;
                }
                if (System.nanoTime() > deadline) {
                    timeout = true;
                    MinecraftServer.getServer().execute(() -> ping(p, id));
                    break;
                }
                LockSupport.parkNanos(200_000);
            }
            quietInfo.put(token, new Object[] {micros() - t0, polls, timeout});
        }, "probe-quiet");
        t.setDaemon(true);
        t.start();
    }

    /** Every task of this plugin that is not cancelled (one shot or repeating) plus running async workers, minus harness pings. */
    static int busy() {
        org.bukkit.plugin.Plugin me = ProbeAccess.plugin();
        int n = 0;
        Set<Integer> live = new HashSet<>();
        for (BukkitTask t : Bukkit.getScheduler().getPendingTasks()) {
            if (t.getOwner() != me || t.isCancelled()) continue;
            live.add(t.getTaskId());
            if (!harness.contains(t.getTaskId())) n++;
        }
        harness.retainAll(live);
        for (BukkitWorker wk : Bukkit.getScheduler().getActiveWorkers()) if (wk.getOwner() == me) n++;
        return n;
    }

    private static void clean(Player p, Map<String, String> q, Map<String, Object> r) {
        String kind = q.get("kind");
        p.resetTitle();
        if (walker != null) {
            walker.remove();
            walker = null;
        }
        if (fake != null) {
            World w = p.getWorld();
            for (int x = -1; x <= 0; x++) for (int y = 66; y <= 67; y++) for (int z = 18; z <= 19; z++) {
                Location at = new Location(w, x, y, z);
                p.sendBlockChange(at, at.getBlock().getBlockData());
            }
            fake = null;
        }
        if (real != null) {
            real.setType(Material.AIR, false);
            real = null;
        }
        if ("home".equals(q.get("to"))) {
            p.teleport(new Location(p.getWorld(), 0.5, Y + 1, 0.5, 0f, 0f));
            region = 0;
        }
        r.put("busy", busy());
    }

    /** One shot tasks on the main thread, all counted by busy(). */
    private static final class Plugin {
        void later(Runnable r, long ticks) {
            Bukkit.getScheduler().runTaskLater(ProbeAccess.plugin(), r, ticks);
        }
    }

    /** Thread.sleep, not parkNanos: a thread that was unparked before returns from parkNanos at once. */
    private static void sleep(long ms) {
        try {
            Thread.sleep(ms);
        } catch (InterruptedException e) {
            Thread.currentThread().interrupt();
        }
    }

    private static long micros() {
        java.time.Instant now = java.time.Instant.now();
        return now.getEpochSecond() * 1_000_000L + now.getNano() / 1000;
    }
}
