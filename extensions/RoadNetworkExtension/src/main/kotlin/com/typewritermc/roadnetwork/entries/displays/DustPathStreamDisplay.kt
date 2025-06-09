package com.typewritermc.roadnetwork.entries.displays

import com.github.retrooper.packetevents.protocol.particle.Particle
import com.github.retrooper.packetevents.protocol.particle.data.ParticleDustData
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
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.engine.paper.utils.toPacketVector3d
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.gps.PathStreamDisplay
import com.typewritermc.roadnetwork.gps.PathStreamDisplayEntry
import org.bukkit.entity.Player
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass

@Entry(
    "dust_path_stream_display",
    "Displaying a path stream with colored dust particles",
    Colors.MYRTLE_GREEN,
    "fluent:dust-24-filled"
)
class DustPathStreamDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    override val refreshDuration: Duration = Duration.ofMillis(1700),
    @Help("How fast the stream travels in blocks per second")
    @Default("20.0")
    val speed: Double = 20.0,
    @Default("1.0")
    val size: Double = 1.0,
    val color: Color = Color.WHITE,
) : PathStreamDisplayEntry<DustPathStreamDisplay> {
    override val klass: KClass<DustPathStreamDisplay> get() = DustPathStreamDisplay::class
    override fun createDisplay(
        ref: Ref<RoadNetworkEntry>,
        player: Player,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position
    ): DustPathStreamDisplay = DustPathStreamDisplay(
        ref, player, startPosition, endPosition, refreshDuration, speed, size, color
    )
}

class DustPathStreamDisplay(
    ref: Ref<RoadNetworkEntry>,
    player: Player,
    startPosition: (Player) -> Position,
    endPosition: (Player) -> Position,
    refreshDuration: Duration = Duration.ofMillis(1700),
    val speed: Double = 20.0,
    val size: Double = 1.0,
    val color: Color = Color.WHITE,
) : PathStreamDisplay(ref, player, startPosition, endPosition, refreshDuration) {
    private val lines = ConcurrentHashMap<PathLine, Unit>()

    override suspend fun refreshPath() {
        val (_, paths) = calculatePathing() ?: return
        val line = paths.flatten()
        if (line.isEmpty()) return
        lines[PathLine(line, speed = speed)] = Unit // speed unused
    }

    override fun displayPath() {
        lines.keys.retainAll { line ->
            val location = line.currentPosition ?: return@retainAll false
            WrapperPlayServerParticle(
                Particle(ParticleTypes.DUST, ParticleDustData(size.toFloat(), color.toPacketColor())),
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
