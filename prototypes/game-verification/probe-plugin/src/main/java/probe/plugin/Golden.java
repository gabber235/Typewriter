package probe.plugin;

import java.util.Map;
import org.bukkit.Bukkit;
import org.bukkit.GameMode;
import org.bukkit.Location;
import org.bukkit.Material;
import org.bukkit.World;
import org.bukkit.entity.Entity;
import org.bukkit.entity.Player;
import org.bukkit.inventory.ItemStack;

/** Spike F: a fixed diorama with every animated thing a golden frame meets, and a fixed camera. */
final class Golden {
    private Golden() {}

    private static void fill(World w, Material m, int x0, int x1, int y0, int y1, int z0, int z1) {
        for (int x = x0; x <= x1; x++)
            for (int y = y0; y <= y1; y++)
                for (int z = z0; z <= z1; z++) w.getBlockAt(x, y, z).setType(m, false);
    }

    private static void quiet(World w) {
        for (String rule : new String[] {"minecraft:advance_time false", "minecraft:advance_weather false", "minecraft:random_tick_speed 0", "minecraft:spawn_mobs false"}) {
            Bukkit.dispatchCommand(Bukkit.getConsoleSender(), "gamerule " + rule);
        }
        w.setTime(6000);
        w.setStorm(false);
        w.setThundering(false);
        for (Entity e : w.getEntities()) if (!(e instanceof Player)) e.remove();
    }

    static boolean run(String name, Map<String, String> q, Player p, Map<String, Object> r) {
        switch (name) {
            case "gscene" -> {
                World w = p.getWorld();
                quiet(w);
                fill(w, Material.AIR, -8, 8, 65, 70, -3, 11);
                fill(w, Material.STONE, -8, 8, 63, 63, -3, 11);
                fill(w, Material.GRASS_BLOCK, -8, 8, 64, 64, -3, 11);
                fill(w, Material.WATER, 1, 4, 64, 64, 3, 5);
                fill(w, Material.LAVA, -5, -3, 64, 64, 3, 5);
                fill(w, Material.STONE_BRICKS, -6, 6, 65, 68, 9, 9);
                w.getBlockAt(-6, 65, 7).setType(Material.NETHERRACK, false);
                w.getBlockAt(-6, 66, 7).setType(Material.FIRE, false);
                w.getBlockAt(4, 65, 7).setType(Material.TORCH, false);
                w.getBlockAt(5, 65, 8).setType(Material.OAK_LEAVES, false);
                p.setGameMode(GameMode.CREATIVE);
                p.setFlying(false);
                p.getInventory().clear();
                p.teleport(new Location(w, 0.5, 65, 0.5, 0f, Float.parseFloat(q.getOrDefault("pitch", "20"))));
            }
            case "gterrain" -> {
                World w = p.getWorld();
                quiet(w);
                Location s = w.getSpawnLocation();
                int y = w.getHighestBlockYAt(s.getBlockX(), s.getBlockZ()) + 3;
                p.setGameMode(GameMode.CREATIVE);
                p.setAllowFlight(true);
                p.setFlying(true);
                p.getInventory().clear();
                p.teleport(new Location(w, s.getBlockX() + 0.5, y, s.getBlockZ() + 0.5, Float.parseFloat(q.getOrDefault("yaw", "30")), Float.parseFloat(q.getOrDefault("pitch", "15"))));
                r.put("at", s.getBlockX() + "," + y + "," + s.getBlockZ());
            }
            case "ghotbar" -> {
                p.getInventory().clear();
                String[] items = q.getOrDefault("items", "").split(",", -1);
                for (int i = 0; i < items.length && i < 9; i++) {
                    if (!items[i].isEmpty()) p.getInventory().setItem(i, new ItemStack(Material.valueOf(items[i]), 1));
                }
                p.getInventory().setHeldItemSlot(Integer.parseInt(q.getOrDefault("held", "0")));
                p.updateInventory();
            }
            case "gprep" -> {
                // Advancement and recipe toasts would slide in whenever an item is first given; spend them once.
                Bukkit.dispatchCommand(Bukkit.getConsoleSender(), "gamerule minecraft:show_advancement_messages false");
                Bukkit.dispatchCommand(Bukkit.getConsoleSender(), "advancement grant " + p.getName() + " everything");
                Bukkit.dispatchCommand(Bukkit.getConsoleSender(), "recipe give " + p.getName() + " *");
            }
            case "gfreeze" -> Bukkit.getServerTickManager().setFrozen("1".equals(q.get("on")));
            default -> {
                return false;
            }
        }
        return true;
    }
}
