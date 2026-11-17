package com.typewritermc.playtest.plugin

import org.bukkit.Bukkit
import org.bukkit.World
import org.bukkit.plugin.Plugin
import skirout.harness.v1.wire.Region

/**
 * The ground of the regions the next claims get, which Paper loads during earlier attempts so a claim
 * finds its chunks loaded: around each region's middle, every chunk Paper sends a player standing there
 * plus the ring the client needs to draw the outermost of them. A region's ground stays loaded until the
 * attempt in it ends; regions are never reused, so it is never loaded again. Main thread only.
 */
internal class GroundAhead(
    private val plugin: Plugin,
) {
    private val loaded = HashSet<Region>()
    private val claimed = HashMap<Long, Region>()

    /** The next claims get [regions]; Paper starts loading the ground of each it does not hold yet. */
    fun load(regions: List<Region>) {
        val world = world()
        for (region in regions) {
            if (loaded.add(region)) forEachChunk(world, region) { x, z -> world.addPluginChunkTicket(x, z, plugin) }
        }
    }

    /** [attempt] stands in [region]; its ground stays loaded until the attempt ends. */
    fun claim(
        attempt: Long,
        region: Region,
    ) {
        if (region in loaded) claimed[attempt] = region
    }

    /** [attempt] ended; Paper lets its region's ground go. */
    fun release(attempt: Long) {
        val region = claimed.remove(attempt)
        if (region == null || !loaded.remove(region)) return
        val world = world()
        forEachChunk(world, region) { x, z -> world.removePluginChunkTicket(x, z, plugin) }
    }
}

private fun world(): World = Bukkit.getWorlds().first()

private inline fun forEachChunk(
    world: World,
    region: Region,
    action: (x: Int, z: Int) -> Unit,
) {
    val radius = world.sendViewDistance + 1
    val middleX = region.x shr 4
    val middleZ = region.z shr 4
    for (x in middleX - radius..middleX + radius) {
        for (z in middleZ - radius..middleZ + radius) action(x, z)
    }
}
