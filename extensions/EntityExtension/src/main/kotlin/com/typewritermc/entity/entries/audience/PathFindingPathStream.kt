package com.typewritermc.entity.entries.audience

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entity.IndividualActivityContext
import com.typewritermc.engine.paper.entry.entity.toProperty
import com.typewritermc.entity.entries.activity.NavigationActivityTaskState
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.entries.*
import com.typewritermc.roadnetwork.gps.GPSEdge
import org.bukkit.entity.Player
import java.time.Duration

class PathFindingPathStreamProducer(
    player: Player,
    id: String,
    roadNetwork: Ref<RoadNetworkEntry>,
    startPosition: (Player) -> Position,
    endPosition: (Player) -> Position,
    refreshDuration: Duration,
    val speed: Double = 0.5,
    displaySupplier: PathStreamDisplaysSupplier
) : PathStreamProducer(player, id, roadNetwork, startPosition, endPosition, refreshDuration, displaySupplier) {
    constructor(
        player: Player,
        ref: Ref<PathStreamDisplayEntry>,
        roadNetwork: Ref<RoadNetworkEntry>,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position,
        refreshDuration: Duration = Duration.ofMillis(1200),
        speed: Double = 0.5,
        displayEntries: List<Ref<PathStreamDisplayEntry>>
    ) : this(
        player,
        ref.id,
        roadNetwork,
        startPosition,
        endPosition,
        refreshDuration,
        speed,
        { displayEntries.createDisplays(it) },
    )

    override suspend fun refreshPath(): PathStream? {
        val (start, end) = points() ?: return null
        val edges = findEdges() ?: return null
        val visibleEdges = edges.filterVisible(start, end)
        if (visibleEdges.isEmpty()) return null
        return PathFindingPathStream(
            displaySupplier(player),
            player,
            roadNetwork,
            visibleEdges,
            speed
        )
    }
}

class PathFindingPathStream(
    displays: List<PathStreamDisplay>,
    val player: Player,
    val roadNetwork: Ref<RoadNetworkEntry>,
    private val edges: List<GPSEdge>,
    private val speed: Double,
) : PathStream(displays) {
    private var navigator: NavigationActivityTaskState.Walking
    private var currentEdgeIndex = 0
        set(value) {
            field = value
            startTime = System.currentTimeMillis()
        }
    private val currentEdge: GPSEdge
        get() = edges[currentEdgeIndex.coerceIn(0 until edges.size)]

    init {
        require(edges.isNotEmpty()) { "There must be at least 1 edge for the entity to walk" }
        navigator = NavigationActivityTaskState.Walking(
            roadNetwork,
            currentEdge,
            currentEdge.start.toProperty(),
            speed.toFloat(),
            rotationLookAhead = 0,
        )
    }

    override fun forwardPath(): Position {
        require(currentEdgeIndex < edges.size) { "No more edges to walk on" }
        navigator.tick(IndividualActivityContext(emptyRef(), player, isViewed = true))
        val position = navigator.position().toPosition()

        if (!navigator.isComplete()) return position
        currentEdgeIndex++
        if (!shouldContinue()) return position
        navigator = NavigationActivityTaskState.Walking(
            roadNetwork,
            currentEdge,
            position.toProperty(),
            speed.toFloat(),
            rotationLookAhead = 0,
        )
        return position
    }

    override fun shouldContinue(): Boolean {
        return currentEdgeIndex < edges.size
    }

    override fun dispose() {
        super.dispose()
        navigator.dispose()
    }
}