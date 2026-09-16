package com.typewritermc.region.entries.display

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.region.content.resolveBukkitWorld
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.tracker.RegionTracker
import it.unimi.dsi.fastutil.ints.IntOpenHashSet
import java.time.Duration
import java.time.Instant
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.roundToInt
import org.bukkit.World
import org.bukkit.entity.Player

@Entry("region_boundary_ground_entity", "Renders where a region meets the ground as fake entities", Colors.GREEN, "mdi:fence")
/**
 * Spawns one [FakeEntity], built from the configured [entityDefinition], along the line
 * where the region intersects the ground: on the walkable surface inside the region's
 * vertical span, right where the footprint ends. Each entity stands on the terrain and
 * faces away from the region. A hovering region, or one whose span holds no surface,
 * spawns nothing.
 *
 * Entities are distributed evenly along the line, one per [spacing] blocks with identical
 * gaps in between, and every corner of the footprint gets its own entity. Keep the spacing
 * generous, every entity is network tracked. The terrain is resampled every couple of
 * seconds, and immediately when the region moves.
 *
 * With an [animation] the entities walk the line at the configured speed instead of standing
 * still, and the corner points give way to even gaps, since a moving entity cannot stay on a
 * corner.
 *
 * ## How could this be used?
 *
 * Fence off a ritual circle with candle or crystal entities standing on the grass, or line
 * the border of a contested zone with banner carriers that follow the hills.
 */
class RegionBoundaryGroundEntityDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The region whose ground line to populate with entities.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
    @Help("Blocks between entities along the ground line.")
    @Default("3.0")
    val spacing: Var<Double> = ConstVar(3.0),
    @Help("The entity definition to spawn along the ground line.")
    val entityDefinition: Ref<EntityDefinitionEntry> = emptyRef(),
    @Help("Whether the entities stand still or flow around the region, and how fast.")
    @Default("""{"case":"static","value":{}}""")
    val animation: GroundLineAnimation = StaticGroundLine(),
    @Help("Which way the entities look.")
    @Default("""{"case":"outward","value":{}}""")
    val facing: GroundLineFacing = FaceOutward(),
    @Help("Render the full ground line, or only a window near the player.")
    val area: BoundaryRenderArea = FullBoundary(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay =
        RegionBoundaryGroundEntityDisplay(region, area, id, spacing, entityDefinition, animation, facing)
}

class RegionBoundaryGroundEntityDisplay(
    region: RegionData,
    area: BoundaryRenderArea,
    entryId: String?,
    private val spacing: Var<Double>,
    private val entityDefinition: Ref<EntityDefinitionEntry>,
    private val animation: GroundLineAnimation,
    private val facing: GroundLineFacing,
) : RegionBoundaryDisplay(region, area, entryId) {
    private val lines = ConcurrentHashMap<UUID, PlayerGroundLine>()
    private val caches = GroundCachePool()
    private val startedAt: Instant = Instant.now()

    @Volatile
    private var disposed = false

    override fun onDisplayPlayerRemoved(player: Player) {
        lines.remove(player.uniqueId)?.disposeEntities()
        caches.forget(player.uniqueId)
    }

    override fun renderForPlayer(player: Player, tracker: RegionTracker, transform: ResolvedTransform) {
        val definition = entityDefinition.get() ?: return
        // compute so a render in flight during teardown cannot install a line the sweep has
        // already walked past. Its entities would be fakes nobody owns and nobody can
        // despawn, since the display is out of the audience manager by then.
        val state = lines.compute(player.uniqueId) { _, previous ->
            if (disposed) return@compute null
            if (previous != null && previous.definition === definition) return@compute previous
            previous?.disposeEntities()
            PlayerGroundLine(definition)
        } ?: return

        val world = resolveBukkitWorld(transform.world.identifier)
        if (world == null || world.uid != player.world.uid) {
            // The line leaves the map as well as being disposed: disposal is one way, and a line left in the map
            // would refuse every entity for the rest of the player's membership while still
            // spawning and destroying one per sample per tick.
            lines.remove(player.uniqueId)?.disposeEntities()
            return
        }

        val now = Instant.now()
        val cache = caches.cacheFor(tracker, player.uniqueId)
        val samples = if (animation is StaticGroundLine) {
            val step = spacing.get(player)
            val sampled = cache.resampledFor(tracker.shape, transform, world, now, step)
            // The spacing belongs in the key as much as the sampling does. It is a per player
            // variable, and the cache hands back the unspaced outline while another player's
            // sampling is still being built, so a stamp on its own would pin one player to a line
            // built at somebody else's spacing until the terrain is walked again.
            if (state.samplesStamp != sampled.stamp || state.samplesSpacing != step) {
                state.samplesStamp = sampled.stamp
                state.samplesSpacing = step
                GroundLinePath(sampled.points).vertices.map { GroundSample(transform, it, facing, 1) }
            } else {
                state.samples
            }
        } else {
            animatedSamples(player, cache, tracker.shape, transform, world, now)
        }
        state.samples = samples

        reconcile(player, state)

        for (entity in state.entities.values) {
            entity.consumeProperties(entity.collectors.mapNotNull { it.collect(player) })
            entity.entity.tick()
        }
    }

    /**
     * The entities spread evenly around the loop by arc length and walked along it. Slots keep
     * their index as they wrap, so an entity keeps its identity all the way around, and a slot
     * whose arc falls in a hole in the line has no sample until it walks out of it.
     */
    private fun animatedSamples(
        player: Player,
        cache: GroundOutlineCache,
        shape: Shape,
        transform: ResolvedTransform,
        world: World,
        now: Instant,
    ): List<GroundSample?> {
        val path = cache.pathFor(shape, transform, world, now)
        if (path.totalArc < 1e-6) return emptyList()

        val gap = spacing.get(player).coerceAtLeast(MIN_SPACING)
        val slots = (path.totalArc / gap).roundToInt().coerceAtLeast(1)
        val phase = groundLinePhase(animation, path, player, Duration.between(startedAt, now))
        val travel = animation.direction(path)

        return (0 until slots).map { slot ->
            val arc = slot * path.totalArc / slots + phase
            path.pointAt(arc)?.let { GroundSample(transform, it, facing, travel) }
        }
    }

    /**
     * Diffs the entities against the samples visible in the window, keyed by sample index.
     * On the static path the index is ordered by angle around the region, so unchanged
     * terrain keeps every index at the same spot and resampling sends no packets. On the
     * animated path the index is a fixed slot on the loop instead, and its position changes
     * every tick.
     */
    private fun reconcile(player: Player, state: PlayerGroundLine) {
        val window = nearWindow(player)
        val samples = state.samples
        val active = IntOpenHashSet()
        for (index in samples.indices) {
            val position = samples[index]?.position ?: continue
            if (window == null || window.contains(position.x, position.y, position.z)) active.add(index)
        }

        val iterator = state.entities.entries.iterator()
        while (iterator.hasNext()) {
            val entry = iterator.next()
            if (entry.key in active) continue
            entry.value.entity.dispose()
            iterator.remove()
        }

        val activeIterator = active.intIterator()
        while (activeIterator.hasNext()) {
            val index = activeIterator.nextInt()
            if (state.entities.containsKey(index)) continue
            val sample = samples[index] ?: continue
            val entity = state.definition.create(player)
            entity.spawn(sample.positionProperty())
            if (!state.track(index, BoundEntity(entity, state.collectorsFor(index)))) entity.dispose()
        }
    }

    override fun dispose() {
        disposed = true
        val iterator = lines.entries.iterator()
        while (iterator.hasNext()) {
            iterator.next().value.disposeEntities()
            iterator.remove()
        }
        caches.clear()
        super.dispose()
    }

    private class BoundEntity(
        val entity: FakeEntity,
        val collectors: List<PropertyCollector<EntityProperty>>,
    ) {
        fun consumeProperties(properties: List<EntityProperty>) = entity.consumeProperties(properties)
    }

    /**
     * One player's line of fake entities.
     *
     * Rendering runs off the main thread while removal from the audience and a reload both
     * dispose from another, so the map is concurrent and disposal is one way: once swept,
     * the line never accepts another entity. Without that, an entity spawned just after the
     * sweep survives as a fake nobody owns and nobody can despawn.
     */
    private class PlayerGroundLine(val definition: EntityDefinitionEntry) {
        var samples: List<GroundSample?> = emptyList()
        var samplesStamp: Instant = Instant.EPOCH
        var samplesSpacing: Double? = null
        val entities = ConcurrentHashMap<Int, BoundEntity>()

        @Volatile
        private var disposed = false

        fun collectorsFor(index: Int): List<PropertyCollector<EntityProperty>> {
            val position = FakeProvider(PositionProperty::class) { samples.getOrNull(index)?.positionProperty() }
            return (definition.data.withPriority() + (position to Int.MAX_VALUE)).toCollectors()
        }

        /** `false` when the line was already disposed, leaving [entity] to the caller. */
        fun track(index: Int, entity: BoundEntity): Boolean {
            var accepted = false
            entities.compute(index) { _, previous ->
                previous?.entity?.dispose()
                if (disposed) return@compute null
                accepted = true
                entity
            }
            return accepted
        }

        fun disposeEntities() {
            disposed = true
            val iterator = entities.entries.iterator()
            while (iterator.hasNext()) {
                iterator.next().value.entity.dispose()
                iterator.remove()
            }
        }
    }

    private class GroundSample(
        transform: ResolvedTransform,
        point: PathPoint,
        facing: GroundLineFacing,
        travelDirection: Int,
    ) {
        private val world = transform.world
        val position: Vector = point.position
        private val yaw: Float = facing.yaw(point, travelDirection)

        fun positionProperty() = PositionProperty(world, position.x, position.y, position.z, yaw, 0f)
    }
}

private const val MIN_SPACING = 0.5
