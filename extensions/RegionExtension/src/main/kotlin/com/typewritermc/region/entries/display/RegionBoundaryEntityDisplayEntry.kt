package com.typewritermc.region.entries.display

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.shape.Shape
import com.typewritermc.region.shape.averageUnitDirection
import com.typewritermc.region.tracker.RegionTracker
import it.unimi.dsi.fastutil.ints.IntOpenHashSet
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.asin
import kotlin.math.atan2
import org.bukkit.entity.Player

@Entry("region_boundary_entity", "Renders a region's boundary as fake entities", Colors.GREEN, "mdi:account-multiple")
/**
 * Spawns one [FakeEntity], built from the configured [entityDefinition], at every sampled
 * point on the region's boundary, per audience player. The definition's data (skin,
 * equipment, pose) is applied and kept up to date, and each entity faces along the
 * boundary's outward normal at its point, looking away from the region.
 *
 * The default density is much lower than for particle or fake block displays because each
 * sample is a network tracked fake entity, and the spawn rate is the dominant cost. The
 * default 0.05 puts fifteen entities on a 5 block sphere.
 *
 * The display caches the entities per player and diffs them against the samples visible in
 * the window. Each entity's position is fed through its property collector pipeline at top
 * priority, so a static boundary costs only the initial spawn and a moving boundary sends
 * only the packets the position diff requires.
 *
 * ## How could this be used?
 *
 * Visualize a safe zone with floating marker NPCs along the boundary, or hint at a hidden
 * trigger by sprinkling crystal entities along its perimeter.
 */
class RegionBoundaryEntityDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The region whose boundary to populate with entities.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
    @Help("Samples per unit boundary area. Entity displays cost more than particles, so keep this low. Zero is not off: every boundary gets at least eight samples.")
    @Default("0.05")
    val density: Var<Double> = ConstVar(0.05),
    @Help("The entity definition to spawn at each boundary sample.")
    val entityDefinition: Ref<EntityDefinitionEntry> = emptyRef(),
    @Help("Render the full boundary, or only a window near the player.")
    val area: BoundaryRenderArea = FullBoundary(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay =
        RegionBoundaryEntityDisplay(region, density, area, id, entityDefinition)
}

class RegionBoundaryEntityDisplay(
    region: RegionData,
    private val density: Var<Double>,
    area: BoundaryRenderArea,
    entryId: String?,
    private val entityDefinition: Ref<EntityDefinitionEntry>,
) : RegionBoundaryDisplay(region, area, entryId) {
    private val boundaries = ConcurrentHashMap<UUID, PlayerBoundary>()

    @Volatile
    private var disposed = false

    override fun onDisplayPlayerRemoved(player: Player) {
        boundaries.remove(player.uniqueId)?.disposeEntities()
    }

    override fun renderForPlayer(player: Player, tracker: RegionTracker, transform: ResolvedTransform) {
        val definition = entityDefinition.get() ?: return
        // compute so a render in flight during teardown cannot install a boundary the sweep
        // has already walked past. Its entities would be fakes nobody owns and nobody can
        // despawn, since the display is out of the audience manager by then.
        val state = boundaries.compute(player.uniqueId) { _, previous ->
            if (disposed) return@compute null
            if (previous != null && previous.definition === definition) return@compute previous
            previous?.disposeEntities()
            PlayerBoundary(definition)
        } ?: return

        val density = density.get(player)
        if (state.density != density) {
            state.localSamples = localSamples(tracker.shape, density)
            state.density = density
            state.transformHash = null
        }
        val transformHash = transform.hashCode()
        if (state.transformHash != transformHash) {
            state.samples = state.localSamples.map { it.toWorld(transform) }
            state.transformHash = transformHash
        }

        state.window = nearWindow(player)
        reconcile(player, state)

        for (entity in state.entities.values) {
            entity.consumeProperties(entity.collectors.mapNotNull { it.collect(player) })
            entity.entity.tick()
        }
    }

    /**
     * Diffs the entities against the samples visible in the window, keyed by sample index.
     * Removed samples dispose their entity and new samples spawn one. Position updates for
     * surviving samples flow through each entity's collector pipeline, which diffs
     * internally and sends nothing when the sample did not move.
     */
    private fun reconcile(player: Player, state: PlayerBoundary) {
        val window = state.window
        val samples = state.samples
        val active = IntOpenHashSet()
        for (index in samples.indices) {
            val position = samples[index].position
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
            val entity = state.definition.create(player)
            entity.spawn(samples[index].positionProperty())
            if (!state.track(index, BoundEntity(entity, state.collectorsFor(index)))) entity.dispose()
        }
    }

    /**
     * The boundary samples in the region's own frame, each with its outward normal. Sampling the
     * shape is the expensive half of placing the entities and depends on the density alone, so a
     * region that moves every tick only pays for turning these into world positions.
     */
    private fun localSamples(shape: Shape, density: Double): List<LocalSample> =
        shape.sampleBoundary(density).map { local ->
            LocalSample(local, averageUnitDirection(shape.outwardNormals(local)) ?: Vector(0.0, 0.0, 1.0))
        }.toList()

    override fun dispose() {
        disposed = true
        val iterator = boundaries.entries.iterator()
        while (iterator.hasNext()) {
            iterator.next().value.disposeEntities()
            iterator.remove()
        }
        super.dispose()
    }

    /**
     * A fake entity together with its collector pipeline: the definition's data plus a
     * [FakeProvider] that supplies the entity's boundary sample position at top priority.
     */
    private class BoundEntity(
        val entity: FakeEntity,
        val collectors: List<PropertyCollector<EntityProperty>>,
    ) {
        fun consumeProperties(properties: List<EntityProperty>) = entity.consumeProperties(properties)
    }

    /**
     * One player's ring of fake entities.
     *
     * Rendering runs off the main thread while removal from the audience and a reload both
     * dispose from another, so the map is concurrent and disposal is one way: once swept,
     * the boundary never accepts another entity. Without that, an entity spawned just after
     * the sweep survives as a fake nobody owns and nobody can despawn.
     */
    private class PlayerBoundary(val definition: EntityDefinitionEntry) {
        var transformHash: Int? = null
        var density: Double? = null
        var localSamples: List<LocalSample> = emptyList()
        var samples: List<OrientedSample> = emptyList()
        var window: NearWindow? = null
        val entities = ConcurrentHashMap<Int, BoundEntity>()

        @Volatile
        private var disposed = false

        fun collectorsFor(index: Int): List<PropertyCollector<EntityProperty>> {
            val position = FakeProvider(PositionProperty::class) { samples.getOrNull(index)?.positionProperty() }
            return (definition.data.withPriority() + (position to Int.MAX_VALUE)).toCollectors()
        }

        /** `false` when the boundary was already disposed, leaving [entity] to the caller. */
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

    private class LocalSample(val local: Vector, val normal: Vector) {
        fun toWorld(transform: ResolvedTransform): OrientedSample {
            val direction = transform.rotateLocalToWorld(normal)
            val yaw = Math.toDegrees(atan2(-direction.x, direction.z)).toFloat()
            val pitch = Math.toDegrees(asin(-direction.y.coerceIn(-1.0, 1.0))).toFloat()
            return OrientedSample(transform.toWorldPosition(local), yaw, pitch)
        }
    }

    private data class OrientedSample(val position: Position, val yaw: Float, val pitch: Float) {
        fun positionProperty() = PositionProperty(position.world, position.x, position.y, position.z, yaw, pitch)
    }
}
