package probe.plugin;

import io.papermc.paper.entity.TeleportFlag;
import java.io.BufferedReader;
import java.io.File;
import java.io.IOException;
import java.io.InputStreamReader;
import java.io.OutputStream;
import java.net.InetAddress;
import java.net.ServerSocket;
import java.net.Socket;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Random;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.CompletableFuture;
import java.util.concurrent.TimeUnit;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.title.Title;
import net.minecraft.network.protocol.common.ClientboundPingPacket;
import net.minecraft.network.protocol.game.ClientboundAddEntityPacket;
import net.minecraft.network.protocol.game.ClientboundRemoveEntitiesPacket;
import net.minecraft.network.protocol.game.ClientboundSetEntityDataPacket;
import net.minecraft.server.MinecraftServer;
import net.minecraft.world.entity.Display;
import net.minecraft.world.phys.Vec3;
import org.bukkit.Bukkit;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.World;
import org.bukkit.WorldCreator;
import org.bukkit.block.Block;
import org.bukkit.craftbukkit.CraftWorld;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Entity;
import org.bukkit.entity.Player;
import org.bukkit.entity.TextDisplay;
import org.bukkit.generator.ChunkGenerator;
import org.bukkit.inventory.ItemStack;
import org.bukkit.potion.PotionEffect;
import org.bukkit.potion.PotionEffectType;
import org.bukkit.scheduler.BukkitTask;
import org.bukkit.util.Transformation;
import org.bukkit.util.Vector;

/**
 * Spike C commands over a raw line socket. Request "dispatch/name?k=v&k=v", dispatch is
 * tick (Bukkit scheduler, runs at the next tick start) or direct (MinecraftServer.execute, runs
 * between ticks as soon as the main thread is idle). Reply: one JSON line.
 */
final class Speed {
    private static final int Y = 64;
    private static ProbePlugin plugin;
    private static final Map<UUID, List<Integer>> packetEntities = new HashMap<>();
    private static final Map<UUID, List<Location>> fakeBlocks = new HashMap<>();
    private static final List<Entity> realEntities = new ArrayList<>();
    private static final List<World> pool = new ArrayList<>();
    private static World current;
    private static BukkitTask mover;

    static void start(ProbePlugin p) {
        plugin = p;
        int port = Integer.getInteger("probe.line.port", 0);
        if (port == 0) return;
        Thread t = new Thread(() -> {
            try (ServerSocket server = new ServerSocket(port, 8, InetAddress.getLoopbackAddress())) {
                while (true) {
                    Socket s = server.accept();
                    s.setTcpNoDelay(true);
                    Thread c = new Thread(() -> serve(s), "probe-line-conn");
                    c.setDaemon(true);
                    c.start();
                }
            } catch (IOException e) {
                e.printStackTrace();
            }
        }, "probe-line");
        t.setDaemon(true);
        t.start();
    }

    private static void serve(Socket s) {
        try (s; BufferedReader in = new BufferedReader(new InputStreamReader(s.getInputStream(), StandardCharsets.UTF_8));
             OutputStream out = s.getOutputStream()) {
            String line;
            while ((line = in.readLine()) != null) {
                String reply;
                try {
                    reply = handle(line);
                } catch (Throwable e) {
                    Throwable c = e.getCause() == null ? e : e.getCause();
                    reply = "{\"error\":\"" + String.valueOf(c).replace("\\", "/").replace("\"", "'").replace("\n", " ") + "\"}";
                }
                out.write((reply + "\n").getBytes(StandardCharsets.UTF_8));
                out.flush();
            }
        } catch (IOException ignored) {
        }
    }

    private static String handle(String line) throws Exception {
        int slash = line.indexOf('/');
        String dispatch = line.substring(0, slash);
        String rest = line.substring(slash + 1);
        int qm = rest.indexOf('?');
        String name = qm < 0 ? rest : rest.substring(0, qm);
        Map<String, String> q = query(qm < 0 ? "" : rest.substring(qm + 1));
        Callable<Map<String, Object>> call = () -> run(name, q);
        Map<String, Object> result;
        if (dispatch.equals("direct")) {
            CompletableFuture<Map<String, Object>> f = new CompletableFuture<>();
            MinecraftServer.getServer().execute(() -> {
                try {
                    f.complete(call.call());
                } catch (Throwable t) {
                    f.completeExceptionally(t);
                }
            });
            result = f.get(60, TimeUnit.SECONDS);
        } else {
            result = Bukkit.getScheduler().callSyncMethod(plugin, call).get(60, TimeUnit.SECONDS);
        }
        return json(result);
    }

    private static Map<String, Object> run(String name, Map<String, String> q) throws Exception {
        Map<String, Object> r = new LinkedHashMap<>();
        Player p = q.containsKey("player") ? Bukkit.getPlayerExact(q.get("player")) : null;
        switch (name) {
            case "noop" -> {}
            case "act" -> {
                int late = Integer.parseInt(q.getOrDefault("lateTicks", "0"));
                if (late > 0) {
                    r.put("sentMicros", micros());
                    Bukkit.getScheduler().runTaskLater(plugin, () -> act(p, q, new LinkedHashMap<>()), late);
                } else {
                    act(p, q, r);
                }
            }
            case "reset" -> reset(p, q);
            case "region" -> region(p, q, r);
            case "worldNew" -> worldNew(p, q, r);
            case "poolInit" -> poolInit(q, r);
            case "poolSwap" -> poolSwap(p, q, r);
            case "dirty" -> dirty(p, q);
            case "tickrate" -> {
                Bukkit.getServerTickManager().setTickRate(Float.parseFloat(q.get("rate")));
                r.put("rate", Bukkit.getServerTickManager().getTickRate());
            }
            case "time" -> {
                Bukkit.dispatchCommand(Bukkit.getConsoleSender(), "gamerule minecraft:advance_time false");
                Bukkit.getWorlds().get(0).setTime(6000);
            }
            case "status" -> {
                r.put("tps", Bukkit.getTPS()[0]);
                r.put("rate", Bukkit.getServerTickManager().getTickRate());
                r.put("mspt", Bukkit.getAverageTickTime());
                r.put("tick", Bukkit.getCurrentTick());
                r.put("worlds", Bukkit.getWorlds().size());
                r.put("online", Bukkit.getOnlinePlayers().size());
            }
            case "moveDisplay" -> moveDisplay(p, q, r);
            case "moveTick" -> moveTick(p, q, r);
            case "title" -> {
                Title title = Title.title(Component.text(q.get("text")), Component.text(q.getOrDefault("sub", "")),
                        Title.Times.times(ticks(q, "in"), ticks(q, "stay"), ticks(q, "out")));
                r.put("sentMicros", micros());
                p.showTitle(title);
            }
            default -> throw new IllegalArgumentException("unknown " + name);
        }
        if (q.containsKey("ping") && p != null) {
            ((CraftPlayer) p).getHandle().connection.send(new ClientboundPingPacket(Integer.parseInt(q.get("ping"))));
        }
        return r;
    }

    private static Duration ticks(Map<String, String> q, String key) {
        return Duration.ofMillis(50L * Integer.parseInt(q.get(key)));
    }

    /** Shows one thing near the player; broken=1 shows nothing. */
    private static void act(Player p, Map<String, String> q, Map<String, Object> r) {
        String kind = q.get("kind");
        String token = q.get("token");
        boolean broken = "1".equals(q.get("broken"));
        r.put("sentMicros", micros());
        if (broken) return;
        Location base = p.getLocation();
        switch (kind) {
            case "title" -> p.showTitle(Title.title(Component.text(token), Component.empty(),
                    Title.Times.times(Duration.ofMillis(50), Duration.ofMillis(5000), Duration.ofMillis(50))));
            case "chat" -> p.sendMessage(Component.text(token));
            case "block" -> {
                Location at = new Location(p.getWorld(), base.getBlockX() + 2, base.getBlockY(), base.getBlockZ() + 2);
                p.sendBlockChange(at, Material.valueOf(q.get("material")).createBlockData());
                fakesOf(fakeBlocks, p).add(at);
            }
            case "entity" -> {
                Location at = base.clone().add(0, 1.5, 3);
                Display.TextDisplay fake = new Display.TextDisplay(net.minecraft.world.entity.EntityTypes.TEXT_DISPLAY, ((CraftWorld) p.getWorld()).getHandle());
                fake.setPos(at.getX(), at.getY(), at.getZ());
                fake.setText(net.minecraft.network.chat.Component.literal(token));
                fake.setCustomName(net.minecraft.network.chat.Component.literal(token));
                int id = fake.getId();
                var add = new ClientboundAddEntityPacket(id, UUID.randomUUID(), at.getX(), at.getY(), at.getZ(), 0f, 180f,
                        net.minecraft.world.entity.EntityTypes.TEXT_DISPLAY, 0, Vec3.ZERO, 0);
                var data = new ClientboundSetEntityDataPacket(id, fake.getEntityData().packAll());
                var connection = ((CraftPlayer) p).getHandle().connection;
                connection.send(add);
                connection.send(data);
                fakesOf(packetEntities, p).add(id);
            }
            default -> throw new IllegalArgumentException(kind);
        }
    }

    /** Sends clear packets for whatever earlier commands showed; full=1 also clears player state. */
    private static void reset(Player p, Map<String, String> q) {
        p.resetTitle();
        p.sendActionBar(Component.empty());
        var connection = ((CraftPlayer) p).getHandle().connection;
        List<Integer> entities = fakesOf(packetEntities, p);
        if (!entities.isEmpty()) {
            connection.send(new ClientboundRemoveEntitiesPacket(entities.stream().mapToInt(i -> i).toArray()));
            entities.clear();
        }
        List<Location> blocks = fakesOf(fakeBlocks, p);
        for (Location at : blocks) {
            if (at.isWorldLoaded() && at.getWorld() == p.getWorld()) p.sendBlockChange(at, at.getBlock().getBlockData());
        }
        blocks.clear();
        if ("1".equals(q.get("full"))) cleanPlayer(p);
    }

    private static <T> List<T> fakesOf(Map<UUID, List<T>> byPlayer, Player p) {
        return byPlayer.computeIfAbsent(p.getUniqueId(), id -> new ArrayList<>());
    }

    private static void cleanPlayer(Player p) {
        p.clearActivePotionEffects();
        p.setVelocity(new Vector());
        p.setFireTicks(0);
        p.getInventory().clear();
        for (Entity e : realEntities) e.remove();
        realEntities.clear();
    }

    /** Leaves one of every leftover kind behind. */
    private static void dirty(Player p, Map<String, String> q) {
        p.showTitle(Title.title(Component.text("DIRTY-title"), Component.text("DIRTY-sub"), Title.Times.times(Duration.ofMillis(50), Duration.ofMillis(5000), Duration.ofMillis(2000))));
        p.sendActionBar(Component.text("DIRTY-bar"));
        p.sendMessage(Component.text("DIRTY-chat"));
        p.addPotionEffect(new PotionEffect(PotionEffectType.SPEED, 2000, 1));
        p.setFireTicks(2000);
        p.setVelocity(new Vector(0.6, 0.2, 0));
        p.getInventory().addItem(new ItemStack(Material.DIAMOND, 3));
        Location base = p.getLocation();
        Location blockAt = new Location(p.getWorld(), base.getBlockX() + 2, base.getBlockY(), base.getBlockZ() + 2);
        p.sendBlockChange(blockAt, Material.GOLD_BLOCK.createBlockData());
        fakesOf(fakeBlocks, p).add(blockAt);
        Location fake = base.clone().add(1, 1.5, 3);
        Display.TextDisplay d = new Display.TextDisplay(net.minecraft.world.entity.EntityTypes.TEXT_DISPLAY, ((CraftWorld) p.getWorld()).getHandle());
        d.setPos(fake.getX(), fake.getY(), fake.getZ());
        d.setText(net.minecraft.network.chat.Component.literal("DIRTY-packet"));
        d.setCustomName(net.minecraft.network.chat.Component.literal("DIRTY-packet"));
        var connection = ((CraftPlayer) p).getHandle().connection;
        connection.send(new ClientboundAddEntityPacket(d.getId(), UUID.randomUUID(), fake.getX(), fake.getY(), fake.getZ(), 0f, 180f,
                net.minecraft.world.entity.EntityTypes.TEXT_DISPLAY, 0, Vec3.ZERO, 0));
        connection.send(new ClientboundSetEntityDataPacket(d.getId(), d.getEntityData().packAll()));
        fakesOf(packetEntities, p).add(d.getId());
        TextDisplay real = p.getWorld().spawn(base.clone().add(-1, 1.5, 3), TextDisplay.class, e -> {
            e.text(Component.text("DIRTY-real"));
            e.customName(Component.text("DIRTY-real"));
            e.setPersistent(false);
        });
        realEntities.add(real);
    }

    private static void platform(World world, int cx, int cz) {
        for (int x = -8; x <= 8; x++) {
            for (int z = -8; z <= 8; z++) {
                Block b = world.getBlockAt(cx + x, Y, cz + z);
                if (b.getType() != Material.STONE) b.setType(Material.STONE, false);
            }
        }
    }

    /** R1: same world, a region 64 chunks apart. pooled=N reuses N prebuilt regions. */
    private static void region(Player p, Map<String, String> q, Map<String, Object> r) {
        int idx = Integer.parseInt(q.get("idx"));
        int spacing = Integer.parseInt(q.getOrDefault("chunks", "64")) * 16;
        int x = (idx + 1) * spacing;
        long t0 = System.nanoTime();
        World w = p.getWorld();
        platform(w, x, 0);
        r.put("platformMs", (System.nanoTime() - t0) / 1_000_000.0);
        p.teleport(new Location(w, x + 0.5, Y + 1, 0.5, 0f, 0f));
        r.put("cx", x >> 4);
        r.put("cz", 0);
        r.put("dim", w.getKey().toString());
    }

    private static World newVoid(String name) {
        WorldCreator c = new WorldCreator(name).generator(new ChunkGenerator() {}).generateStructures(false).keepSpawnLoaded(net.kyori.adventure.util.TriState.FALSE);
        World w = c.createWorld();
        
        return w;
    }

    /** R2: a new void world, player moves in, the previous one unloads and its folder goes. */
    private static void worldNew(Player p, Map<String, String> q, Map<String, Object> r) throws IOException {
        long t0 = System.nanoTime();
        World w = newVoid("gen" + q.get("idx"));
        long t1 = System.nanoTime();
        platform(w, 0, 0);
        long t2 = System.nanoTime();
        World old = p.getWorld();
        p.teleport(new Location(w, 0.5, Y + 1, 0.5, 0f, 0f));
        long t3 = System.nanoTime();
        if (old != Bukkit.getWorlds().get(0)) {
            File folder = old.getWorldFolder();
            Bukkit.unloadWorld(old, false);
            Bukkit.getScheduler().runTaskAsynchronously(plugin, () -> deleteTree(folder.toPath()));
        }
        long t4 = System.nanoTime();
        r.put("createMs", (t1 - t0) / 1e6);
        r.put("platformMs", (t2 - t1) / 1e6);
        r.put("teleportMs", (t3 - t2) / 1e6);
        r.put("unloadMs", (t4 - t3) / 1e6);
        r.put("dim", w.getKey().toString());
        r.put("cx", 0);
        r.put("cz", 0);
    }

    private static void poolInit(Map<String, String> q, Map<String, Object> r) {
        int n = Integer.parseInt(q.getOrDefault("n", "8"));
        long t0 = System.nanoTime();
        for (int i = 0; i < n; i++) {
            World w = newVoid("pool" + i);
            platform(w, 0, 0);
            for (int x = -3; x <= 3; x++) for (int z = -3; z <= 3; z++) w.setChunkForceLoaded(x, z, true);
            pool.add(w);
        }
        r.put("initMs", (System.nanoTime() - t0) / 1e6);
    }

    /** R3: swap player between preloaded void worlds. */
    private static void poolSwap(Player p, Map<String, String> q, Map<String, Object> r) {
        World w = pool.get(Integer.parseInt(q.get("idx")) % pool.size());
        p.teleport(new Location(w, 0.5, Y + 1, 0.5, 0f, 0f));
        r.put("dim", w.getKey().toString());
        r.put("cx", 0);
        r.put("cz", 0);
    }

    /** C2: one TextDisplay teleported with a client side interpolation of `duration` ticks. */
    private static void moveDisplay(Player p, Map<String, String> q, Map<String, Object> r) {
        int duration = Integer.parseInt(q.get("duration"));
        String token = q.get("token");
        Location base = p.getLocation().clone().add(0, 1.5, 4);
        base.setYaw(180);
        TextDisplay real = p.getWorld().spawn(base, TextDisplay.class, e -> {
            e.text(Component.text(token));
            e.customName(Component.text(token));
            e.setPersistent(false);
            e.setTeleportDuration(duration);
        });
        realEntities.add(real);
        int distance = Integer.parseInt(q.get("distance"));
        Bukkit.getScheduler().runTaskLater(plugin, () -> {
            r.put("moved", micros());
            real.teleport(base.clone().add(distance, 0, 0));
        }, Integer.parseInt(q.getOrDefault("after", "10")));
        r.put("sentMicros", micros());
        r.put("baseX", base.getX());
    }

    /** C2: Typewriter style tick driven camera path, one teleport per server tick. */
    private static void moveTick(Player p, Map<String, String> q, Map<String, Object> r) {
        int total = Integer.parseInt(q.get("ticks"));
        String token = q.get("token");
        Location base = p.getLocation().clone().add(0, 1.5, 4);
        base.setYaw(180);
        TextDisplay real = p.getWorld().spawn(base, TextDisplay.class, e -> {
            e.text(Component.text(token));
            e.customName(Component.text(token));
            e.setPersistent(false);
            e.setTeleportDuration(1);
        });
        realEntities.add(real);
        int[] n = {0};
        mover = Bukkit.getScheduler().runTaskTimer(plugin, () -> {
            n[0]++;
            real.teleport(base.clone().add(n[0] * 0.25, 0, 0));
            if (n[0] >= total) mover.cancel();
        }, 1L, 1L);
        r.put("sentMicros", micros());
        r.put("baseX", base.getX());
    }

    private static void deleteTree(Path path) {
        try (var walk = Files.walk(path)) {
            walk.sorted(Comparator.reverseOrder()).forEach(x -> x.toFile().delete());
        } catch (IOException ignored) {
        }
    }

    private static long micros() {
        Instant now = Instant.now();
        return now.getEpochSecond() * 1_000_000L + now.getNano() / 1000;
    }

    private static Map<String, String> query(String raw) {
        Map<String, String> out = new HashMap<>();
        for (String pair : raw.split("&")) {
            int eq = pair.indexOf('=');
            if (eq > 0) out.put(pair.substring(0, eq), URLDecoder.decode(pair.substring(eq + 1), StandardCharsets.UTF_8));
        }
        return out;
    }

    private static String json(Map<String, Object> m) {
        StringBuilder b = new StringBuilder("{");
        boolean first = true;
        for (var e : m.entrySet()) {
            if (!first) b.append(',');
            first = false;
            b.append('"').append(e.getKey()).append("\":");
            Object v = e.getValue();
            if (v instanceof Number || v instanceof Boolean) b.append(v);
            else b.append('"').append(String.valueOf(v).replace("\"", "'")).append('"');
        }
        return b.append('}').toString();
    }
}
