package probe.plugin;

import io.papermc.paper.event.player.AsyncChatEvent;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import net.kyori.adventure.text.serializer.plain.PlainTextComponentSerializer;
import net.minecraft.server.MinecraftServer;
import org.bukkit.Bukkit;
import org.bukkit.GameMode;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.World;
import org.bukkit.entity.Player;
import org.bukkit.event.EventHandler;
import org.bukkit.event.EventPriority;
import org.bukkit.event.Listener;
import org.bukkit.event.player.PlayerItemHeldEvent;
import org.bukkit.event.player.PlayerToggleSneakEvent;
import org.bukkit.inventory.ItemStack;
import org.bukkit.inventory.PlayerInventory;

/**
 * In process input prototype, cross talk: several clients send input at the same step; this records every
 * event with the player it reached, so an input that lands on the wrong client shows as the wrong player.
 *
 *   x.arrange?players=a,b,c    each player on its own spot, same inventory, slot 0, facing south, log cleared
 *   x.log                      every recorded event: player, kind, detail, server tick
 *   x.state?players=a,b,c      each player's slot, yaw and sneak state as the server sees it
 */
final class Cross implements Listener {
    private static final List<String> log = new ArrayList<>();

    static void start(ProbePlugin p) {
        Bukkit.getPluginManager().registerEvents(new Cross(), p);
    }

    private static synchronized void add(Player p, String kind, String detail) {
        log.add("{\"p\":" + Input.q(p.getName()) + ",\"k\":" + Input.q(kind) + ",\"d\":" + Input.q(detail) + ",\"st\":" + MinecraftServer.getServer().getTickCount() + "}");
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void held(PlayerItemHeldEvent e) {
        add(e.getPlayer(), "held", e.getPreviousSlot() + "->" + e.getNewSlot());
    }

    @EventHandler(priority = EventPriority.MONITOR)
    public void sneak(PlayerToggleSneakEvent e) {
        add(e.getPlayer(), "sneak", String.valueOf(e.isSneaking()));
    }

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = false)
    public void chat(AsyncChatEvent e) {
        add(e.getPlayer(), "chat", PlainTextComponentSerializer.plainText().serialize(e.message()));
    }

    static boolean run(String name, Map<String, String> q, Player ignored, Map<String, Object> r) {
        switch (name) {
            case "x.arrange" -> {
                String[] names = q.get("players").split(",");
                World w = Bukkit.getWorlds().get(0);
                for (int x = -2; x <= 4 * names.length + 2; x++)
                    for (int y = Input.Y; y <= Input.Y + 2; y++)
                        for (int z = -3; z <= 3; z++) w.getBlockAt(x, y, z).setType(Material.AIR, false);
                for (int i = 0; i < names.length; i++) {
                    Player p = Bukkit.getPlayerExact(names[i]);
                    if (p == null) throw new IllegalStateException("not online: " + names[i]);
                    p.closeInventory();
                    p.setGameMode(GameMode.SURVIVAL);
                    p.setSneaking(false);
                    p.setVelocity(new org.bukkit.util.Vector());
                    p.teleport(new Location(w, 4 * i + 0.5, Input.Y, 0.5, 0f, 0f));
                    PlayerInventory inv = p.getInventory();
                    inv.clear();
                    inv.setItem(0, new ItemStack(Material.SPYGLASS));
                    inv.setItem(1, new ItemStack(Material.STICK));
                    inv.setItem(2, new ItemStack(Material.DIAMOND, 5));
                    inv.setItem(3, new ItemStack(Material.APPLE, 3));
                    inv.setItem(4, new ItemStack(Material.BREAD, 3));
                    inv.setHeldItemSlot(0);
                }
                synchronized (Cross.class) {
                    log.clear();
                }
                r.put("tick", MinecraftServer.getServer().getTickCount());
            }
            case "x.log" -> {
                synchronized (Cross.class) {
                    r.put("log", new Input.RawJson("[" + String.join(",", log) + "]"));
                }
                r.put("tick", MinecraftServer.getServer().getTickCount());
            }
            case "x.state" -> {
                StringBuilder b = new StringBuilder("[");
                for (String n : q.get("players").split(",")) {
                    Player p = Bukkit.getPlayerExact(n);
                    if (b.length() > 1) b.append(',');
                    b.append("{\"p\":").append(Input.q(n));
                    if (p != null) b.append(",\"slot\":").append(p.getInventory().getHeldItemSlot()).append(",\"yaw\":").append(p.getLocation().getYaw())
                            .append(",\"sneaking\":").append(p.isSneaking());
                    b.append('}');
                }
                r.put("players", new Input.RawJson(b.append(']').toString()));
                r.put("tick", MinecraftServer.getServer().getTickCount());
            }
            default -> {
                return false;
            }
        }
        return true;
    }
}
