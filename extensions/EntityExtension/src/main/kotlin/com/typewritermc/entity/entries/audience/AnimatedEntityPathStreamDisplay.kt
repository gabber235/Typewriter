package com.typewritermc.entity.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityDefinitionEntry
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.PropertyCollector
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.entity.entries.activity.NavigationActivityTaskState
import com.typewritermc.entity.entries.cinematic.FakeProvider
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.gps.GPSEdge
import com.typewritermc.roadnetwork.gps.PathStreamDisplay
import com.typewritermc.roadnetwork.gps.PathStreamDisplayEntry
import org.bukkit.entity.Player
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass

val entityDisplayTimeout by snippet(
    "entity.pathStream.display.animated.timeout",
    15_000,
    "When entities are force despawned after this amount of time in milliseconds"
)

@Entry(
    "animated_entity_path_stream_display",
    "An entity which moves along the path stream path",
    Colors.MYRTLE_GREEN,
    "material-symbols:move-location-rounded"
)
/**
 * This path display lets an entity follow the path stream path.
 */
class AnimatedEntityPathStreamDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    @Default("1200")
    override val refreshDuration: Duration = Duration.ofMillis(1200),
    @Help("How fast the stream travels in blocks per second")
    @Default("0.5")
    val speed: Double = 0.5,
    val definition: Ref<EntityDefinitionEntry> = emptyRef(),
) : PathStreamDisplayEntry<AnimatedEntityPathStreamDisplay> {
    override val klass: KClass<AnimatedEntityPathStreamDisplay> get() = AnimatedEntityPathStreamDisplay::class
    override fun createDisplay(
        ref: Ref<RoadNetworkEntry>,
        player: Player,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position
    ): AnimatedEntityPathStreamDisplay {
        val definitionEntry =
            definition.get() ?: throw IllegalArgumentException("Entity Definition was not defined on ${ref()}")
        return AnimatedEntityPathStreamDisplay(
            ref,
            player,
            startPosition,
            endPosition,
            refreshDuration,
            speed,
            definitionEntry
        )
    }
}

class AnimatedEntityPathStreamDisplay(
    ref: Ref<RoadNetworkEntry>,
    player: Player,
    startPosition: (Player) -> Position,
    endPosition: (Player) -> Position,
    refreshDuration: Duration,
    val speed: Double = 0.5,
    val definition: EntityDefinitionEntry,
) : PathStreamDisplay(ref, player, startPosition, endPosition, refreshDuration) {
    private val entities = ConcurrentHashMap<PathStreamFollower, Unit>()

    override suspend fun refreshPath() {
        val (start, end) = points() ?: return
        val edges = findEdges() ?: return
        val visibleEdges = edges.filterVisible(start, end)

        entities[PathStreamFollower(ref, player, visibleEdges, speed, definition)] = Unit
    }

    override fun displayPath() {
        entities.keys.retainAll { entity ->
            entity.tick()
            val retain = entity.shouldContinue()
            if (!retain) {
                entity.dispose()
            }
            retain
        }
    }

    override fun dispose() {
        super.dispose()
        entities.keys.forEach { it.dispose() }
        entities.clear()
    }
}

private class PathStreamFollower(
    val roadNetwork: Ref<RoadNetworkEntry>,
    private val player: Player,
    private val edges: List<GPSEdge>,
    private val speed: Double,
    definition: EntityDefinitionEntry,
) {
    private val entity: FakeEntity
    private val collectors: List<PropertyCollector<EntityProperty>>
    private var navigator: NavigationActivityTaskState.Walking
    private var position: PositionProperty

    private var startTime: Long = System.currentTimeMillis()
    private var currentEdgeIndex = 0
        set(value) {
            field = value
            startTime = System.currentTimeMillis()
        }
    private val currentEdge: GPSEdge
        get() = edges[currentEdgeIndex.coerceIn(0 until edges.size)]

    init {
        require(edges.isNotEmpty()) { "There must be at least 1 edge for the entity to walk" }
        position = currentEdge.start.toProperty()

        navigator = NavigationActivityTaskState.Walking(
            roadNetwork,
            currentEdge,
            position,
            speed.toFloat(),
            rotationLookAhead = 0,
        )

        val prioritizedPropertySuppliers = definition.data.withPriority() +
                (FakeProvider(PositionProperty::class) { position } to Int.MAX_VALUE)

        collectors = prioritizedPropertySuppliers.toCollectors()
        entity = definition.create(player)
        val collectedProperties = collectors.mapNotNull { it.collect(player) }
        entity.spawn(position)
        entity.consumeProperties(collectedProperties)
    }

    fun tick() {
        if (!shouldContinue()) return
        navigator.tick(IndividualActivityContext(emptyRef(), player, isViewed = true))
        position = navigator.position()

        val collectedProperties = collectors.mapNotNull { it.collect(player) }
        entity.consumeProperties(collectedProperties)
        entity.tick()

        if (!navigator.isComplete()) return

        currentEdgeIndex++
        if (!shouldContinue()) return
        navigator = NavigationActivityTaskState.Walking(
            roadNetwork,
            currentEdge,
            position,
            speed.toFloat(),
            rotationLookAhead = 0,
        )
    }

    fun shouldContinue(): Boolean {
        return currentEdgeIndex < edges.size && System.currentTimeMillis() - startTime < entityDisplayTimeout
    }

    fun dispose() {
        entity.dispose()
        navigator.dispose()
    }
}