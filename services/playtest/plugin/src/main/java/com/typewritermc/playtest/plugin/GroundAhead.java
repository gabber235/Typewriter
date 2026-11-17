package com.typewritermc.playtest.plugin;

import java.util.HashMap;
import java.util.HashSet;
import java.util.List;
import java.util.Map;
import java.util.Set;
import org.bukkit.Bukkit;
import org.bukkit.World;
import org.bukkit.plugin.Plugin;
import skirout.harness.v1.wire.Region;

/**
 * The ground of the regions the next claims get, which Paper loads during earlier attempts so a claim
 * finds its chunks loaded: around each region's middle, every chunk Paper sends a player standing there
 * plus the ring the client needs to draw the outermost of them. A region's ground stays loaded until the
 * attempt in it ends; regions are never reused, so it is never loaded again. Main thread only.
 */
final class GroundAhead {
    private final Plugin plugin;
    private final Set<Region> loaded = new HashSet<>();
    private final Map<Long, Region> claimed = new HashMap<>();

    GroundAhead(Plugin plugin) {
        this.plugin = plugin;
    }

    /** The next claims get [regions]; Paper starts loading the ground of each it does not hold yet. */
    void load(List<Region> regions) {
        World world = world();
        for (Region region : regions) {
            if (loaded.add(region)) forEachChunk(world, region, (x, z) -> world.addPluginChunkTicket(x, z, plugin));
        }
    }

    /** [attempt] stands in [region]; its ground stays loaded until the attempt ends. */
    void claim(long attempt, Region region) {
        if (loaded.contains(region)) claimed.put(attempt, region);
    }

    /** [attempt] ended; Paper lets its region's ground go. */
    void release(long attempt) {
        Region region = claimed.remove(attempt);
        if (region == null || !loaded.remove(region)) return;
        World world = world();
        forEachChunk(world, region, (x, z) -> world.removePluginChunkTicket(x, z, plugin));
    }

    private static World world() {
        return Bukkit.getWorlds().getFirst();
    }

    private interface ChunkAction {
        void at(int x, int z);
    }

    private static void forEachChunk(World world, Region region, ChunkAction action) {
        int radius = world.getSendViewDistance() + 1;
        int middleX = region.getX() >> 4;
        int middleZ = region.getZ() >> 4;
        for (int x = middleX - radius; x <= middleX + radius; x++) {
            for (int z = middleZ - radius; z <= middleZ + radius; z++) action.at(x, z);
        }
    }
}
