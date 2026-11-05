package probe.plugin;

import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.UUID;
import net.kyori.adventure.bossbar.BossBar;
import net.kyori.adventure.text.Component;
import net.kyori.adventure.text.format.TextColor;
import net.kyori.adventure.title.Title;
import net.minecraft.core.NonNullList;
import net.minecraft.network.protocol.game.ClientboundAddEntityPacket;
import net.minecraft.network.protocol.game.ClientboundContainerSetContentPacket;
import net.minecraft.network.protocol.game.ClientboundRemoveEntitiesPacket;
import net.minecraft.network.protocol.game.ClientboundSetCameraPacket;
import net.minecraft.network.protocol.game.ClientboundSetEntityDataPacket;
import net.minecraft.network.protocol.game.ClientboundTeleportEntityPacket;
import net.minecraft.server.level.ServerPlayer;
import net.minecraft.world.entity.Display;
import net.minecraft.world.entity.EntityTypes;
import net.minecraft.world.entity.PositionMoveRotation;
import net.minecraft.world.entity.monster.zombie.Zombie;
import net.minecraft.world.item.Items;
import net.minecraft.world.phys.Vec3;
import org.bukkit.Bukkit;
import org.bukkit.GameMode;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.SoundCategory;
import org.bukkit.World;
import org.bukkit.block.Block;
import org.bukkit.block.Sign;
import org.bukkit.block.sign.Side;
import org.bukkit.craftbukkit.CraftWorld;
import org.bukkit.craftbukkit.entity.CraftPlayer;
import org.bukkit.entity.Player;
import org.bukkit.inventory.ItemStack;
import org.bukkit.scheduler.BukkitTask;
import org.bukkit.scoreboard.Criteria;
import org.bukkit.scoreboard.DisplaySlot;
import org.bukkit.scoreboard.Objective;
import org.bukkit.scoreboard.Scoreboard;

/** Spike A scene commands. Everything a scene builds is undone by `arena`. */
final class Observe {
    private static final List<Integer> packetEntities = new ArrayList<>();
    private static final List<Location> realBlocks = new ArrayList<>();
    private static final List<Location> fakeBlocks = new ArrayList<>();
    private static BukkitTask rideTask;
    private static BossBar bar;

    private Observe() {}

    private static double d(Map<String, String> q, String k, double v) {
        return q.containsKey(k) ? Double.parseDouble(q.get(k)) : v;
    }

    private static int i(Map<String, String> q, String k, int v) {
        return q.containsKey(k) ? Integer.parseInt(q.get(k)) : v;
    }

    /** A few Display setters are private on the server side. */
    private static void call(Class<?> owner, Object target, String method, int value) {
        try {
            var m = owner.getDeclaredMethod(method, int.class);
            m.setAccessible(true);
            m.invoke(target, value);
        } catch (ReflectiveOperationException e) {
            throw new RuntimeException(e);
        }
    }

    private static ServerPlayer nms(Player p) {
        return ((CraftPlayer) p).getHandle();
    }

    static boolean run(String name, Map<String, String> q, Player p, Map<String, Object> r) {
        switch (name) {
            case "arena" -> arena(p);
            case "wall" -> {
                Material m = Material.valueOf(q.getOrDefault("material", "STONE"));
                int z = i(q, "z", 3);
                World w = p.getWorld();
                for (int x = i(q, "x0", -3); x <= i(q, "x1", 3); x++) {
                    for (int y = i(q, "y0", 65); y <= i(q, "y1", 69); y++) {
                        Block b = w.getBlockAt(x, y, z);
                        b.setType(m, false);
                        realBlocks.add(b.getLocation());
                    }
                }
            }
            case "block" -> {
                Location at = new Location(p.getWorld(), i(q, "x", 0), i(q, "y", 65), i(q, "z", 0));
                Material m = Material.valueOf(q.get("material"));
                if ("1".equals(q.get("fake"))) {
                    p.sendBlockChange(at, m.createBlockData());
                    fakeBlocks.add(at);
                } else {
                    at.getBlock().setType(m, false);
                    realBlocks.add(at);
                }
            }
            case "sign" -> {
                Block b = p.getWorld().getBlockAt(i(q, "x", 0), i(q, "y", 65), i(q, "z", 3));
                b.setType(Material.OAK_SIGN, false);
                realBlocks.add(b.getLocation());
                org.bukkit.block.data.type.Sign data = (org.bukkit.block.data.type.Sign) b.getBlockData();
                data.setRotation(org.bukkit.block.BlockFace.valueOf(q.getOrDefault("face", "SOUTH")));
                b.setBlockData(data, false);
                Sign sign = (Sign) b.getState();
                sign.getSide(Side.FRONT).line(1, Component.text(q.get("text")));
                sign.update(true, false);
            }
            case "pzombie" -> {
                Zombie z = new Zombie(EntityTypes.ZOMBIE, ((CraftWorld) p.getWorld()).getHandle());
                double x = d(q, "x", 0.5), y = d(q, "y", 65), zz = d(q, "z", 6.5);
                z.setPos(x, y, zz);
                if ("1".equals(q.get("invisible"))) z.setInvisible(true);
                if (q.containsKey("name")) {
                    z.setCustomName(net.minecraft.network.chat.Component.literal(q.get("name")));
                    z.setCustomNameVisible(true);
                }
                var c = nms(p).connection;
                c.send(new ClientboundAddEntityPacket(z.getId(), UUID.randomUUID(), x, y, zz, 0f, (float) d(q, "yaw", 180), EntityTypes.ZOMBIE, 0, Vec3.ZERO, d(q, "yaw", 180)));
                c.send(new ClientboundSetEntityDataPacket(z.getId(), z.getEntityData().packAll()));
                packetEntities.add(z.getId());
                r.put("id", z.getId());
            }
            case "ptext" -> {
                Display.TextDisplay t = new Display.TextDisplay(EntityTypes.TEXT_DISPLAY, ((CraftWorld) p.getWorld()).getHandle());
                double x = d(q, "x", 0.5), y = d(q, "y", 66.2), z = d(q, "z", 4.5);
                t.setPos(x, y, z);
                var text = net.minecraft.network.chat.Component.literal(q.get("text"));
                if (q.containsKey("color")) text = text.withColor(Integer.parseInt(q.get("color"), 16));
                t.setText(text);
                if (q.containsKey("opacity")) t.setTextOpacity((byte) i(q, "opacity", 255));
                if (q.containsKey("bg")) call(Display.TextDisplay.class, t, "setBackgroundColor", (int) Long.parseLong(q.get("bg"), 16));
                var c = nms(p).connection;
                c.send(new ClientboundAddEntityPacket(t.getId(), UUID.randomUUID(), x, y, z, 0f, (float) d(q, "yaw", 180), EntityTypes.TEXT_DISPLAY, 0, Vec3.ZERO, 0));
                c.send(new ClientboundSetEntityDataPacket(t.getId(), t.getEntityData().packAll()));
                packetEntities.add(t.getId());
                r.put("id", t.getId());
            }
            case "ttl" -> {
                Component c = Component.text(q.get("text"));
                if (q.containsKey("color")) c = c.color(TextColor.fromHexString("#" + q.get("color")));
                p.showTitle(Title.title(c, Component.empty(), Title.Times.times(Duration.ZERO, Duration.ofMillis(50L * i(q, "stay", 400)), Duration.ZERO)));
            }
            case "say" -> p.sendMessage(Component.text(q.get("text")));
            case "saymany" -> {
                int n = i(q, "n", 30);
                for (int k = 0; k < n; k++) p.sendMessage(Component.text(q.getOrDefault("prefix", "line") + k));
            }
            case "bar" -> p.sendActionBar(Component.text(q.get("text")));
            case "sound" -> {
                Location l = p.getLocation().add(d(q, "dx", 0), d(q, "dy", 0), d(q, "dz", 2));
                p.playSound(l, q.getOrDefault("id", "minecraft:entity.zombie.ambient"), SoundCategory.valueOf(q.getOrDefault("cat", "HOSTILE")), (float) d(q, "vol", 1), 1f);
            }
            case "boss" -> {
                bar = BossBar.bossBar(Component.text(q.get("text")), (float) d(q, "progress", 0.5), BossBar.Color.RED, BossBar.Overlay.PROGRESS);
                p.showBossBar(bar);
            }
            case "sidebar" -> {
                Scoreboard board = Bukkit.getScoreboardManager().getNewScoreboard();
                Objective o = board.registerNewObjective("probe", Criteria.DUMMY, Component.text(q.get("title")));
                o.setDisplaySlot(DisplaySlot.SIDEBAR);
                int score = 10;
                for (String line : q.get("lines").split("\\|")) o.getScore(line).setScore(score--);
                p.setScoreboard(board);
            }
            case "items" -> {
                p.getInventory().clear();
                if (q.containsKey("item")) p.getInventory().setItem(i(q, "slot", 3), new ItemStack(Material.valueOf(q.get("item")), i(q, "count", 3)));
            }
            case "fakeInv" -> {
                ServerPlayer h = nms(p);
                NonNullList<net.minecraft.world.item.ItemStack> items = NonNullList.withSize(h.inventoryMenu.getItems().size(), net.minecraft.world.item.ItemStack.EMPTY);
                if (q.containsKey("slot")) items.set(36 + i(q, "slot", 3), new net.minecraft.world.item.ItemStack(Items.DIAMOND, i(q, "count", 3)));
                h.connection.send(new ClientboundContainerSetContentPacket(0, h.inventoryMenu.getStateId(), items, net.minecraft.world.item.ItemStack.EMPTY));
            }
            case "serverInv" -> {
                int n = 0;
                for (ItemStack s : p.getInventory().getContents()) if (s != null && !s.isEmpty()) n += s.getAmount();
                r.put("count", n);
            }
            case "wiggle" -> {
                ServerPlayer h = nms(p);
                int id = i(q, "id", 0);
                double x = d(q, "x", 0.5), y = d(q, "y", 65), z = d(q, "z", 4.5);
                int[] n = {0};
                rideTask = Bukkit.getScheduler().runTaskTimer(ProbeAccess.plugin(), () -> {
                    n[0]++;
                    h.connection.send(ClientboundTeleportEntityPacket.teleport(id, new PositionMoveRotation(new Vec3(x + (n[0] % 2) * 0.3, y, z), Vec3.ZERO, 180f, 0f), Set.of(), false));
                }, 1L, 1L);
            }
            case "ride" -> ride(p, q, r);
            case "rideEnd" -> rideEnd(p);
            default -> {
                return false;
            }
        }
        return true;
    }

    private static void arena(Player p) {
        rideEnd(p);
        p.setGameMode(GameMode.SURVIVAL);
        p.resetTitle();
        p.sendActionBar(Component.empty());
        var c = nms(p).connection;
        if (!packetEntities.isEmpty()) {
            c.send(new ClientboundRemoveEntitiesPacket(packetEntities.stream().mapToInt(x -> x).toArray()));
            packetEntities.clear();
        }
        for (Location at : realBlocks) at.getBlock().setType(Material.AIR, false);
        realBlocks.clear();
        for (Location at : fakeBlocks) p.sendBlockChange(at, at.getBlock().getBlockData());
        fakeBlocks.clear();
        if (bar != null) {
            p.hideBossBar(bar);
            bar = null;
        }
        p.setScoreboard(Bukkit.getScoreboardManager().getMainScoreboard());
        p.getInventory().clear();
        p.updateInventory();
        p.teleport(new Location(p.getWorld(), 0.5, 65, 0.5, 0f, 0f));
    }

    /** Scene 16: spectate a packet only display, moved once per tick. Duration 0 is the broken variant. */
    private static void ride(Player p, Map<String, String> q, Map<String, Object> r) {
        ServerPlayer h = nms(p);
        Display.TextDisplay t = new Display.TextDisplay(EntityTypes.TEXT_DISPLAY, ((CraftWorld) p.getWorld()).getHandle());
        double x = 0.5, y = 67, z0 = d(q, "z", -6);
        double step = d(q, "step", 0.25);
        int ticks = i(q, "ticks", 50);
        t.setPos(x, y, z0);
        call(Display.class, t, "setPosRotInterpolationDuration", i(q, "duration", 3));
        var c = h.connection;
        c.send(new ClientboundAddEntityPacket(t.getId(), UUID.randomUUID(), x, y, z0, 0f, 0f, EntityTypes.TEXT_DISPLAY, 0, Vec3.ZERO, 0));
        c.send(new ClientboundSetEntityDataPacket(t.getId(), t.getEntityData().packAll()));
        c.send(new ClientboundSetCameraPacket(t));
        packetEntities.add(t.getId());
        int id = t.getId();
        int[] n = {0};
        rideTask = Bukkit.getScheduler().runTaskTimer(ProbeAccess.plugin(), () -> {
            n[0]++;
            c.send(ClientboundTeleportEntityPacket.teleport(id, new PositionMoveRotation(new Vec3(x, y, z0 + n[0] * step), Vec3.ZERO, 0f, 0f), Set.of(), false));
            if (n[0] >= ticks && rideTask != null) {
                rideTask.cancel();
                rideTask = null;
            }
        }, 1L, 1L);
        r.put("id", id);
    }

    private static void rideEnd(Player p) {
        if (rideTask != null) {
            rideTask.cancel();
            rideTask = null;
        }
        nms(p).connection.send(new ClientboundSetCameraPacket(nms(p)));
    }
}
