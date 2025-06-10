package com.typewritermc.roadnetwork.entries

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.roadnetwork.RoadNetworkEntry
import org.bukkit.entity.Player
import java.time.Duration

class LinePathStreamProducer(
    player: Player,
    id: String = "",
    roadNetwork: Ref<RoadNetworkEntry>,
    startPosition: (Player) -> Position,
    endPosition: (Player) -> Position,
    refreshDuration: Duration = Duration.ofMillis(1700),
    displaySupplier: PathStreamDisplaysSupplier = { listOf(ParticlePathStreamDisplay(it)) },
    val speed: Double = 20.0,
) : PathStreamProducer(player, id, roadNetwork, startPosition, endPosition, refreshDuration, displaySupplier) {
    constructor(
        player: Player,
        ref: Ref<PathStreamDisplayEntry>,
        roadNetwork: Ref<RoadNetworkEntry>,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position,
        refreshDuration: Duration,
        speed: Double,
        displayEntries: List<Ref<PathStreamDisplayEntry>>,
    ) : this(
        player,
        ref.id,
        roadNetwork,
        startPosition,
        endPosition,
        refreshDuration,
        { displayEntries.createDisplays(it) },
        speed
    )

    override suspend fun refreshPath(): PathStream? {
        val (_, paths) = calculatePathing() ?: return null
        val line = paths.flatten()
        if (line.isEmpty()) return null
        return LinePathStream(displaySupplier(player), line, speed)
    }
}

class LinePathStream(
    displays: List<PathStreamDisplay>,
    val path: List<Position>,
    val speed: Double,
) : PathStream(displays) {
    init {
        require(path.isNotEmpty()) { "Path must not be empty" }
        require(startTime >= 0) { "Start time must not be negative" }
        require(speed > 0) { "Speed must be positive" }
    }

    val totalDuration: Double = (path.size / speed * 1000L)
    val percentage: Double
        get() {
            val diff = System.currentTimeMillis() - startTime
            return diff / totalDuration
        }

    val index: Int
        get() = (path.size * percentage).toInt().coerceIn(0, path.size - 1)
    val currentPosition: Position
        get() = path[index]

    override fun forwardPath(): Position {
        return currentPosition
    }

    override fun shouldContinue(): Boolean {
        return System.currentTimeMillis() < startTime + totalDuration
    }
}