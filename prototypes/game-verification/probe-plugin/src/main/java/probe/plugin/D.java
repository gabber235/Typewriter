package probe.plugin;

import java.time.Duration;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.ConcurrentHashMap;
import java.util.concurrent.ThreadLocalRandom;
import java.util.concurrent.TimeUnit;
import java.util.concurrent.atomic.AtomicInteger;
import java.util.concurrent.locks.LockSupport;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.title.Title;
import net.minecraft.network.protocol.common.ClientboundPingPacket;
import net.minecraft.network.protocol.game.ClientboundAddEntityPacket;
import net.minecraft.network.protocol.game.ClientboundRemoveEntitiesPacket;
import net.minecraft.network.protocol.game.ClientboundSetEntityDataPacket;
import net.minecraft.server.MinecraftServer;
import net.minecraft.world.phys.Vec3;
import org.bukkit.Bukkit;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.Particle;
import org.bukkit.Sound;
import org.bukkit.SoundCategory;
import org.bukkit.WeatherType;
import org.bukkit.World;
import org.bukkit.boss.BarColor;
import org.bukkit.boss.BarStyle;
import org.bukkit.boss.BossBar;
import org.bukkit.craftbukkit.CraftWorld;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Player;
import org.bukkit.entity.TextDisplay;
import org.bukkit.scheduler.BukkitTask;
import org.bukkit.scoreboard.DisplaySlot;
import org.bukkit.scoreboard.Objective;
import org.bukkit.scoreboard.Scoreboard;

/**
 * Spike D: one requirement per call for any number of players on one Paper, plus leaky
 * requirements that reach other players. Every requirement sends its effect and a window barrier
 * after w ticks (E3t). Done (E6) is asked separately with d.quiet, scoped to the whole server
 * (what E and I built) or to one player (a per player rule the framework could hold).
 *
 *   d.req?player&kind&token&w&broken&wping[&material&late&asyncMs&lagMs&scope=world|player]
 *   d.quiet?player&scope=server|player&qping
 * (not "ping": the line handler sends a ping for that parameter right after the command)
 *   d.reset?player
 */
final class D {
    private static final Map<Integer, UUID> taskOwner = new ConcurrentHashMap<>();
    private static final Map<UUID, AtomicInteger> asyncRunning = new ConcurrentHashMap<>();
    private static final Map<UUID, Leftovers> left = new HashMap<>();
    private static final Map<Integer, long[]> quietInfo = new ConcurrentHashMap<>();
    private static final int NIGHT = 18000;

    /** What one player's requirements left behind, cleared by d.reset. */
    private static final class Leftovers {
        final List<Integer> packetEntities = new ArrayList<>();
        final List<Location> fakeBlocks = new ArrayList<>();
        final List<TextDisplay> worldEntities = new ArrayList<>();
        final List<BossBar> bars = new ArrayList<>();
        Objective objective;
        boolean worldTime, worldStorm, playerTime, playerWeather, ownBoard;
    }

    private D() {}

    static boolean run(String name, Map<String, String> q, Player p, Map<String, Object> r) throws Exception {
        switch (name) {
            case "d.req" -> req(p, q, r);
            case "d.quiet" -> quiet(p, q.getOrDefault("scope", "server"), Integer.parseInt(q.get("qping")));
            case "d.qinfo" -> {
                long[] v = quietInfo.remove(Integer.parseInt(q.get("qping")));
                r.put("quietMicros", v == null ? -1 : v[0]);
                r.put("polls", v == null ? -1 : v[1]);
            }
            case "d.reset" -> reset(p);
            case "d.busy" -> {
                r.put("server", Ready.busy());
                r.put("player", playerBusy(p.getUniqueId()));
            }
            default -> {
                return false;
            }
        }
        return true;
    }

    private static Leftovers of(Player p) {
        return left.computeIfAbsent(p.getUniqueId(), id -> new Leftovers());
    }

    private static void ping(Player p, int id) {
        ((CraftPlayer) p).getHandle().connection.send(new ClientboundPingPacket(id));
    }

    private static void later(Player p, Runnable run, long ticks) {
        BukkitTask t = Bukkit.getScheduler().runTaskLater(ProbeAccess.plugin(), run, ticks);
        taskOwner.put(t.getTaskId(), p.getUniqueId());
    }

    private static void async(Player p, long ms, Runnable then) {
        AtomicInteger n = asyncRunning.computeIfAbsent(p.getUniqueId(), id -> new AtomicInteger());
        n.incrementAndGet();
        Bukkit.getScheduler().runTaskAsynchronously(ProbeAccess.plugin(), () -> {
            try {
                sleep(ms);
                if (then != null) then.run();
            } finally {
                n.decrementAndGet();
            }
        });
    }

    private static void req(Player p, Map<String, String> q, Map<String, Object> r) {
        String kind = q.get("kind"), token = q.get("token");
        boolean broken = "1".equals(q.get("broken"));
        boolean world = !"player".equals(q.getOrDefault("scope", "world"));
        int w = Integer.parseInt(q.get("w"));
        int id = Integer.parseInt(q.get("wping"));
        r.put("serverTick", Bukkit.getCurrentTick());
        Leftovers lo = of(p);
        Location base = p.getLocation();
        World wd = p.getWorld();
        if (!broken) switch (kind) {
            case "title" -> p.showTitle(title(token));
            case "chat" -> p.sendMessage(Component.text(token));
            case "block" -> {
                Location at = new Location(wd, base.getBlockX() + 2, base.getBlockY(), base.getBlockZ() + 2);
                p.sendBlockChange(at, Material.valueOf(q.get("material")).createBlockData());
                lo.fakeBlocks.add(at);
            }
            case "entity" -> lo.packetEntities.add(packetEntity(p, base.clone().add(0, 1.5, 3), token));
            case "late" -> later(p, () -> p.sendMessage(Component.text(token)), Integer.parseInt(q.get("late")));
            case "async" -> async(p, Long.parseLong(q.getOrDefault("asyncMs", String.valueOf(ThreadLocalRandom.current().nextLong(0, 20)))),
                () -> p.sendMessage(Component.text(token)));
            // Leaky kinds: world=1 uses the world wide API, world=0 its per player counterpart.
            case "bcast" -> {
                if (world) Bukkit.broadcast(Component.text(token));
                else p.sendMessage(Component.text(token));
            }
            case "titleall" -> {
                if (world) for (Player o : Bukkit.getOnlinePlayers()) o.showTitle(title(token));
                else p.showTitle(title(token));
            }
            case "time" -> {
                if (world) {
                    wd.setTime(NIGHT);
                    lo.worldTime = true;
                } else {
                    p.setPlayerTime(NIGHT, false);
                    lo.playerTime = true;
                }
            }
            case "weather" -> {
                if (world) {
                    wd.setStorm(true);
                    lo.worldStorm = true;
                } else {
                    p.setPlayerWeather(WeatherType.DOWNFALL);
                    lo.playerWeather = true;
                }
            }
            case "boss" -> {
                BossBar bar = Bukkit.createBossBar(token, BarColor.RED, BarStyle.SOLID);
                if (world) for (Player o : Bukkit.getOnlinePlayers()) bar.addPlayer(o);
                else bar.addPlayer(p);
                lo.bars.add(bar);
            }
            case "sidebar" -> {
                Scoreboard board;
                if (world) board = Bukkit.getScoreboardManager().getMainScoreboard();
                else {
                    board = Bukkit.getScoreboardManager().getNewScoreboard();
                    p.setScoreboard(board);
                    lo.ownBoard = true;
                }
                Objective o = board.registerNewObjective("d" + Math.abs(token.hashCode() % 100000), org.bukkit.scoreboard.Criteria.DUMMY, Component.text(token));
                o.setDisplaySlot(DisplaySlot.SIDEBAR);
                o.getScore("line").setScore(1);
                lo.objective = o;
            }
            case "wentity" -> {
                Location at = base.clone().add(0, 1.5, 3);
                at.setYaw(180f);
                TextDisplay e = wd.spawn(at, TextDisplay.class, d -> {
                    d.text(Component.text(token));
                    d.customName(Component.text(token));
                    d.setPersistent(false);
                    if (!world) d.setVisibleByDefault(false);
                });
                if (!world) p.showEntity(ProbeAccess.plugin(), e);
                lo.worldEntities.add(e);
            }
            case "sound" -> {
                // Volume 2 is heard up to 32 blocks: the next region at 16 blocks hears it.
                Location at = base.clone().add(0, 1, 2);
                float vol = Float.parseFloat(q.getOrDefault("vol", "2"));
                if (world) wd.playSound(at, Sound.BLOCK_NOTE_BLOCK_PLING, SoundCategory.RECORDS, vol, 1f);
                else p.playSound(at, Sound.BLOCK_NOTE_BLOCK_PLING, SoundCategory.RECORDS, vol, 1f);
            }
            case "particle" -> {
                Location at = base.clone().add(0, 1.5, 3);
                if (world) wd.spawnParticle(Particle.HAPPY_VILLAGER, at, 40, 1, 1, 1, 0);
                else p.spawnParticle(Particle.HAPPY_VILLAGER, at, 40, 1, 1, 1, 0);
            }
            case "lag" -> sleep(Long.parseLong(q.getOrDefault("lagMs", "400")));
            case "slowasync" -> async(p, Long.parseLong(q.getOrDefault("asyncMs", "300")), null);
            case "none" -> {}
            default -> throw new IllegalArgumentException(kind);
        }
        BukkitTask wt = Bukkit.getScheduler().runTaskLater(ProbeAccess.plugin(), () -> ping(p, id), w);
        Ready.harness.add(wt.getTaskId());
    }

    private static Title title(String token) {
        return Title.title(Component.text(token), Component.empty(), Title.Times.times(Duration.ofMillis(50), Duration.ofMillis(5000), Duration.ofMillis(50)));
    }

    private static int packetEntity(Player p, Location at, String token) {
        var fake = new net.minecraft.world.entity.Display.TextDisplay(net.minecraft.world.entity.EntityTypes.TEXT_DISPLAY, ((CraftWorld) p.getWorld()).getHandle());
        fake.setPos(at.getX(), at.getY(), at.getZ());
        fake.setText(net.minecraft.network.chat.Component.literal(token));
        fake.setCustomName(net.minecraft.network.chat.Component.literal(token));
        int id = fake.getId();
        var connection = ((CraftPlayer) p).getHandle().connection;
        connection.send(new ClientboundAddEntityPacket(id, UUID.randomUUID(), at.getX(), at.getY(), at.getZ(), 0f, 180f,
            net.minecraft.world.entity.EntityTypes.TEXT_DISPLAY, 0, Vec3.ZERO, 0));
        connection.send(new ClientboundSetEntityDataPacket(id, fake.getEntityData().packAll()));
        return id;
    }

    /** Pending tasks this player's requirements scheduled, plus its async work still running. */
    static int playerBusy(UUID id) {
        Set<Integer> live = new HashSet<>();
        int n = 0;
        for (BukkitTask t : Bukkit.getScheduler().getPendingTasks()) {
            if (t.isCancelled()) continue;
            live.add(t.getTaskId());
            if (id.equals(taskOwner.get(t.getTaskId()))) n++;
        }
        taskOwner.keySet().retainAll(live);
        AtomicInteger a = asyncRunning.get(id);
        return n + (a == null ? 0 : a.get());
    }

    /** Ready.quiet with a scope: polls between ticks until the scope is idle, then sends the barrier. */
    private static void quiet(Player p, String scope, int id) {
        UUID who = p.getUniqueId();
        boolean server = "server".equals(scope);
        Thread t = new Thread(() -> {
            long t0 = micros();
            int polls = 0;
            long deadline = System.nanoTime() + 20_000_000_000L;
            while (true) {
                polls++;
                CompletableFuture<Boolean> f = new CompletableFuture<>();
                MinecraftServer.getServer().execute(() -> {
                    try {
                        if ((server ? Ready.busy() : playerBusy(who)) > 0) {
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
                    MinecraftServer.getServer().execute(() -> ping(p, id));
                    break;
                }
                LockSupport.parkNanos(200_000);
            }
            quietInfo.put(id, new long[] {micros() - t0, polls});
        }, "probe-d-quiet");
        t.setDaemon(true);
        t.start();
    }

    private static void reset(Player p) {
        Leftovers lo = of(p);
        p.resetTitle();
        var connection = ((CraftPlayer) p).getHandle().connection;
        if (!lo.packetEntities.isEmpty()) {
            connection.send(new ClientboundRemoveEntitiesPacket(lo.packetEntities.stream().mapToInt(i -> i).toArray()));
            lo.packetEntities.clear();
        }
        for (Location at : lo.fakeBlocks) if (at.getWorld() == p.getWorld()) p.sendBlockChange(at, at.getBlock().getBlockData());
        lo.fakeBlocks.clear();
        for (TextDisplay e : lo.worldEntities) e.remove();
        lo.worldEntities.clear();
        for (BossBar b : lo.bars) b.removeAll();
        lo.bars.clear();
        if (lo.objective != null) {
            lo.objective.unregister();
            lo.objective = null;
        }
        if (lo.ownBoard) {
            p.setScoreboard(Bukkit.getScoreboardManager().getMainScoreboard());
            lo.ownBoard = false;
        }
        if (lo.worldTime) {
            p.getWorld().setTime(6000);
            lo.worldTime = false;
        }
        if (lo.worldStorm) {
            p.getWorld().setStorm(false);
            lo.worldStorm = false;
        }
        if (lo.playerTime) {
            p.resetPlayerTime();
            lo.playerTime = false;
        }
        if (lo.playerWeather) {
            p.resetPlayerWeather();
            lo.playerWeather = false;
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
