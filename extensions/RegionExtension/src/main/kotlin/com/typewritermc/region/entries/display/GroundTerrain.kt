package com.typewritermc.region.entries.display

import it.unimi.dsi.fastutil.longs.Long2ObjectOpenHashMap
import org.bukkit.ChunkSnapshot
import org.bukkit.World

/** The block reads a ground sampling makes. */
internal interface GroundTerrain {
    val maxHeight: Int

    fun isColumnLoaded(x: Int, z: Int): Boolean

    fun highestBlockY(x: Int, z: Int): Int

    fun isSolid(x: Int, y: Int, z: Int): Boolean
}

/**
 * Reads the terrain from chunk snapshots.
 *
 * A column scan reads every block between the region's floor and the terrain, and a tall region
 * over a wide footprint reads hundreds of thousands of them per refresh. Each read through
 * [World.getBlockAt] allocates a block handle and looks its chunk up again, while a snapshot is
 * copied once per chunk and answers from an array.
 *
 * It is created and read on the main thread, since the snapshots are taken on first use.
 */
internal class SnapshotTerrain(private val world: World) : GroundTerrain {
    private val snapshots = Long2ObjectOpenHashMap<ChunkSnapshot?>()

    override val maxHeight: Int get() = world.maxHeight

    override fun isColumnLoaded(x: Int, z: Int): Boolean = snapshot(x shr 4, z shr 4) != null

    override fun highestBlockY(x: Int, z: Int): Int = world.getHighestBlockYAt(x, z)

    override fun isSolid(x: Int, y: Int, z: Int): Boolean =
        snapshot(x shr 4, z shr 4)?.getBlockType(x and 15, y, z and 15)?.isSolid ?: false

    private fun snapshot(chunkX: Int, chunkZ: Int): ChunkSnapshot? {
        val key = (chunkX.toLong() shl 32) or (chunkZ.toLong() and 0xFFFFFFFFL)
        if (snapshots.containsKey(key)) return snapshots.get(key)
        val snapshot = if (world.isChunkLoaded(chunkX, chunkZ)) {
            world.getChunkAt(chunkX, chunkZ).getChunkSnapshot(false, false, false)
        } else {
            null
        }
        snapshots.put(key, snapshot)
        return snapshot
    }
}

/**
 * Reads the terrain block by block from the world.
 *
 * The specs use it: MockBukkit's chunk snapshot stores blocks under world coordinates and looks
 * them up under chunk local ones, so it answers air for every block.
 */
internal class WorldTerrain(private val world: World) : GroundTerrain {
    override val maxHeight: Int get() = world.maxHeight

    override fun isColumnLoaded(x: Int, z: Int): Boolean = world.isChunkLoaded(x shr 4, z shr 4)

    override fun highestBlockY(x: Int, z: Int): Int = world.getHighestBlockYAt(x, z)

    override fun isSolid(x: Int, y: Int, z: Int): Boolean = world.getBlockAt(x, y, z).type.isSolid
}
