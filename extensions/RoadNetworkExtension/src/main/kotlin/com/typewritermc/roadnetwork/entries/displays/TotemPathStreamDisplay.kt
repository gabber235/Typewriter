package com.typewritermc.roadnetwork.entries.displays

import com.github.retrooper.packetevents.protocol.particle.Particle
import com.github.retrooper.packetevents.protocol.particle.type.ParticleTypes
import com.github.retrooper.packetevents.util.Vector3f
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerParticle
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.utils.toPacketVector3d
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.gps.PathStreamDisplay
import com.typewritermc.roadnetwork.gps.PathStreamDisplayEntry
import org.bukkit.entity.Player
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap
import kotlin.math.max
import kotlin.reflect.KClass

@Entry(
    "totem_path_stream_display",
    "Displaying a path stream with totem of undying particles",
    Colors.MYRTLE_GREEN,
    "game-icons:totem-mask"
)
/**
 * This displays the `Path Stream` with the totem of undying particles.
 * It's the default way to display any `Path Stream`
 */
class TotemPathStreamDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    @Default("1700")
    @Help("The time between a new stream being calculated")
    val refreshDuration: Duration = Duration.ofMillis(1700),
    @Help("How fast the stream travels in blocks per second")
    @Default("20.0")
    val speed: Double = 20.0,
) : PathStreamDisplayEntry<TotemPathStreamDisplay> {
    override val klass: KClass<TotemPathStreamDisplay> get() = TotemPathStreamDisplay::class
    override fun createDisplay(
        ref: Ref<RoadNetworkEntry>,
        player: Player,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position
    ): TotemPathStreamDisplay = TotemPathStreamDisplay(ref, player, startPosition, endPosition, refreshDuration, speed)
}

class TotemPathStreamDisplay(
    ref: Ref<RoadNetworkEntry>,
    player: Player,
    startPosition: (Player) -> Position,
    endPosition: (Player) -> Position,
    refreshDuration: Duration = Duration.ofMillis(1700),
    val speed: Double = 20.0,
) : PathStreamDisplay(ref, player, startPosition, endPosition, refreshDuration) {
    private val lines = ConcurrentHashMap<PathLine, Unit>()

    override suspend fun refreshPath() {
        val (_, paths) = calculatePathing() ?: return
        val line = paths.flatten()
        if (line.isEmpty()) return
        lines[PathLine(line, speed)] = Unit
    }

    override fun displayPath() {
        lines.keys.retainAll { line ->
            val location = line.currentPosition ?: return@retainAll false
            WrapperPlayServerParticle(
                Particle(ParticleTypes.TOTEM_OF_UNDYING),
                true,
                location.withY { it + 1 }.toPacketVector3d(),
                Vector3f(0.3f, 0.0f, 0.3f),
                0f,
                1
            ) sendPacketTo player

            line.shouldContinue()
        }
    }
}

data class PathLine(
    val path: List<Position>,
    val speed: Double,
    val startTime: Long = System.currentTimeMillis(),
) {
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
        get() = (path.size * percentage).toInt().coerceIn(0, max(0, path.size - 1))
    val currentPosition: Position?
        get() = path.getOrNull(index)

    fun shouldContinue(): Boolean {
        return System.currentTimeMillis() < startTime + totalDuration
    }
}
