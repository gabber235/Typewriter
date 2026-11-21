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
        boundaries.remove(player.uniqueId)?.entities?.dispose()
    }

    override fun renderForPlayer(player: Player, tracker: RegionTracker, transform: ResolvedTransform) {
        val definition = entityDefinition.get() ?: return
        // compute so a render in flight during teardown cannot install a boundary the sweep
        // has already walked past. Its entities would be fakes nobody owns and nobody can
        // despawn, since the display is out of the audience manager by then.
        val state = boundaries.compute(player.uniqueId) { _, previous ->
            if (disposed) return@compute null
            if (previous != null && previous.entities.definition === definition) return@compute previous
            previous?.entities?.dispose()
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

        state.entities.update(player, state.samples, nearWindow(player))
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
            iterator.next().value.entities.dispose()
            iterator.remove()
        }
        super.dispose()
    }

    /** One player's boundary: the samples it was last placed at and the entities standing there. */
    private class PlayerBoundary(definition: EntityDefinitionEntry) {
        val entities = BoundaryEntities(definition)
        var transformHash: Int? = null
        var density: Double? = null
        var localSamples: List<LocalSample> = emptyList()
        var samples: List<OrientedSample> = emptyList()
    }

    private class LocalSample(val local: Vector, val normal: Vector) {
        fun toWorld(transform: ResolvedTransform): OrientedSample {
            val direction = transform.rotateLocalToWorld(normal)
            val yaw = Math.toDegrees(atan2(-direction.x, direction.z)).toFloat()
            val pitch = Math.toDegrees(asin(-direction.y.coerceIn(-1.0, 1.0))).toFloat()
            return OrientedSample(transform.toWorldPosition(local), yaw, pitch)
        }
    }

    private data class OrientedSample(val position: Position, val yaw: Float, val pitch: Float) : EntityPlacement {
        override val x: Double get() = position.x
        override val y: Double get() = position.y
        override val z: Double get() = position.z

        override fun positionProperty() = PositionProperty(position.world, position.x, position.y, position.z, yaw, pitch)
    }
}
