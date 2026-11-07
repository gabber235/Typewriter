package probe.plugin;

import java.io.IOException;
import java.io.Reader;
import java.io.Writer;
import java.lang.management.ManagementFactory;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.time.Instant;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Properties;
import java.util.UUID;
import java.util.stream.Stream;
import net.kyori.adventure.bossbar.BossBar;
import net.kyori.adventure.text.Component;
import org.bukkit.Bukkit;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.NamespacedKey;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.HandlerList;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerJoinEvent;
import org.bukkit.event.player.PlayerQuitEvent;
import org.bukkit.inventory.ItemStack;
import org.bukkit.metadata.FixedMetadataValue;
import org.bukkit.permissions.PermissionAttachment;
import org.bukkit.persistence.PersistentDataType;
import org.bukkit.potion.PotionEffect;
import org.bukkit.potion.PotionEffectType;
import org.bukkit.scoreboard.Scoreboard;
import org.bukkit.scoreboard.Team;

/**
 * Spike K: imitates per player state a Typewriter plugin keeps, so a warm client's leftovers can be counted.
 *
 * Stored (survives a restart): plugins/ProbePlugin/k/store/UUID.properties (value, owed and given reward,
 * stored permission), plugins/ProbePlugin/k/mail/UUID.txt (delivered at join). Memory (gone with the process or
 * a plugin reload): sessions with a quit grace and their chat history (replayed on a rejoin within the grace),
 * holds with a removal grace (adopted when started again within it), permission attachments, boss bars.
 * Paper's own per player state: inventory, effects, position, xp, ender chest, persistent data container,
 * player time, metadata, scoreboard team (by name).
 *
 *   k.cfg  graceTicks holdGrace saveOnReward deleteMail persistSessions   (kept in a file, survives restarts)
 *   k.req  tok          reads every kind (one chat line KREQ), then writes every kind with tok
 *   k.wipe scope=naive|full   clears what the framework knows about this player
 *   k.owe  tok          reward owed; given at once when online, else at the next join
 *   k.reload            disable and enable this plugin (direct dispatch only)
 *   k.files             per player files on disk, heap, map sizes
 */
final class K implements Listener {
    static final String[] KINDS = {"stored", "history", "session", "hold", "team", "perm", "sperm", "inv", "eff", "pos", "xp", "mail",
            "pdc", "ptime", "ender", "boss", "meta"};
    static K live;

    final ProbePlugin plugin;
    final Path dir;
    final Properties cfg = new Properties();
    final Map<UUID, Properties> store = new HashMap<>();
    final Map<UUID, Sess> sessions = new HashMap<>();
    final Map<UUID, Hold> holds = new HashMap<>();
    final Map<UUID, PermissionAttachment> perms = new HashMap<>();
    final Map<UUID, BossBar> bars = new HashMap<>();
    final NamespacedKey pdcKey;

    static final class Sess {
        final String name;
        long graceUntil = -1;
        boolean resumed;
        final List<String> history = new ArrayList<>();

        Sess(String name) {
            this.name = name;
        }
    }

    record Hold(String token, int taskId) {}

    private K(ProbePlugin plugin) {
        this.plugin = plugin;
        this.dir = plugin.getDataFolder().toPath().resolve("k");
        this.pdcKey = new NamespacedKey(plugin, "k");
        try {
            Files.createDirectories(dir.resolve("store"));
            Files.createDirectories(dir.resolve("mail"));
            Path c = dir.resolve("cfg.properties");
            if (Files.exists(c)) try (Reader r = Files.newBufferedReader(c)) {
                cfg.load(r);
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        if (bool("persistSessions")) loadSessions();
    }

    /** Called from onEnable; a reload makes a new instance, so every memory map starts empty. */
    static void start(ProbePlugin p) {
        live = new K(p);
        Bukkit.getPluginManager().registerEvents(live, p);
        Bukkit.getScheduler().runTaskTimer(p, live::expire, 20, 20);
        for (Player pl : Bukkit.getOnlinePlayers()) live.load(pl.getUniqueId());
    }

    static void stop() {
        if (live != null) {
            HandlerList.unregisterAll(live);
            for (BossBar b : live.bars.values()) for (Player pl : Bukkit.getOnlinePlayers()) pl.hideBossBar(b);
            for (PermissionAttachment a : live.perms.values()) a.remove();
        }
        live = null;
    }

    boolean bool(String key) {
        return "1".equals(cfg.getProperty(key, "0"));
    }

    int integer(String key, int def) {
        return Integer.parseInt(cfg.getProperty(key, String.valueOf(def)));
    }

    // ---------- stored ----------

    Path storeFile(UUID u) {
        return dir.resolve("store").resolve(u + ".properties");
    }

    Properties load(UUID u) {
        Properties p = new Properties();
        Path f = storeFile(u);
        if (Files.exists(f)) try (Reader r = Files.newBufferedReader(f)) {
            p.load(r);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        store.put(u, p);
        return p;
    }

    Properties stored(UUID u) {
        Properties p = store.get(u);
        return p != null ? p : load(u);
    }

    void save(UUID u) {
        Properties p = stored(u);
        try (Writer w = Files.newBufferedWriter(storeFile(u))) {
            p.store(w, null);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    Path mailFile(UUID u) {
        return dir.resolve("mail").resolve(u + ".txt");
    }

    void loadSessions() {
        Path f = dir.resolve("sessions.txt");
        if (!Files.exists(f)) return;
        try {
            for (String line : Files.readAllLines(f)) {
                if (line.isBlank()) continue;
                Sess s = new Sess(line.substring(37));
                s.graceUntil = Bukkit.getCurrentTick() + integer("graceTicks", 100);
                sessions.put(UUID.fromString(line.substring(0, 36)), s);
            }
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    void saveSessions() {
        if (!bool("persistSessions")) return;
        StringBuilder b = new StringBuilder();
        sessions.forEach((u, s) -> b.append(u).append(' ').append(s.name).append('\n'));
        try {
            Files.writeString(dir.resolve("sessions.txt"), b);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
    }

    // ---------- join and quit ----------

    @EventHandler
    public void onJoin(PlayerJoinEvent e) {
        Player p = e.getPlayer();
        UUID u = p.getUniqueId();
        load(u);
        long tick = Bukkit.getCurrentTick();
        Sess s = sessions.get(u);
        boolean resumed = s != null && s.graceUntil >= tick;
        if (!resumed) {
            s = new Sess(p.getName());
            sessions.put(u, s);
        }
        s.graceUntil = -1;
        s.resumed = resumed;
        saveSessions();
        say(p, "KJOIN " + p.getName() + " resumed=" + (resumed ? 1 : 0) + " hist=" + s.history.size());
        for (String h : s.history) say(p, h);
        Path mail = mailFile(u);
        if (Files.exists(mail)) {
            try {
                for (String line : Files.readAllLines(mail)) if (!line.isBlank()) say(p, "KMAIL " + line);
                if (!bool("keepMail")) Files.delete(mail);
            } catch (IOException ex) {
                throw new RuntimeException(ex);
            }
        }
        giveOwed(p);
    }

    @EventHandler
    public void onQuit(PlayerQuitEvent e) {
        UUID u = e.getPlayer().getUniqueId();
        Sess s = sessions.get(u);
        if (s != null) s.graceUntil = Bukkit.getCurrentTick() + integer("graceTicks", 100);
        store.remove(u);
        perms.remove(u);
        BossBar b = bars.remove(u);
        if (b != null) e.getPlayer().hideBossBar(b);
    }

    void expire() {
        long tick = Bukkit.getCurrentTick();
        boolean changed = sessions.values().removeIf(s -> s.graceUntil >= 0 && s.graceUntil < tick);
        if (changed) saveSessions();
    }

    void say(Player p, String line) {
        p.sendMessage(Component.text(line));
    }

    void giveOwed(Player p) {
        Properties st = stored(p.getUniqueId());
        String owed = st.getProperty("owed");
        if (owed == null || owed.equals(st.getProperty("given"))) return;
        ItemStack item = new ItemStack(Material.DIAMOND);
        item.editMeta(m -> m.customName(Component.text("R" + owed)));
        p.getInventory().addItem(item);
        st.setProperty("given", owed);
        save(p.getUniqueId());
        if (bool("saveOnReward")) p.saveData();
        say(p, "KGIVEN " + owed);
    }

    // ---------- commands ----------

    static boolean run(String name, Map<String, String> q, Player p, Map<String, Object> r) throws Exception {
        if (!name.startsWith("k.")) return false;
        K k = live;
        switch (name) {
            case "k.cfg" -> {
                for (String key : List.of("graceTicks", "holdGrace", "saveOnReward", "keepMail", "persistSessions"))
                    if (q.containsKey(key)) k.cfg.setProperty(key, q.get(key));
                try (Writer w = Files.newBufferedWriter(k.dir.resolve("cfg.properties"))) {
                    k.cfg.store(w, null);
                }
                r.put("cfg", new LinkedHashMap<>(k.cfg));
            }
            case "k.req" -> k.req(p, q.get("tok"), r);
            case "k.wipe" -> {
                long t0 = System.nanoTime();
                k.wipe(p, q.getOrDefault("scope", "full"));
                r.put("wipeUs", (System.nanoTime() - t0) / 1000);
            }
            case "k.owe" -> {
                UUID u = p != null ? p.getUniqueId() : UUID.fromString(q.get("uuid"));
                k.stored(u).setProperty("owed", q.get("tok"));
                k.save(u);
                if (p != null) k.giveOwed(p);
            }
            case "k.reload" -> {
                long t0 = System.nanoTime();
                var pm = Bukkit.getPluginManager();
                pm.disablePlugin(k.plugin);
                pm.enablePlugin(k.plugin);
                r.put("reloadUs", (System.nanoTime() - t0) / 1000);
                r.put("same", live != k ? 0 : 1);
            }
            case "k.files" -> k.files(r);
            case "k.wset" -> {
                // Restore prototype: a value in the overworld's data (level.dat), saved only when asked.
                org.bukkit.World w = Bukkit.getWorlds().get(0);
                w.getPersistentDataContainer().set(k.pdcKey, PersistentDataType.STRING, q.get("tok"));
                if ("1".equals(q.get("save"))) w.save();
            }
            case "k.wget" -> r.put("tok", Bukkit.getWorlds().get(0).getPersistentDataContainer().getOrDefault(k.pdcKey, PersistentDataType.STRING, ""));
            case "k.checkpoint" -> {
                Thread t = new Thread(() -> probe.agent.Crac.checkpointNow("done"), "probe-crac");
                t.start();
            }
            default -> throw new IllegalArgumentException("unknown " + name);
        }
        return true;
    }

    void req(Player p, String tok, Map<String, Object> r) {
        UUID u = p.getUniqueId();
        Map<String, Object> saw = read(p);
        StringBuilder b = new StringBuilder("KREQ " + tok);
        saw.forEach((key, v) -> b.append(' ').append(key).append('=').append(v));
        say(p, b.toString());
        saw.forEach((key, v) -> r.put("s_" + key, v));
        // Write every kind, as a requirement that touches all of them would.
        Properties st = stored(u);
        st.setProperty("v", tok);
        st.setProperty("perm", tok);
        save(u);
        Sess s = sessions.computeIfAbsent(u, x -> new Sess(p.getName()));
        String h = "KH " + tok;
        s.history.add(h);
        say(p, h);
        startHold(p, tok);
        endHold(p, tok);
        Scoreboard sb = Bukkit.getScoreboardManager().getMainScoreboard();
        String teamName = "k" + Integer.toHexString(tok.hashCode());
        Team t = sb.getTeam(teamName);
        if (t == null) t = sb.registerNewTeam(teamName);
        t.addEntry(p.getName());
        PermissionAttachment a = perms.computeIfAbsent(u, x -> p.addAttachment(plugin));
        a.setPermission("k.perm", true);
        ItemStack item = new ItemStack(Material.STICK);
        item.editMeta(m -> m.customName(Component.text("I" + tok)));
        p.getInventory().addItem(item);
        p.addPotionEffect(new PotionEffect(PotionEffectType.SPEED, 20 * 600, 0, false, false, false));
        p.teleport(home(p).add(3, 0, 0));
        p.setLevel(3);
        try {
            Files.writeString(mailFile(u), tok + "\n", StandardCharsets.UTF_8, java.nio.file.StandardOpenOption.CREATE, java.nio.file.StandardOpenOption.APPEND);
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        p.getPersistentDataContainer().set(pdcKey, PersistentDataType.STRING, tok);
        p.setPlayerTime(18000, false);
        p.getEnderChest().addItem(new ItemStack(Material.STICK));
        BossBar bar = BossBar.bossBar(Component.text("B" + tok), 1f, BossBar.Color.RED, BossBar.Overlay.PROGRESS);
        BossBar old = bars.put(u, bar);
        if (old != null) p.hideBossBar(old);
        p.showBossBar(bar);
        p.setMetadata("k", new FixedMetadataValue(plugin, tok));
    }

    Map<String, Object> read(Player p) {
        UUID u = p.getUniqueId();
        Map<String, Object> m = new LinkedHashMap<>();
        Properties st = stored(u);
        m.put("stored", st.getProperty("v", "-"));
        Sess s = sessions.get(u);
        m.put("history", s == null ? 0 : s.history.size());
        m.put("session", s != null && s.resumed ? 1 : 0);
        m.put("hold", holds.containsKey(u) ? 1 : 0);
        Team t = Bukkit.getScoreboardManager().getMainScoreboard().getEntryTeam(p.getName());
        m.put("team", t == null ? "-" : t.getName());
        m.put("perm", p.hasPermission("k.perm") ? 1 : 0);
        m.put("sperm", st.getProperty("perm", "-"));
        int inv = 0;
        for (ItemStack i : p.getInventory().getContents()) if (i != null && !i.isEmpty()) inv++;
        m.put("inv", inv);
        m.put("eff", p.getActivePotionEffects().size());
        m.put("pos", Math.round(p.getLocation().distance(home(p)) * 10) / 10.0);
        m.put("xp", p.getLevel());
        m.put("mail", Files.exists(mailFile(u)) ? 1 : 0);
        m.put("pdc", p.getPersistentDataContainer().has(pdcKey) ? 1 : 0);
        m.put("ptime", p.isPlayerTimeRelative() ? 0 : 1);
        int ender = 0;
        for (ItemStack i : p.getEnderChest().getContents()) if (i != null && !i.isEmpty()) ender++;
        m.put("ender", ender);
        m.put("boss", bars.containsKey(u) ? 1 : 0);
        m.put("meta", p.hasMetadata("k") ? 1 : 0);
        return m;
    }

    static Location home(Player p) {
        return new Location(p.getWorld(), 0.5, 65, 0.5, 0f, 0f);
    }

    void startHold(Player p, String tok) {
        Hold pending = holds.remove(p.getUniqueId());
        if (pending != null) {
            Bukkit.getScheduler().cancelTask(pending.taskId());
            say(p, "KHOLD adopted " + pending.token());
        }
    }

    /** Removal waits the grace; a hold started again within it adopts this one. */
    void endHold(Player p, String tok) {
        UUID u = p.getUniqueId();
        int id = Bukkit.getScheduler().runTaskLater(plugin, () -> holds.remove(u), integer("holdGrace", 10)).getTaskId();
        holds.put(u, new Hold(tok, id));
    }

    /** naive: what an obvious per player reset clears (plugin store, chat, inventory, effects, position).
     *  full: every kind this plugin knows about. */
    void wipe(Player p, String scope) {
        UUID u = p.getUniqueId();
        store.put(u, new Properties());
        try {
            Files.deleteIfExists(storeFile(u));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        p.getInventory().clear();
        for (PotionEffect e : p.getActivePotionEffects()) p.removePotionEffect(e.getType());
        p.setVelocity(new org.bukkit.util.Vector());
        p.setFallDistance(0);
        p.teleport(home(p));
        if (!scope.equals("full")) return;
        sessions.remove(u);
        saveSessions();
        Hold h = holds.remove(u);
        if (h != null) Bukkit.getScheduler().cancelTask(h.taskId());
        Team t = Bukkit.getScoreboardManager().getMainScoreboard().getEntryTeam(p.getName());
        if (t != null) t.removeEntry(p.getName());
        PermissionAttachment a = perms.remove(u);
        if (a != null) a.remove();
        p.setLevel(0);
        p.setExp(0);
        try {
            Files.deleteIfExists(mailFile(u));
        } catch (IOException e) {
            throw new RuntimeException(e);
        }
        p.getPersistentDataContainer().remove(pdcKey);
        p.resetPlayerTime();
        p.getEnderChest().clear();
        BossBar b = bars.remove(u);
        if (b != null) p.hideBossBar(b);
        p.removeMetadata("k", plugin);
    }

    void files(Map<String, Object> r) {
        Path world = Bukkit.getWorldContainer().toPath().resolve(Bukkit.getWorlds().get(0).getName()).normalize();
        Map<String, Object> f = new LinkedHashMap<>();
        for (Path base : List.of(world, dir)) {
            try (Stream<Path> s = Files.walk(base)) {
                s.filter(Files::isRegularFile).filter(x -> !x.toString().contains("region") && !x.toString().contains("entities") && !x.toString().contains("poi"))
                        .forEach(x -> {
                            String key = base.relativize(x.getParent()).toString();
                            long[] c = (long[]) f.computeIfAbsent(base.getFileName() + "/" + key, z -> new long[2]);
                            c[0]++;
                            try {
                                c[1] += Files.size(x);
                            } catch (IOException ignored) {
                            }
                        });
            } catch (IOException e) {
                throw new RuntimeException(e);
            }
        }
        Map<String, Object> out = new LinkedHashMap<>();
        f.forEach((key, v) -> out.put(key, ((long[]) v)[0] + " files " + ((long[]) v)[1] + " B"));
        r.put("files", out);
        Path uc = Path.of("usercache.json");
        r.put("usercacheBytes", Files.exists(uc) ? uc.toFile().length() : 0);
        Runtime rt = Runtime.getRuntime();
        System.gc();
        r.put("heapUsedMb", (rt.totalMemory() - rt.freeMemory()) >> 20);
        r.put("sessions", sessions.size());
        r.put("holds", holds.size());
        r.put("teams", Bukkit.getScoreboardManager().getMainScoreboard().getTeams().size());
        r.put("offlinePlayers", Bukkit.getOfflinePlayers().length);
        r.put("uptimeMs", ManagementFactory.getRuntimeMXBean().getUptime());
        r.put("at", Instant.now().toEpochMilli());
    }
}
