package com.typewritermc.roadnetwork.entries

import com.extollit.gaming.ai.path.HydrazinePathFinder
import com.extollit.gaming.ai.path.model.Passibility
import com.extollit.linalg.immutable.Vec3d
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.distanceSqrt
import com.typewritermc.engine.paper.entry.descendants
import com.typewritermc.engine.paper.entry.entity.toProperty
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceFilterEntry
import com.typewritermc.engine.paper.entry.entries.PassThroughFilter
import com.typewritermc.engine.paper.entry.entries.TickableDisplay
import com.typewritermc.engine.paper.entry.inAudience
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.firstWalkableLocationBelow
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.RoadNetworkManager
import com.typewritermc.roadnetwork.gps.GPSEdge
import com.typewritermc.roadnetwork.gps.PointToPointGPS
import com.typewritermc.roadnetwork.gps.isInRangeOf
import com.typewritermc.roadnetwork.pathfinding.PFEmptyEntity
import com.typewritermc.roadnetwork.pathfinding.instanceSpace
import com.typewritermc.roadnetwork.roadNetworkMaxDistance
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.time.Duration
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import kotlin.time.Duration.Companion.seconds

class SinglePathStreamDisplay(
    private val roadNetwork: Ref<RoadNetworkEntry>,
    private val display: (Player) -> Ref<PathStreamDisplayEntry>,
    private val startPosition: (Player) -> Position = Player::position,
    private val endPosition: (Player) -> Position,
) : AudienceDisplay(), TickableDisplay {
    private val producers = ConcurrentHashMap<UUID, PathStreamProducer>()
    override fun onPlayerAdd(player: Player) {
        val entry = display(player).get()
        producers[player.uniqueId] =
            entry?.createProducer(player, roadNetwork, startPosition, endPosition) ?: LinePathStreamProducer(
                player = player,
                roadNetwork = roadNetwork,
                startPosition = startPosition,
                endPosition = endPosition
            )
    }

    override fun onPlayerRemove(player: Player) {
        producers.remove(player.uniqueId)?.dispose()
    }

    override fun tick() {
        players.forEach { player ->
            producers.computeIfPresent(player.uniqueId) { _, producer ->
                val entry = this.display(player).get()
                val id = entry?.id ?: ""
                if (producer.id == id) {
                    producer.tick()
                    return@computeIfPresent producer
                }

                producer.dispose()
                (entry?.createProducer(player, roadNetwork, startPosition, endPosition) ?: LinePathStreamProducer(
                    player = player,
                    roadNetwork = roadNetwork,
                    startPosition = startPosition,
                    endPosition = endPosition
                )).apply { tick() }
            }
        }
        producers.values.forEach {
            it.tick()
        }
    }
}

class MultiPathStreamDisplay(
    private val ref: Ref<RoadNetworkEntry>,
    private val streams: (Player) -> List<StreamProducer>,
) : AudienceDisplay(), TickableDisplay {
    private val producers = ConcurrentHashMap<UUID, MutableMap<String, PathStreamProducer>>()

    override fun tick() {
        players.forEach { player ->
            producers.computeIfPresent(player.uniqueId) { _, displays ->
                val streams = streams(player).associateBy { it.id }
                streams.filter { it.key !in displays }.forEach { (key, stream) ->
                    displays[key] = stream.createProducer(ref, player)
                }

                streams.mapNotNull {
                    val display = displays[it.key] ?: return@mapNotNull null
                    it.key to (it.value to display)
                }.forEach { (key, value) ->
                    val (stream, display) = value

                    if (stream.ref.id == display.id) {
                        display.tick()
                        return@forEach
                    }
                    display.dispose()
                    displays[key] = stream.createProducer(ref, player).apply { tick() }
                }

                displays.keys.filter { it !in streams }.forEach { key ->
                    displays.remove(key)?.dispose()
                }
                displays
            }
        }
    }

    override fun onPlayerAdd(player: Player) {
        producers.putIfAbsent(player.uniqueId, mutableMapOf())
    }

    override fun onPlayerRemove(player: Player) {
        producers.remove(player.uniqueId)?.forEach { it.value.dispose() }
    }
}

class StreamProducer(
    val id: String,
    val ref: Ref<PathStreamDisplayEntry>,
    val startPosition: (Player) -> Position = Player::position,
    val endPosition: (Player) -> Position,
) {
    fun createProducer(roadNetwork: Ref<RoadNetworkEntry>, player: Player): PathStreamProducer {
        return ref.get()?.createProducer(player, roadNetwork, startPosition, endPosition) ?: LinePathStreamProducer(
            player = player,
            roadNetwork = roadNetwork,
            startPosition = startPosition,
            endPosition = endPosition
        )
    }
}

@Tags("path_stream_display")
interface PathStreamDisplayEntry : AudienceFilterEntry {
    @Default("1700")
    @Help("The time between a new stream being calculated")
    val refreshDuration: Duration

    fun createDisplay(
        player: Player,
    ): PathStreamDisplay?

    fun createProducer(
        player: Player,
        roadNetwork: Ref<RoadNetworkEntry>,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position,
    ): PathStreamProducer

    fun displays(): List<Ref<PathStreamDisplayEntry>> = children.descendants(PathStreamDisplayEntry::class) + ref()

    override suspend fun display() = PassThroughFilter(ref())
}

fun List<Ref<PathStreamDisplayEntry>>.highestPathStreamDisplayEntry(
    player: Player,
): Ref<PathStreamDisplayEntry>? = filter { player.inAudience(it) }.maxByOrNull { it.priority }

interface PathStreamDisplay {
    fun display(position: Position)
    fun dispose()
}


private val pathStreamTimeout by snippet(
    "road_network.path_stream.timeout",
    15_000,
    "When path streams are forcefully canceled after this amount of time in milliseconds"
)

abstract class PathStream(
    val displays: List<PathStreamDisplay>
) {
    protected var startTime: Long = System.currentTimeMillis()

    fun tick(): Boolean {
        val position = forwardPath()
        displays.forEach { it.display(position) }
        return shouldContinue() && System.currentTimeMillis() - startTime < pathStreamTimeout
    }

    abstract fun forwardPath(): Position
    abstract fun shouldContinue(): Boolean

    open fun dispose() {
        displays.forEach { it.dispose() }
    }
}

typealias PathStreamDisplaysSupplier = (Player) -> List<PathStreamDisplay>

fun List<Ref<PathStreamDisplayEntry>>.createDisplays(player: Player): List<PathStreamDisplay> = mapNotNull {
    if (!player.inAudience(it)) return@mapNotNull null
    val entry = it.get() ?: return@mapNotNull null
    entry.createDisplay(player)
}

abstract class PathStreamProducer(
    val player: Player,
    val id: String,
    protected val roadNetwork: Ref<RoadNetworkEntry>,
    protected val startPosition: (Player) -> Position,
    protected val endPosition: (Player) -> Position,
    protected val refreshDuration: Duration,
    protected val displaySupplier: PathStreamDisplaysSupplier,
) : KoinComponent {

    protected val roadNetworkManager: RoadNetworkManager by inject()

    protected val gps = PointToPointGPS(roadNetwork, { startPosition(player) }, { endPosition(player) })

    protected var lastRefresh = 0L
    protected var job: Job? = null

    protected val mutex = Mutex()
    protected val streams = mutableListOf<PathStream>()

    abstract suspend fun refreshPath(): PathStream?

    fun tick() {
        if (job?.isActive == false) {
            lastRefresh = System.currentTimeMillis()
            job = null
        }
        if (job == null && (System.currentTimeMillis() - lastRefresh) > refreshDuration.toMillis()) {
            job = Dispatchers.UntickedAsync.launch {
                withTimeout(30.seconds) {
                    val stream = refreshPath() ?: return@withTimeout
                    mutex.withLock { streams.add(stream) }
                }
            }
        }

        Dispatchers.Unconfined.launch {
            mutex.lock()
            try {
                var writeIndex = 0
                for (readIndex in 0..streams.lastIndex) {
                    val stream = streams[readIndex]
                    val retain = withTimeoutOrNull(5.seconds) {
                        try {
                            stream.tick()
                        } catch (e: Throwable) {
                            e.printStackTrace()
                            false
                        }
                    } ?: false
                    if (!retain) {
                        stream.dispose()
                        continue
                    }

                    if (writeIndex != readIndex) {
                        streams[writeIndex] = stream
                    }
                    writeIndex++
                }

                if (writeIndex < streams.size) {
                    for (removeIndex in streams.lastIndex downTo writeIndex)
                        streams.removeAt(removeIndex)
                }
            } finally {
                mutex.unlock()
            }
        }
    }

    open fun dispose() {
        job?.cancel()
        job = null
        streams.forEach { it.dispose() }
        streams.clear()
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