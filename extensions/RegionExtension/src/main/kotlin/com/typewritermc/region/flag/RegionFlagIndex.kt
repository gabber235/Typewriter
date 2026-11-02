package com.typewritermc.region.flag

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.region.RegionEngine
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.entries.modifier.AllowanceModifierEntry
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.tracker.RegionTracker
import com.typewritermc.region.tracker.WorldAabb
import com.typewritermc.core.entries.ref
import it.unimi.dsi.fastutil.longs.Long2ObjectOpenHashMap
import org.bukkit.entity.Player
import kotlin.reflect.KClass

/** How many chunks a region may span before it is scanned instead of indexed. */
const val MAX_INDEXED_CHUNKS = 1024L

/**
 * One region that carries flags, resolved once at load.
 *
 * [tracker] and [aabb] are `null` for a variable placement region: it exists only per viewer and
 * moves, so it cannot be resolved or indexed ahead of time.
 *
 * [order] is the region's position once the definitions are sorted by entry id. It breaks ties
 * between equal priorities, and the region later in that order wins. Page files are read in an
 * order the filesystem decides, so load order itself is not stable across restarts.
 */
internal class FlaggedRegion(
    val entry: RegionDefinitionEntry,
    val priority: Int,
    val order: Int,
    val modifiers: Map<KClass<out RegionModifierEntry>, RegionModifierEntry>,
    val tracker: RegionTracker?,
    val aabb: WorldAabb?,
)

/** A flag, and the region whose priority won it the decision. */
data class FlagDecision<M : RegionModifierEntry>(
    val flag: M,
    val regionName: String,
    val priority: Int,
    val order: Int,
)

/**
 * Which region decides about a given block.
 *
 * Constant placement regions are indexed by the chunks their footprint touches, so a block in a
 * chunk no region reaches costs one hash miss. The index exists for that case: ten thousand
 * regions on the server, with a redstone contraption running somewhere none of them reach.
 *
 * A region whose footprint spans more than [MAX_INDEXED_CHUNKS] would write thousands of index
 * entries, so it goes into a bucket that is scanned instead. A handful of huge regions cost a
 * handful of AABB tests; the ten thousand normal ones stay a hash lookup.
 *
 * Variable placement regions cannot be indexed and are resolved per player through the engine's
 * query cache. Without a player they are skipped, which is why a piston or a redstone tick never
 * sees them.
 */
class RegionFlagIndex internal constructor(
    regions: List<FlaggedRegion>,
    private val engine: RegionEngine?,
) {
    private val chunks = HashMap<World, Long2ObjectOpenHashMap<MutableList<FlaggedRegion>>>()
    private val oversized = mutableListOf<FlaggedRegion>()
    private val dynamic = mutableListOf<FlaggedRegion>()

    /**
     * Regions examined by the last [resolve] call. Diagnostics only: a test asserts that an
     * empty chunk touches none, and a concurrent lookup may overwrite it in between. The field
     * is plain rather than volatile because every flag lookup writes it, including the ones on
     * a redstone tick.
     */
    var candidatesTouched: Int = 0
        private set

    val oversizedCount: Int get() = oversized.size

    /**
     * Every constant placement candidate whose AABB contains [position]. Inline, so a lookup
     * allocates nothing: a piston resolves once per moved block and redstone once per state
     * change, and a block update in a chunk no region reaches costs one hash miss.
     */
    private inline fun forEachPositionalCandidate(
        position: Position,
        action: (FlaggedRegion, RegionTracker) -> Unit,
    ) {
        val indexed = chunks[position.world]
            ?.get(chunkKey(floorChunk(position.x), floorChunk(position.z)))
        if (indexed != null) {
            for (region in indexed) {
                val aabb = region.aabb ?: continue
                if (!aabb.contains(position)) continue
                action(region, region.tracker ?: continue)
            }
        }

        for (region in oversized) {
            val aabb = region.aabb ?: continue
            if (aabb.world != position.world || !aabb.contains(position)) continue
            action(region, region.tracker ?: continue)
        }
    }

    private fun positionalCandidates(position: Position): List<Pair<FlaggedRegion, RegionTracker>> {
        val result = mutableListOf<Pair<FlaggedRegion, RegionTracker>>()
        forEachPositionalCandidate(position) { region, tracker -> result += region to tracker }
        return result
    }

    /**
     * Every candidate worth testing for [position]: the constant placement regions found through
     * [positionalCandidates], plus every variable placement region resolved through the engine when
     * a [player] is given.
     */
    private fun candidates(position: Position, player: Player?): List<Pair<FlaggedRegion, RegionTracker>> {
        val result = positionalCandidates(position).toMutableList()
        if (player != null) {
            for (region in dynamic) {
                val tracker = engine?.query(RegionReferenceData(region.entry.ref()), player) ?: continue
                result += region to tracker
            }
        }
        return result
    }

    init {
        for (region in regions) {
            val aabb = region.aabb
            if (aabb == null || region.tracker == null) {
                dynamic += region
                continue
            }

            val span = (aabb.maxChunkX - aabb.minChunkX + 1).toLong() *
                    (aabb.maxChunkZ - aabb.minChunkZ + 1).toLong()
            if (span > MAX_INDEXED_CHUNKS) {
                oversized += region
                continue
            }

            val world = chunks.getOrPut(aabb.world) { Long2ObjectOpenHashMap() }
            for (chunkX in aabb.minChunkX..aabb.maxChunkX) {
                for (chunkZ in aabb.minChunkZ..aabb.maxChunkZ) {
                    world.computeIfAbsent(chunkKey(chunkX, chunkZ)) { mutableListOf() }.add(region)
                }
            }
        }
    }

    /**
     * The flag of type [type] belonging to the highest priority region that both contains
     * [position] and carries such a flag, or `null` when no region decides.
     *
     * A [player] is needed to resolve variable placement regions. Without one they are skipped.
     */
    fun <M : RegionModifierEntry> resolve(type: KClass<M>, position: Position, player: Player?): M? =
        resolveDecision(type, position, player)?.flag

    /**
     * The flag of type [type] belonging to the highest priority region that both contains
     * [position] and carries such a flag, together with the region that decided it.
     *
     * A [player] is needed to resolve variable placement regions. Without one they are skipped.
     *
     * [decides] filters out flags that have nothing to say about the case at hand, so a narrow
     * flag on top of a broad one defers to it instead of nullifying it. A damage flag limited
     * to fall damage must not switch off the hub's blanket flag for lava.
     */
    fun <M : RegionModifierEntry> resolveDecision(
        type: KClass<M>,
        position: Position,
        player: Player?,
        decides: (M) -> Boolean = { true },
    ): FlagDecision<M>? {
        val best = bestRegion(type, position, player, decides) ?: return null

        @Suppress("UNCHECKED_CAST")
        val flag = best.modifiers[type] as M
        return FlagDecision(flag, best.entry.name, best.priority, best.order)
    }

    /** Every flagged region containing [position], highest priority first. */
    internal fun regionsAt(position: Position, player: Player?): List<FlaggedRegion> =
        candidates(position, player)
            .filter { (_, tracker) -> tracker.isInside(position) }
            .map { (region, _) -> region }
            .sortedWith(compareByDescending<FlaggedRegion> { it.priority }.thenByDescending { it.order })

    private fun <M : RegionModifierEntry> bestRegion(
        type: KClass<M>,
        position: Position,
        player: Player?,
        decides: (M) -> Boolean,
    ): FlaggedRegion? {
        var touched = 0
        var best: FlaggedRegion? = null

        @Suppress("UNCHECKED_CAST")
        fun decidingFlag(region: FlaggedRegion): Boolean {
            val flag = region.modifiers[type] as? M ?: return false
            return decides(flag)
        }

        forEachPositionalCandidate(position) { region, tracker ->
            touched += 1
            if (decidingFlag(region) && tracker.isInside(position)) {
                val current = best
                if (current == null || beats(region, current)) best = region
            }
        }

        if (player != null) {
            for (region in dynamic) {
                if (!decidingFlag(region)) continue
                val tracker = engine?.query(RegionReferenceData(region.entry.ref()), player) ?: continue
                touched += 1
                if (!tracker.isInside(position)) continue
                if (best == null || beats(region, best)) best = region
            }
        }

        candidatesTouched = touched
        return best
    }

    private fun beats(candidate: FlaggedRegion, current: FlaggedRegion): Boolean {
        if (candidate.priority != current.priority) return candidate.priority > current.priority
        return candidate.order > current.order
    }
}

/**
 * Whether the flag of type [type] deciding about [position] allows the event, and `true` when no
 * region decides about it at all.
 *
 * A flag whose allowance is bound to a variable cannot answer without a [player], and events like a
 * crop growing or sand coming to rest have none. Such a flag abstains and the region below it
 * decides, the same way a region whose placement cannot resolve does. Reading the unresolved
 * allowance as a denial instead stops every natural process inside the region, whichever way the
 * variable would have gone, and says so nowhere.
 */
fun <M : AllowanceModifierEntry> RegionFlagIndex.allows(
    type: KClass<M>,
    position: Position,
    player: Player?,
): Boolean {
    if (player != null) return resolve(type, position, player)?.allowed?.get(player) != false
    val flag = resolveDecision(type, position, null) { it.allowed.get(null) != null }?.flag ?: return true
    return flag.allowed.get(null) == true
}

private fun floorChunk(coordinate: Double): Int = Math.floorDiv(Math.floor(coordinate).toInt(), 16)

private fun chunkKey(chunkX: Int, chunkZ: Int): Long =
    (chunkX.toLong() shl 32) or (chunkZ.toLong() and 0xFFFFFFFFL)
