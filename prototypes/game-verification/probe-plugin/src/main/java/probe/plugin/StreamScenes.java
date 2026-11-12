package probe.plugin;

import com.destroystokyo.paper.event.server.ServerTickEndEvent;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Random;
import net.kyori.adventure.bossbar.BossBar;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.NamedTextColor;
import net.kyori.adventure.title.Title;
import net.minecraft.network.protocol.common.ClientboundPingPacket;
import org.bukkit.Bukkit;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.World;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Display;
import org.bukkit.entity.Entity;
import org.bukkit.entity.EntityType;
import org.bukkit.entity.Player;
import org.bukkit.entity.TextDisplay;
import org.bukkit.entity.Villager;
import org.bukkit.event.EventHandler;
import org.bukkit.event.Listener;
import org.bukkit.scheduler.BukkitTask;
import org.bukkit.scoreboard.DisplaySlot;
import org.bukkit.scoreboard.Objective;
import org.bukkit.scoreboard.Scoreboard;

/**
 * Stream prototype, server side: the busiest perception scenes, driven tick by tick by Bukkit tasks so
 * they follow stepped ticks, plus tick end timestamps and barrier sends for the latency join.
 *
 *   st.scn?player&name=actionbar|title|chat|boss|walk|tags   start a scene (main thread, between ticks)
 *   st.stim?player&kind=chat|bar|title|boss|display&token     one typical requirement's stimulus
 *   st.clear?player                                           remove everything the scenes made
 *   st.barrier?player&id                                      vanilla ping below 2^30; returns the send time
 *   st.ticks                                                  tick end nanoTimes since the last call
 */
final class StreamScenes implements Listener {
    private static ProbePlugin plugin;
    private static final List<long[]> tickLog = new ArrayList<>();
    private static final List<BukkitTask> tasks = new ArrayList<>();
    private static final List<Entity> spawned = new ArrayList<>();
    private static final List<BossBar> bars = new ArrayList<>();
    private static final Random rnd = new Random(7);

    private StreamScenes() {}

    static void start(ProbePlugin p) {
        plugin = p;
        Bukkit.getPluginManager().registerEvents(new StreamScenes(), p);
    }

    @EventHandler
    public void onTickEnd(ServerTickEndEvent e) {
        synchronized (tickLog) {
            if (tickLog.size() < 200_000) tickLog.add(new long[] {e.getTickNumber(), System.nanoTime()});
        }
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
            case "st.scn" -> scene(p, q.get("name"), r);
            case "st.stim" -> stim(p, q.get("kind"), q.get("token"), r);
            case "st.clear" -> clear(p);
            case "st.op" -> {
                p.setOp(true);
                p.updateCommands();
            }
            case "st.barrier" -> {
                int id = Integer.parseInt(q.get("id"));
                long t = System.nanoTime();
                ((CraftPlayer) p).getHandle().connection.send(new ClientboundPingPacket(id));
                r.put("sentNanos", t);
            }
            case "st.ticks" -> {
                List<Long> ticks = new ArrayList<>(), nanos = new ArrayList<>();
                synchronized (tickLog) {
                    for (long[] v : tickLog) {
                        ticks.add(v[0]);
                        nanos.add(v[1]);
                    }
                    tickLog.clear();
                }
                r.put("ticks", ticks);
                r.put("nanos", nanos);
            }
            default -> {
                return false;
            }
        }
        return true;
    }

    private static void scene(Player p, String name, Map<String, Object> r) {
        switch (name) {
            case "actionbar" -> every(100, t -> {
                // Ours: Typewriter keeps its bar alive by sending it every other tick.
                if (t % 2 == 0) p.sendActionBar(Component.text("Gather 3 of 5 moonpetals", NamedTextColor.GOLD));
                // Another plugin's bar on its own rhythm, with a changing value.
                if (t % 5 == 0) p.sendActionBar(Component.text("Mana " + (100 - t / 5) + "/100", NamedTextColor.AQUA));
            });
            case "title" -> p.showTitle(Title.title(Component.text("The Journey Begins", NamedTextColor.GOLD), Component.text("Chapter One: Riverside"),
                Title.Times.times(Duration.ofMillis(500), Duration.ofMillis(2000), Duration.ofMillis(1000))));
            case "chat" -> {
                for (int i = 1; i <= 20; i++) p.sendMessage(Component.text("[Keeper] Line " + i + " of the old tale: the river remembers every step."));
            }
            case "boss" -> {
                BossBar b = BossBar.bossBar(Component.text("The Warden Awakens"), 0f, BossBar.Color.RED, BossBar.Overlay.PROGRESS);
                bars.add(b);
                p.showBossBar(b);
                every(100, t -> b.progress(Math.min(1f, (t + 1) / 100f)));
            }
            case "walk" -> walk(p, r);
            case "tags" -> {
                Scoreboard sb = Bukkit.getScoreboardManager().getNewScoreboard();
                Objective o = sb.registerNewObjective("quest", org.bukkit.scoreboard.Criteria.DUMMY, Component.text("Quest Log"));
                o.setDisplaySlot(DisplaySlot.SIDEBAR);
                o.getScore("Find the keeper").setScore(2);
                o.getScore("Cross the river").setScore(1);
                p.setScoreboard(sb);
            }
            default -> throw new IllegalArgumentException(name);
        }
    }

    /** Terrain with bumps, a named villager and a text display ahead of the player (facing +z). */
    private static void walk(Player p, Map<String, Object> r) {
        World w = p.getWorld();
        int y = 64;
        for (int x = -12; x <= 12; x++) {
            for (int z = -6; z <= 24; z++) {
                w.getBlockAt(x, y - 1, z).setType(Material.GRASS_BLOCK, false);
                w.getBlockAt(x, y - 2, z).setType(Material.DIRT, false);
                for (int h = 0; h < 4; h++) w.getBlockAt(x, y + h, z).setType(Material.AIR, false);
            }
        }
        for (int i = 0; i < 40; i++) {
            int x = rnd.nextInt(25) - 12, z = rnd.nextInt(31) - 6;
            if (Math.abs(x) <= 2) continue; // keep the path along x = 0 clear
            int h = 1 + rnd.nextInt(2);
            for (int k = 0; k < h; k++) w.getBlockAt(x, y + k, z).setType(rnd.nextBoolean() ? Material.STONE : Material.OAK_LEAVES, false);
        }
        w.getBlockAt(1, y, 9).setType(Material.OAK_LOG, false);
        w.getBlockAt(-1, y, 9).setType(Material.LANTERN, false);
        p.setFlying(false);
        p.teleport(new Location(w, 0.5, y, 0.5, 0f, 0f));
        Villager v = (Villager) w.spawnEntity(new Location(w, 1.5, y, 9.5, 180f, 0f), EntityType.VILLAGER);
        v.setAI(false);
        v.setSilent(true);
        v.customName(Component.text("Old Keeper"));
        v.setCustomNameVisible(true);
        spawned.add(v);
        TextDisplay d = (TextDisplay) w.spawnEntity(new Location(w, -1.5, y + 2, 10.5), EntityType.TEXT_DISPLAY);
        d.text(Component.text("Welcome to Riverside"));
        d.setBillboard(Display.Billboard.CENTER);
        spawned.add(d);
        r.put("villager", v.getEntityId());
        r.put("display", d.getEntityId());
        r.put("blocks", "1:" + y + ":9,-1:" + y + ":9");
    }

    private static void stim(Player p, String kind, String token, Map<String, Object> r) {
        switch (kind) {
            case "chat" -> p.sendMessage(Component.text("Keeper: " + token));
            case "bar" -> p.sendActionBar(Component.text("Objective " + token));
            case "title" -> p.showTitle(Title.title(Component.text(token), Component.empty(),
                Title.Times.times(Duration.ofMillis(100), Duration.ofMillis(200), Duration.ofMillis(100))));
            case "boss" -> {
                BossBar b = BossBar.bossBar(Component.text("Boss " + token), 1f, BossBar.Color.PURPLE, BossBar.Overlay.PROGRESS);
                bars.add(b);
                p.showBossBar(b);
            }
            case "display" -> {
                Location l = p.getLocation().clone().add(p.getLocation().getDirection().multiply(4)).add(0, 1.5, 0);
                TextDisplay d = (TextDisplay) p.getWorld().spawnEntity(l, EntityType.TEXT_DISPLAY);
                d.text(Component.text(token));
                d.setBillboard(Display.Billboard.CENTER);
                spawned.add(d);
                r.put("id", d.getEntityId());
            }
            default -> throw new IllegalArgumentException(kind);
        }
    }

    private static void clear(Player p) {
        for (BukkitTask t : tasks) t.cancel();
        tasks.clear();
        for (Entity e : spawned) e.remove();
        spawned.clear();
        for (BossBar b : bars) p.hideBossBar(b);
        bars.clear();
        p.clearTitle();
        p.sendActionBar(Component.empty());
        p.setScoreboard(Bukkit.getScoreboardManager().getMainScoreboard());
    }
}
