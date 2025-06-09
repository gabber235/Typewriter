package com.typewritermc.roadnetwork.gps

import com.extollit.gaming.ai.path.HydrazinePathFinder
import com.extollit.gaming.ai.path.model.Passibility
import com.extollit.linalg.immutable.Vec3d
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.distanceSqrt
import com.typewritermc.engine.paper.entry.descendants
import com.typewritermc.engine.paper.entry.entity.toProperty
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.inAudience
import com.typewritermc.engine.paper.utils.firstWalkableLocationBelow
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.RoadNetworkManager
import com.typewritermc.roadnetwork.entries.displays.TotemPathStreamDisplay
import com.typewritermc.roadnetwork.pathfinding.PFEmptyEntity
import com.typewritermc.roadnetwork.pathfinding.instanceSpace
import com.typewritermc.roadnetwork.roadNetworkMaxDistance
import kotlinx.coroutines.*
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.time.Duration
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass
import kotlin.time.Duration.Companion.seconds

class SinglePathStreamDisplay(
    private val ref: Ref<RoadNetworkEntry>,
    private val display: (Player) -> Ref<PathStreamDisplayEntry<*>>,
    private val startPosition: (Player) -> Position = Player::position,
    private val endPosition: (Player) -> Position,
) : AudienceDisplay(), TickableDisplay {
    private val displays = ConcurrentHashMap<UUID, PathStreamDisplay>()
    override fun onPlayerAdd(player: Player) {
        val entry = display(player).get()
        displays[player.uniqueId] =
            entry?.createDisplay(ref, player, startPosition, endPosition) ?: TotemPathStreamDisplay(
                ref,
                player,
                startPosition,
                endPosition
            )
    }

    override fun onPlayerRemove(player: Player) {
        displays.remove(player.uniqueId)?.dispose()
    }

    override fun tick() {
        players.forEach { player ->
            displays.computeIfPresent(player.uniqueId) { _, display ->
                val entry = this.display(player).get()
                val klass = entry?.klass ?: TotemPathStreamDisplay::class
                if (klass.isInstance(display)) {
                    display.tick()
                    return@computeIfPresent display
                }

                display.dispose()
                (entry?.createDisplay(ref, player, startPosition, endPosition) ?: TotemPathStreamDisplay(
                    ref,
                    player,
                    startPosition,
                    endPosition
                )).apply { tick() }
            }
        }
        displays.values.forEach {
            it.tick()
        }
    }
}

class MultiPathStreamDisplay(
    private val ref: Ref<RoadNetworkEntry>,
    private val streams: (Player) -> List<StreamDisplay>,
) : AudienceDisplay(), TickableDisplay {
    private val displays = ConcurrentHashMap<UUID, MutableMap<String, PathStreamDisplay>>()

    override fun tick() {
        players.forEach { player ->
            displays.computeIfPresent(player.uniqueId) { _, displays ->
                val streams = streams(player).associateBy { it.id }
                streams.filter { it.key !in displays }.forEach { (key, stream) ->
                    displays[key] = stream.createDisplay(ref, player)
                }

                streams.mapNotNull {
                    val display = displays[it.key] ?: return@mapNotNull null
                    it.key to (it.value to display)
                }.forEach { (key, value) ->
                    val (stream, display) = value
                    val klass = stream.displayRef.get()?.klass ?: TotemPathStreamDisplay::class
                    if (klass.isInstance(display)) {
                        display.tick()
                        return@forEach
                    }
                    display.dispose()
                    displays[key] = stream.createDisplay(ref, player).apply { tick() }
                }

                displays.keys.filter { it !in streams }.forEach { key ->
                    displays.remove(key)?.dispose()
                }
                displays
            }
        }
    }

    override fun onPlayerAdd(player: Player) {
        displays.putIfAbsent(player.uniqueId, mutableMapOf())
    }

    override fun onPlayerRemove(player: Player) {
        displays.remove(player.uniqueId)?.forEach { it.value.dispose() }
    }
}

class StreamDisplay(
    val id: String,
    val displayRef: Ref<PathStreamDisplayEntry<*>>,
    val startPosition: (Player) -> Position = Player::position,
    val endPosition: (Player) -> Position,
) {
    fun createDisplay(ref: Ref<RoadNetworkEntry>, player: Player): PathStreamDisplay {
        return displayRef.get()?.createDisplay(ref, player, startPosition, endPosition) ?: TotemPathStreamDisplay(
            ref,
            player,
            startPosition,
            endPosition
        )
    }
}

@Tags("path_stream_display")
interface PathStreamDisplayEntry<PSD : PathStreamDisplay> : AudienceEntry {
    @Default("1700")
    @Help("The time between a new stream being calculated")
    val refreshDuration: Duration

    val klass: KClass<PSD>
    fun createDisplay(
        ref: Ref<RoadNetworkEntry>,
        player: Player,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position,
    ): PSD

    override suspend fun display(): AudienceDisplay = PassThroughDisplay()
}

fun Ref<out AudienceFilterEntry>.highestPathStreamDisplay(
    player: Player,
    or: Ref<PathStreamDisplayEntry<*>>
): Ref<PathStreamDisplayEntry<*>> =
    descendants(PathStreamDisplayEntry::class)
        .filter { player.inAudience(it) }
        .maxByOrNull { it.priority } ?: or

abstract class PathStreamDisplay(
    protected val ref: Ref<RoadNetworkEntry>,
    val player: Player,
    protected val startPosition: (Player) -> Position,
    protected val endPosition: (Player) -> Position,
    protected val refreshDuration: Duration,
) : KoinComponent {
    protected val roadNetworkManager: RoadNetworkManager by inject()

    protected val gps = PointToPointGPS(ref, { startPosition(player) }, { endPosition(player) })

    protected var lastRefresh = 0L
    protected var job: Job? = null

    abstract suspend fun refreshPath()
    abstract fun displayPath()

    fun tick() {
        if (job?.isActive == false) {
            lastRefresh = System.currentTimeMillis()
            job = null
        }
        if (job == null && (System.currentTimeMillis() - lastRefresh) > refreshDuration.toMillis()) {
            job = Dispatchers.UntickedAsync.launch {
                withTimeout(30.seconds) {
                    refreshPath()
                }
            }
        }

        displayPath()
    }

    open fun dispose() {
        job?.cancel()
        job = null
    }

    suspend fun calculatePathing(): Pair<List<GPSEdge>, List<List<Position>>>? {
        val (start, end) = points() ?: return null
        val edges = findEdges() ?: return null
        val visibleEdges = edges.filterVisible(start, end)
        val path = findPaths(visibleEdges) ?: return null
        return edges to path
    }

    fun points(): Pair<Position, Position>? {
        val start = startPosition(player).firstWalkableLocationBelow() ?: return null
        val end = endPosition(player).firstWalkableLocationBelow() ?: return null

        // When the start and end location are the same, we don't need to find a path.
        if ((start.distanceSqrt(end) ?: Double.MAX_VALUE) < 1) {
            return null
        }
        return start to end
    }

    suspend fun findEdges(): List<GPSEdge>? {
        return gps.findPath().getOrElse { emptyList() }
    }

    fun List<GPSEdge>.filterVisible(
        start: Position,
        end: Position,
    ) = filter {
        ((it.start.distanceSqrt(start) ?: Double.MAX_VALUE) < roadNetworkMaxDistance * roadNetworkMaxDistance
                || (it.end.distanceSqrt(start)
            ?: Double.MAX_VALUE) < roadNetworkMaxDistance * roadNetworkMaxDistance)
                ||
                ((it.start.distanceSqrt(end) ?: Double.MAX_VALUE) < roadNetworkMaxDistance * roadNetworkMaxDistance
                        || (it.end.distanceSqrt(end)
                    ?: Double.MAX_VALUE) < roadNetworkMaxDistance * roadNetworkMaxDistance)
    }

    suspend fun findPaths(
        edges: List<GPSEdge>,
    ): List<List<Position>>? = coroutineScope {
        edges
            .map { edge ->
                async {
                    findPath(edge.start, edge.end)
                }
            }
            .awaitAll()
            .map { positions -> positions.map { it.mid() } }
    }


    private suspend fun findPath(
        start: Position,
        end: Position,
    ): Iterable<Position> {
        val roadNetwork = roadNetworkManager.getNetwork(gps.roadNetwork)

        val interestingNegativeNodes = roadNetwork.negativeNodes.filter {
            val distance = start.distanceSqrt(it.position) ?: 0.0
            distance > it.radius * it.radius && distance < roadNetworkMaxDistance * roadNetworkMaxDistance
        }

        val entity = PFEmptyEntity(start.toProperty(), searchRange = roadNetworkMaxDistance.toFloat())
        val instance = start.world.instanceSpace
        val pathfinder = HydrazinePathFinder(entity, instance)

        val additionalRadius = pathfinder.subject().width().toDouble()

        // We want to avoid going through negative nodes
        pathfinder.withGraphNodeFilter { node ->
            if (node.isInRangeOf(interestingNegativeNodes, additionalRadius)) {
                return@withGraphNodeFilter Passibility.dangerous
            }
            node.passibility()
        }

        val path = pathfinder.computePathTo(Vec3d(end.x, end.y, end.z)) ?: return emptyList()
        return path.map {
            val coordinate = it.coordinates()
            Position(start.world, coordinate.x.toDouble(), coordinate.y.toDouble(), coordinate.z.toDouble())
        }
    }
}