package probe.plugin;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Random;
import net.kyori.adventure.bossbar.BossBar;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;
import net.kyori.adventure.title.Title;
import net.minecraft.network.protocol.game.ClientboundSetCameraPacket;
import org.bukkit.Bukkit;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.Particle;
import org.bukkit.World;
import org.bukkit.craftbukkit.entity.CraftEntity;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Entity;
import org.bukkit.entity.EntityType;
import org.bukkit.entity.Player;
import org.bukkit.entity.TextDisplay;
import org.bukkit.entity.Villager;
import org.bukkit.scheduler.BukkitTask;

/**
 * Video prototype, server side: the hard cases for a stepped demo recording, each driven tick by tick by
 * a Bukkit task so it follows stepped ticks exactly, each with a deliberately broken variant.
 *
 *   vd.set?player                    build the backdrop (grass, coloured pillars) and put the player at its foot
 *   vd.go?player&name&broken=0|1     start a case: camera|walk|title|particles|boss|typing
 *   vd.clear?player                  stop tasks, remove entities and bars, give the camera back
 */
final class VideoScenes {
    private static ProbePlugin plugin;
    private static final List<BukkitTask> tasks = new ArrayList<>();
    private static final List<Entity> spawned = new ArrayList<>();
    private static final List<BossBar> bars = new ArrayList<>();
    static final int Y = 64;

    private VideoScenes() {}

    static void start(ProbePlugin p) {
        plugin = p;
    }

    private static void every(int ticks, java.util.function.IntConsumer body) {
        int[] t = {0};
        BukkitTask[] self = new BukkitTask[1];
        self[0] = Bukkit.getScheduler().runTaskTimer(plugin, () -> {
            if (t[0] >= ticks) {
                self[0].cancel();
                return;
            }
            body.accept(t[0]++);
        }, 0, 1);
        tasks.add(self[0]);
    }

    static boolean run(String name, Map<String, String> q, Player p, Map<String, Object> r) {
        switch (name) {
            case "vd.set" -> set(p);
            case "vd.go" -> go(p, q.get("name"), "1".equals(q.get("broken")), r);
            case "vd.clear" -> clear(p);
            default -> {
                return false;
            }
        }
        return true;
    }

    /** Same blocks every time (seeded), so reruns start from the same world. */
    private static void set(Player p) {
        World w = p.getWorld();
        Random rnd = new Random(7);
        Material[] wool = {Material.RED_WOOL, Material.LIME_WOOL, Material.BLUE_WOOL, Material.YELLOW_WOOL, Material.MAGENTA_WOOL, Material.CYAN_WOOL};
        for (int x = -14; x <= 14; x++) {
            for (int z = -8; z <= 26; z++) {
                w.getBlockAt(x, Y - 1, z).setType(Material.GRASS_BLOCK, false);
                w.getBlockAt(x, Y - 2, z).setType(Material.DIRT, false);
                for (int h = 0; h < 6; h++) w.getBlockAt(x, Y + h, z).setType(Material.AIR, false);
            }
        }
        for (int i = 0; i < 60; i++) {
            int x = rnd.nextInt(29) - 14, z = rnd.nextInt(35) - 8;
            if (Math.abs(x) <= 5 && z >= 0 && z <= 12) continue; // keep the stage clear
            int h = 1 + rnd.nextInt(4);
            Material m = wool[rnd.nextInt(wool.length)];
            for (int k = 0; k < h; k++) w.getBlockAt(x, Y + k, z).setType(m, false);
        }
        // A back wall with a stripe pattern behind the stage, so motion has edges everywhere.
        for (int x = -10; x <= 10; x++) {
            for (int h = 0; h < 5; h++) w.getBlockAt(x, Y + h, 14).setType(((x + h) & 1) == 0 ? Material.WHITE_CONCRETE : Material.BLACK_CONCRETE, false);
        }
        home(p);
    }

    private static void home(Player p) {
        p.setGameMode(org.bukkit.GameMode.CREATIVE);
        p.setAllowFlight(true);
        p.setFlying(true);
        p.teleport(new Location(p.getWorld(), 0.5, Y + 0.6, 0.5, 0f, 8f));
    }

    private static void go(Player p, String name, boolean broken, Map<String, Object> r) {
        World w = p.getWorld();
        r.put("tick", net.minecraft.server.MinecraftServer.getServer().getTickCount()); // the step pings name ticks by this count
        switch (name) {
            case "camera" -> {
                // Typewriter's display camera: a text display with 10 ticks of position interpolation, teleported every
                // tick along the path, and the player's camera set to it. Orbit of radius 5 around the stage centre.
                double cx = 0.5, cz = 7.0, rad = 5.0;
                double step = broken ? 0.9 : 1.8; // degrees per tick; broken moves at half speed
                TextDisplay cam = (TextDisplay) w.spawnEntity(orbit(w, cx, cz, rad, 0), EntityType.TEXT_DISPLAY);
                cam.text(Component.empty());
                cam.setTeleportDuration(10);
                spawned.add(cam);
                p.setGameMode(org.bukkit.GameMode.SPECTATOR); // the local player model stays out of the shot
                ((CraftPlayer) p).getHandle().connection.send(new ClientboundSetCameraPacket(((CraftEntity) cam).getHandle()));
                every(120, t -> cam.teleport(orbit(w, cx, cz, rad, t * step)));
                r.put("id", cam.getEntityId());
            }
            case "walk" -> {
                Villager v = (Villager) w.spawnEntity(new Location(w, -4.5, Y, 6.5, -90f, 0f), EntityType.VILLAGER);
                v.setAI(false);
                v.setSilent(true);
                v.setGravity(false);
                v.customName(Component.text("Old Keeper"));
                v.setCustomNameVisible(true);
                spawned.add(v);
                double dir = broken ? -1 : 1; // broken walks away from its goal
                every(60, t -> v.teleport(new Location(w, -4.5 + dir * 0.15 * (t + 1), Y, 6.5, dir > 0 ? -90f : 90f, 0f)));
                r.put("id", v.getEntityId());
            }
            case "title" -> p.showTitle(Title.title(Component.text("The Journey Begins", NamedTextColor.GOLD), Component.text("Chapter One: Riverside"),
                Title.Times.times(Duration.ofMillis(500), Duration.ofMillis(broken ? 500 : 2000), Duration.ofMillis(1000))));
            case "particles" -> {
                if (!broken) {
                    every(60, t -> {
                        for (int k = 0; k < 8; k++) {
                            double a = Math.toRadians(k * 45 + t * 6);
                            w.spawnParticle(Particle.END_ROD, new Location(w, 0.5, Y + 1.5, 6.5), 0, Math.cos(a), 0.15, Math.sin(a), 0.12);
                        }
                    });
                }
            }
            case "boss" -> {
                BossBar b = BossBar.bossBar(Component.text("The Warden Awakens"), 0f, BossBar.Color.RED, BossBar.Overlay.PROGRESS);
                bars.add(b);
                p.showBossBar(b);
                float cap = broken ? 0.5f : 1f; // broken stalls at half
                every(100, t -> b.progress(Math.min(cap, (t + 1) / 100f)));
            }
            case "typing" -> {
                p.setOp(true);
                p.updateCommands();
            }
            default -> throw new IllegalArgumentException(name);
        }
    }

    /** Point on the orbit at the given angle, looking at the centre. */
    private static Location orbit(World w, double cx, double cz, double rad, double deg) {
        // deg 0: on the player's side of the stage, looking at +z. Minecraft yaw 0 looks +z, direction (-sin, cos).
        double a = Math.toRadians(deg);
        double x = cx + Math.sin(a) * rad, z = cz - Math.cos(a) * rad;
        Location l = new Location(w, x, Y + 2.2, z);
        l.setYaw((float) deg);
        l.setPitch(12f);
        return l;
    }

    private static void clear(Player p) {
        for (BukkitTask t : tasks) t.cancel();
        tasks.clear();
        ((CraftPlayer) p).getHandle().connection.send(new ClientboundSetCameraPacket(((CraftPlayer) p).getHandle()));
        for (Entity e : spawned) e.remove();
        spawned.clear();
        for (BossBar b : bars) p.hideBossBar(b);
        bars.clear();
        p.clearTitle();
        p.resetTitle();
        p.getInventory().clear();
        home(p);
    }
}
