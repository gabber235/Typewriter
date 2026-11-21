package com.typewritermc.region.entries.display

import com.github.retrooper.packetevents.protocol.packettype.PacketType
import com.github.retrooper.packetevents.protocol.player.DiggingAction
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientPlayerBlockPlacement
import com.github.retrooper.packetevents.wrapper.play.client.WrapperPlayClientPlayerDigging
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerAcknowledgeBlockChanges
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerBlockChange
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.interaction.InterceptionBundle
import com.typewritermc.engine.paper.interaction.interceptPackets
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.engine.paper.utils.toBukkitLocation
import com.typewritermc.engine.paper.utils.toPacketVector3i
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.tracker.RegionTracker
import io.github.retrooper.packetevents.util.SpigotConversionUtil
import io.papermc.paper.event.packet.PlayerChunkLoadEvent
import it.unimi.dsi.fastutil.longs.LongOpenHashSet
import it.unimi.dsi.fastutil.objects.ObjectOpenHashSet
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlinx.coroutines.Dispatchers
import org.bukkit.Location
import org.bukkit.Material
import org.bukkit.block.data.BlockData
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler

@Entry(
    "region_boundary_fake_block",
    "Renders a region's boundary as client-side fake blocks",
    Colors.GREEN,
    "mingcute:cube-3d-fill"
)
/**
 * Sends client side fake block packets at boundary samples. Only audience players see the
 * wall. Only blocks a player could pass through are replaced: air, liquids, plants and
 * other non solid blocks. Solid blocks stay visible, so the wall never swallows terrain.
 *
 * Clicking a fake block cannot make it disappear: the dig and place packets aimed at one
 * are intercepted, the client's block prediction is acknowledged, and the block is
 * sent again, so the wall holds up under punching.
 *
 * Packets are cached per player and sent again only when the resolved shape, the material, or
 * the near window changes; the world is also only sampled at those moments. When the
 * server sends a chunk again after it left the client's render distance, the wall inside it
 * is sent again too. When a player leaves the audience, the original blocks are restored
 * client side.
 *
 * ## How could this be used?
 *
 * Show a barrier wall to players who have not finished the quest that opens an area, while
 * everyone else walks through empty air. Pair it with a Region Barrier Audience so the wall
 * a player sees is the same one that actually holds them back.
 */
class RegionBoundaryFakeBlockDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The region whose boundary to render.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
    @Help("Samples per unit boundary area. Zero is not off: every boundary gets at least eight samples.")
    @Default("0.5")
    val density: Var<Double> = ConstVar(0.5),
    @MaterialProperties(MaterialProperty.BLOCK)
    @Help("The block the wall is built from on the player's client.")
    @Default("\"BARRIER\"")
    val block: Var<Material> = ConstVar(Material.BARRIER),
    @Help("Render the full boundary, or only a window near the player.")
    @Default("""{"case":"near_boundary","value":{"radius":6.0}}""")
    val area: BoundaryRenderArea = NearBoundary(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay =
        RegionBoundaryFakeBlockDisplay(region, density, area, id, block)
}

private data class CachedBlocks(
    val transformHash: Int,
    val window: NearWindow?,
    val material: Material,
    val density: Double,
    val sent: ObjectOpenHashSet<Position>,
    val sentKeys: LongOpenHashSet,
    val worldId: String?,
)

class RegionBoundaryFakeBlockDisplay(
    region: RegionData,
    private val density: Var<Double>,
    area: BoundaryRenderArea,
    entryId: String?,
    private val block: Var<Material>,
) : RegionBoundaryDisplay(region, area, entryId) {
    private val cached = ConcurrentHashMap<UUID, CachedBlocks>()
    private val protections = ConcurrentHashMap<UUID, InterceptionBundle>()
    private val rebuilding = ConcurrentHashMap.newKeySet<UUID>()

    @Volatile
    private var disposed = false

    override fun onDisplayPlayerRemoved(player: Player) {
        protections.remove(player.uniqueId)?.cancel()
        cached.remove(player.uniqueId)?.let { state -> Dispatchers.Sync.launch { restore(player, state) } }
    }

    /**
     * Choosing which blocks the wall may replace, and reading the real blocks back to restore
     * them, are world reads, and this display ticks off the main thread. The rebuild therefore
     * runs on the main thread, guarded so the next tick does not start a second one on top.
     */
    override fun renderForPlayer(player: Player, tracker: RegionTracker, transform: ResolvedTransform) {
        val transformHash = transform.hashCode()
        val material = block.get(player)
        val window = nearWindow(player)
        val density = density.get(player)
        val existing = cached[player.uniqueId]
        if (existing != null &&
            existing.transformHash == transformHash &&
            existing.material == material &&
            existing.window == window &&
            existing.density == density
        ) return

        if (disposed) return
        if (!rebuilding.add(player.uniqueId)) return
        Dispatchers.Sync.launch {
            try {
                // The membership is checked again after the hop: the player can leave the audience, or the whole
                // display can be torn down, while it is queued. A rebuild landing after that
                // leaves a wall on their client that nothing restores, since teardown only
                // walks the blocks it knew about at the time.
                if (!disposed && player.isOnline && player in this@RegionBoundaryFakeBlockDisplay) {
                    rebuild(player, tracker, transform, transformHash, material, window, density)
                }
            } finally {
                rebuilding.remove(player.uniqueId)
            }
        }
    }

    /** Samples the world and diffs the sent blocks against the new set. Main thread only. */
    private fun rebuild(
        player: Player,
        tracker: RegionTracker,
        transform: ResolvedTransform,
        transformHash: Int,
        material: Material,
        window: NearWindow?,
        density: Double,
    ) {
        val existing = cached[player.uniqueId]
        val desired = ObjectOpenHashSet<Position>()
        val desiredKeys = LongOpenHashSet()
        for (local in tracker.shape.sampleBoundary(density)) {
            val pos = transform.toWorldPosition(local).toBlockPosition()
            if (pos in desired) continue
            if (window != null && !window.contains(pos.x + 0.5, pos.y + 0.5, pos.z + 0.5)) continue
            if (!isReplaceable(pos)) continue
            desired.add(pos)
            desiredKeys.add(packBlockKey(pos.blockX, pos.blockY, pos.blockZ))
        }

        val materialChanged = existing == null || existing.material != material
        val previous: Set<Position> = existing?.sent ?: emptySet()
        for (pos in desired) {
            if (materialChanged || pos !in previous) sendBlockChange(player, pos, material)
        }
        for (pos in previous) {
            if (pos !in desired) restoreBlock(player, pos)
        }
        cached[player.uniqueId] =
            CachedBlocks(transformHash, window, material, density, desired, desiredKeys, transform.world.identifier)
        if (desired.isNotEmpty()) ensureClickProtection(player)
    }

    /**
     * The client predicts breaking and placing against the blocks it has been sent, and while
     * a prediction is pending it buffers server block updates for that position instead of
     * applying them, until the server acknowledges the action's sequence number. Cancelling
     * the packet alone would suppress that acknowledgement and the hole would stay, so the
     * protection acknowledges the sequence itself and then sends the fake block again.
     */
    private fun ensureClickProtection(player: Player) {
        protections.computeIfAbsent(player.uniqueId) { playerId ->
            player.interceptPackets {
                PacketType.Play.Client.PLAYER_DIGGING { event ->
                    val packet = WrapperPlayClientPlayerDigging(event)
                    if (packet.action !in DIG_ACTIONS) return@PLAYER_DIGGING
                    val target = packet.blockPosition
                    val state = fakeBlockState(playerId, player, target.x, target.y, target.z) ?: return@PLAYER_DIGGING
                    event.isCancelled = true
                    acknowledgeSequence(player, packet.sequence)
                    resendFakeBlock(player, target.x, target.y, target.z, state.material)
                }
                PacketType.Play.Client.PLAYER_BLOCK_PLACEMENT { event ->
                    val packet = WrapperPlayClientPlayerBlockPlacement(event)
                    val target = packet.blockPosition
                    val state =
                        fakeBlockState(playerId, player, target.x, target.y, target.z) ?: return@PLAYER_BLOCK_PLACEMENT
                    event.isCancelled = true
                    acknowledgeSequence(player, packet.sequence)
                    resendFakeBlock(player, target.x, target.y, target.z, state.material)
                    resyncNeighborhood(playerId, player, target.x, target.y, target.z, state.material)
                }
            }
        }
    }

    private fun acknowledgeSequence(player: Player, sequence: Int) {
        if (sequence == 0) return
        WrapperPlayServerAcknowledgeBlockChanges(sequence).sendPacketTo(player)
    }

    /**
     * A chunk leaving the client's render distance drops its fake blocks with it; when the
     * server sends the chunk again, the wall inside it is sent again on top. Fired off the main
     * thread by Paper, which is fine: this only reads the cache and sends packets.
     */
    @EventHandler
    private fun onChunkLoad(event: PlayerChunkLoadEvent) {
        val state = cached[event.player.uniqueId] ?: return
        if (state.worldId != event.world.uid.toString()) return
        val chunkX = event.chunk.x
        val chunkZ = event.chunk.z
        for (pos in state.sent) {
            if (pos.blockX shr 4 != chunkX || pos.blockZ shr 4 != chunkZ) continue
            resendFakeBlock(event.player, pos.blockX, pos.blockY, pos.blockZ, state.material)
        }
    }

    private fun fakeBlockState(playerId: UUID, player: Player, x: Int, y: Int, z: Int): CachedBlocks? {
        val state = cached[playerId] ?: return null
        if (state.worldId != player.world.uid.toString()) return null
        if (packBlockKey(x, y, z) !in state.sentKeys) return null
        return state
    }

    private fun resendFakeBlock(player: Player, x: Int, y: Int, z: Int, material: Material) {
        WrapperPlayServerBlockChange(
            com.github.retrooper.packetevents.util.Vector3i(x, y, z),
            SpigotConversionUtil.fromBukkitBlockData(material.createBlockData()),
        ).sendPacketTo(player)
    }

    /**
     * A cancelled placement leaves the client's predicted block floating next to the fake
     * block. The neighbors are sent again with the server truth (or the fake material when the
     * neighbor is part of the wall) on the main thread, where world state may be read.
     */
    private fun resyncNeighborhood(playerId: UUID, player: Player, x: Int, y: Int, z: Int, material: Material) {
        server.scheduler.runTask(plugin) { ->
            val state = cached[playerId] ?: return@runTask
            for ((dx, dy, dz) in NEIGHBOR_OFFSETS) {
                val nx = x + dx
                val ny = y + dy
                val nz = z + dz
                if (packBlockKey(nx, ny, nz) in state.sentKeys) {
                    resendFakeBlock(player, nx, ny, nz, material)
                    continue
                }
                val location = Location(player.world, nx.toDouble(), ny.toDouble(), nz.toDouble())
                if (!location.isChunkLoaded) continue
                player.sendBlockChange(location, location.block.blockData)
            }
        }
    }

    private fun isReplaceable(pos: Position): Boolean {
        val location = pos.toBukkitLocation()
        return location.isChunkLoaded && !location.block.type.isSolid
    }

    private fun restore(player: Player, cached: CachedBlocks) {
        // A player who left the region's world already lost the wall with the chunks it stood
        // in, and every block change below carries coordinates without a world: sending them
        // now would paint the region's blocks into the world the player moved to.
        if (cached.worldId != player.world.uid.toString()) return
        for (pos in cached.sent) restoreBlock(player, pos)
    }

    private fun restoreBlock(player: Player, pos: Position) {
        val location = pos.toBukkitLocation()
        if (!location.isChunkLoaded) return
        sendBlockData(player, pos, location.block.blockData)
    }

    private fun sendBlockChange(player: Player, pos: Position, material: Material) =
        sendBlockData(player, pos, material.createBlockData())

    private fun sendBlockData(player: Player, pos: Position, data: BlockData) {
        WrapperPlayServerBlockChange(
            pos.toPacketVector3i(),
            SpigotConversionUtil.fromBukkitBlockData(data),
        ).sendPacketTo(player)
    }

    override fun dispose() {
        disposed = true
        protections.values.forEach(InterceptionBundle::cancel)
        protections.clear()
        val pending = players.mapNotNull { p -> cached.remove(p.uniqueId)?.let { p to it } }
        if (pending.isNotEmpty()) {
            Dispatchers.Sync.launch { for ((p, state) in pending) restore(p, state) }
        }
        super.dispose()
    }

    companion object {
        private val DIG_ACTIONS = setOf(
            DiggingAction.START_DIGGING,
            DiggingAction.CANCELLED_DIGGING,
            DiggingAction.FINISHED_DIGGING,
        )
        private val NEIGHBOR_OFFSETS = listOf(
            Triple(1, 0, 0), Triple(-1, 0, 0),
            Triple(0, 1, 0), Triple(0, -1, 0),
            Triple(0, 0, 1), Triple(0, 0, -1),
        )
    }
}

private fun Position.toBlockPosition(): Position {
    return Position(world, blockX.toDouble(), blockY.toDouble(), blockZ.toDouble(), 0f, 0f)
}

private fun packBlockKey(x: Int, y: Int, z: Int): Long =
    (x.toLong() and 0x3FFFFFF shl 38) or (z.toLong() and 0x3FFFFFF shl 12) or (y.toLong() and 0xFFF)
