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
import kotlin.reflect.KClass

enum class FlameVariant {
    FLAME,
    SOUL_FIRE_FLAME,
}

@Entry(
    "flame_path_stream_display",
    "Displaying a path stream with flame particles",
    Colors.MYRTLE_GREEN,
    "octicon:flame"
)
class FlamePathStreamDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    @Default("1700")
    @Help("The time between a new stream being recalculated")
    val refreshDuration: Duration = Duration.ofMillis(1700),
    @Help("How fast the stream travels in blocks per second")
    @Default("40.0")
    val speed: Double = 40.0,
    @Default("\"SOUL_FIRE_FLAME\"")
    val variant: FlameVariant = FlameVariant.SOUL_FIRE_FLAME,
) : PathStreamDisplayEntry<FlamePathStreamDisplay> {
    override val klass: KClass<FlamePathStreamDisplay> get() = FlamePathStreamDisplay::class
    override fun createDisplay(
        ref: Ref<RoadNetworkEntry>,
        player: Player,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position
    ): FlamePathStreamDisplay =
        FlamePathStreamDisplay(ref, player, startPosition, endPosition, refreshDuration, speed, variant)
}

class FlamePathStreamDisplay(
    ref: Ref<RoadNetworkEntry>,
    player: Player,
    startPosition: (Player) -> Position,
    endPosition: (Player) -> Position,
    refreshDuration: Duration = Duration.ofMillis(1700),
    val speed: Double = 40.0,
    val variant: FlameVariant = FlameVariant.SOUL_FIRE_FLAME,
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
            val particleType = when (variant) {
                FlameVariant.FLAME -> ParticleTypes.FLAME
                FlameVariant.SOUL_FIRE_FLAME -> ParticleTypes.SOUL_FIRE_FLAME
            }
            WrapperPlayServerParticle(
                Particle(particleType),
                true,
                location.withY { it + 0.15 }.toPacketVector3d(),
                Vector3f(0.2f, 0.0f, 0.2f),
                0f,
                1
            ) sendPacketTo player
            line.shouldContinue()
        }
    }
}
