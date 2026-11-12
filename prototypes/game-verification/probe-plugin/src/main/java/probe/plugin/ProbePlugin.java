package probe.plugin;

import com.sun.net.httpserver.HttpExchange;
import com.sun.net.httpserver.HttpServer;
import java.io.IOException;
import java.net.InetSocketAddress;
import java.net.URLDecoder;
import java.nio.charset.StandardCharsets;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Locale;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.Callable;
import java.util.concurrent.TimeUnit;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.title.Title;
import net.minecraft.network.protocol.game.ClientboundAddEntityPacket;
import net.minecraft.network.protocol.game.ClientboundRemoveEntitiesPacket;
import net.minecraft.network.protocol.game.ClientboundSetEntityDataPacket;
import net.minecraft.world.entity.Display;
import net.minecraft.world.phys.Vec3;
import org.bukkit.Bukkit;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.World;
import org.bukkit.craftbukkit.CraftWorld;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Player;
import org.bukkit.entity.TextDisplay;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.plugin.java.JavaPlugin;

/**
 * Throwaway scene driver. Control channel: HTTP on localhost, port from -Dprobe.control.port.
 * Every command runs on the main thread and replies with JSON holding sentMicros, the epoch
 * microseconds taken right before the Paper call that sends the packet.
 *
 *   GET /status                                    players, tps, join events
 *   GET /cmd/title?player=P&text=T&sub=S&in=10&stay=40&out=10   (ticks)
 *   GET /cmd/chat?player=P&text=T
 *   GET /cmd/actionbar?player=P&text=T
 *   GET /cmd/block?player=P&x=&y=&z=&material=DIAMOND_BLOCK
 *   GET /cmd/packetEntity?player=P&text=T&x=&y=&z=    packet only TextDisplay (never in the world)
 *   GET /cmd/hiddenEntity?player=P&text=T&x=&y=&z=    real TextDisplay shown to P only
 *   GET /cmd/stop                                  Bukkit.shutdown()
 */
public final class ProbePlugin extends JavaPlugin implements Listener {
    private static final int PLATFORM_Y = 64;
    private final List<Map<String, Object>> joins = new ArrayList<>();
    private HttpServer http;

    @Override
    public void onEnable() {
        startWatchdog();
        World world = Bukkit.getWorlds().get(0);
        buildPlatform(world);
        Bukkit.getPluginManager().registerEvents(this, this);
        int port = Integer.getInteger("probe.control.port", 0);
        try {
            http = HttpServer.create(new InetSocketAddress("127.0.0.1", port), 0);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        http.createContext("/status", ex -> reply(ex, 200, onMain(this::status)));
        http.createContext("/cmd/", this::command);
        http.start();
        Speed.start(this);
        Input.start(this);
        K.start(this);
        N.start(this);
        StreamScenes.start(this);
        VideoScenes.start(this);
        getLogger().info("probe control on " + http.getAddress().getPort());
    }

    @Override
    public void onDisable() {
        if (http != null) http.stop(0);
        K.stop();
    }

    private void startWatchdog() {
        long max = Long.getLong("probe.maxRuntimeSec", 900);
        Thread t = new Thread(() -> {
            try {
                Thread.sleep(TimeUnit.SECONDS.toMillis(max));
            } catch (InterruptedException e) {
                return;
            }
            System.err.println("probe watchdog: halting server after " + max + " s");
            Runtime.getRuntime().halt(99);
        }, "probe-watchdog");
        t.setDaemon(true);
        t.start();
    }

    private void buildPlatform(World world) {
        for (int x = -8; x <= 8; x++) {
            for (int z = -8; z <= 8; z++) {
                world.getBlockAt(x, PLATFORM_Y, z).setType(Material.STONE, false);
            }
        }
        world.setSpawnLocation(0, PLATFORM_Y + 1, 0);
    }

    @EventHandler
    public void onJoin(PlayerJoinEvent event) {
        Player p = event.getPlayer();
        Location spot = new Location(p.getWorld(), 0.5, PLATFORM_Y + 1, 0.5, 0f, 0f);
        p.teleport(spot);
        p.setGameMode(org.bukkit.GameMode.CREATIVE);
        p.setAllowFlight(true);
        p.setFlying(true);
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("player", p.getName());
        m.put("atMicros", micros());
        joins.add(m);
    }

    private Map<String, Object> status() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("players", Bukkit.getOnlinePlayers().stream().map(Player::getName).toList());
        m.put("tps", Bukkit.getTPS()[0]);
        m.put("joins", new ArrayList<>(joins));
        m.put("nowMicros", micros());
        List<String> names = new ArrayList<>();
        for (org.bukkit.entity.Entity e : Bukkit.getWorlds().get(0).getEntities()) {
            if (e instanceof TextDisplay d) names.add(net.kyori.adventure.text.serializer.plain.PlainTextComponentSerializer.plainText().serialize(d.text()));
        }
        m.put("worldTextDisplays", names);
        return m;
    }

    private void command(HttpExchange ex) throws IOException {
        String name = ex.getRequestURI().getPath().substring("/cmd/".length());
        Map<String, String> q = query(ex.getRequestURI().getRawQuery());
        Map<String, Object> result;
        try {
            result = onMain(() -> run(name, q));
        } catch (RuntimeException e) {
            reply(ex, 500, Map.of("error", String.valueOf(e)));
            return;
        }
        reply(ex, 200, result);
    }

    private Map<String, Object> run(String name, Map<String, String> q) {
        Map<String, Object> r = new LinkedHashMap<>();
        r.put("cmd", name);
        if (name.equals("stop")) {
            Bukkit.getScheduler().runTask(this, Bukkit::shutdown);
            return r;
        }
        Player p = Bukkit.getPlayerExact(q.get("player"));
        if (p == null) throw new IllegalArgumentException("no player " + q.get("player"));
        String text = q.getOrDefault("text", "");
        switch (name) {
            case "title" -> {
                Title title = Title.title(Component.text(text), Component.text(q.getOrDefault("sub", "")),
                        Title.Times.times(ticks(q, "in", 10), ticks(q, "stay", 40), ticks(q, "out", 10)));
                r.put("sentMicros", micros());
                p.showTitle(title);
            }
            case "chat" -> {
                r.put("sentMicros", micros());
                p.sendMessage(Component.text(text));
            }
            case "actionbar" -> {
                r.put("sentMicros", micros());
                p.sendActionBar(Component.text(text));
            }
            case "block" -> {
                Location at = loc(p, q);
                Material material = Material.valueOf(q.getOrDefault("material", "DIAMOND_BLOCK").toUpperCase(Locale.ROOT));
                r.put("serverBlock", at.getBlock().getType().name());
                r.put("sentMicros", micros());
                p.sendBlockChange(at, material.createBlockData());
            }
            case "packetEntity" -> {
                Location at = loc(p, q);
                Display.TextDisplay fake = new Display.TextDisplay(net.minecraft.world.entity.EntityTypes.TEXT_DISPLAY, ((CraftWorld) p.getWorld()).getHandle());
                fake.setPos(at.getX(), at.getY(), at.getZ());
                fake.setText(net.minecraft.network.chat.Component.literal(text));
                fake.setCustomName(net.minecraft.network.chat.Component.literal(text));
                int id = fake.getId();
                r.put("entityId", id);
                var add = new ClientboundAddEntityPacket(id, UUID.randomUUID(), at.getX(), at.getY(), at.getZ(), 0f, 180f,
                        net.minecraft.world.entity.EntityTypes.TEXT_DISPLAY, 0, Vec3.ZERO, 0);
                var data = new ClientboundSetEntityDataPacket(id, fake.getEntityData().packAll());
                var connection = ((CraftPlayer) p).getHandle().connection;
                r.put("sentMicros", micros());
                connection.send(add);
                connection.send(data);
            }
            case "hiddenEntity" -> {
                Location at = loc(p, q);
                at.setYaw(180f);
                r.put("sentMicros", micros());
                TextDisplay real = p.getWorld().spawn(at, TextDisplay.class, e -> {
                    e.text(Component.text(text));
                    e.customName(Component.text(text));
                    e.setVisibleByDefault(false);
                    e.setPersistent(false);
                });
                p.showEntity(this, real);
                r.put("entityId", real.getEntityId());
            }
            case "removeEntity" -> {
                r.put("sentMicros", micros());
                ((CraftPlayer) p).getHandle().connection.send(new ClientboundRemoveEntitiesPacket(Integer.parseInt(q.get("id"))));
            }
            default -> throw new IllegalArgumentException("unknown command " + name);
        }
        return r;
    }

    private static Duration ticks(Map<String, String> q, String key, int fallback) {
        return Duration.ofMillis(50L * Integer.parseInt(q.getOrDefault(key, String.valueOf(fallback))));
    }

    private static Location loc(Player p, Map<String, String> q) {
        return new Location(p.getWorld(), Double.parseDouble(q.get("x")), Double.parseDouble(q.get("y")), Double.parseDouble(q.get("z")));
    }

    private <T> T onMain(Callable<T> call) {
        try {
            return Bukkit.getScheduler().callSyncMethod(this, call).get(30, TimeUnit.SECONDS);
        } catch (Exception e) {
            throw new RuntimeException(e);
        }
    }

    private static long micros() {
        Instant now = Instant.now();
        return now.getEpochSecond() * 1_000_000L + now.getNano() / 1000;
    }

    private static Map<String, String> query(String raw) {
        Map<String, String> out = new HashMap<>();
        if (raw == null) return out;
        for (String pair : raw.split("&")) {
            int eq = pair.indexOf('=');
            if (eq > 0) {
                out.put(pair.substring(0, eq), URLDecoder.decode(pair.substring(eq + 1), StandardCharsets.UTF_8));
            }
        }
        return out;
    }

    private static void reply(HttpExchange ex, int code, Map<String, Object> body) throws IOException {
        byte[] bytes = json(body).getBytes(StandardCharsets.UTF_8);
        ex.getResponseHeaders().set("Content-Type", "application/json");
        ex.sendResponseHeaders(code, bytes.length);
        ex.getResponseBody().write(bytes);
        ex.close();
    }

    private static String json(Object v) {
        if (v instanceof Map<?, ?> m) {
            StringBuilder b = new StringBuilder("{");
            boolean first = true;
            for (var e : m.entrySet()) {
                if (!first) b.append(',');
                first = false;
                b.append(json(String.valueOf(e.getKey()))).append(':').append(json(e.getValue()));
            }
            return b.append('}').toString();
        }
        if (v instanceof List<?> l) {
            StringBuilder b = new StringBuilder("[");
            for (int i = 0; i < l.size(); i++) {
                if (i > 0) b.append(',');
                b.append(json(l.get(i)));
            }
            return b.append(']').toString();
        }
        if (v instanceof Number || v instanceof Boolean) return String.valueOf(v);
        if (v == null) return "null";
        return '"' + v.toString().replace("\\", "\\\\").replace("\"", "\\\"").replace("\n", "\\n") + '"';
    }
}
