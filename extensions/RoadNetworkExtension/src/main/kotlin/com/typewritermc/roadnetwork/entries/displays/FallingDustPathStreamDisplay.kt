package com.typewritermc.roadnetwork.entries.displays

import com.github.retrooper.packetevents.protocol.particle.Particle
import com.github.retrooper.packetevents.protocol.particle.data.ParticleBlockStateData
import com.github.retrooper.packetevents.protocol.particle.type.ParticleTypes
import com.github.retrooper.packetevents.util.Vector3f
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerParticle
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.utils.toPacketVector3d
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.gps.PathStreamDisplay
import com.typewritermc.roadnetwork.gps.PathStreamDisplayEntry
import io.github.retrooper.packetevents.util.SpigotConversionUtil
import org.bukkit.Material
import org.bukkit.entity.Player
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap
import kotlin.reflect.KClass

@Entry(
    "falling_dust_path_stream_display",
    "Displaying a path stream with falling block particles",
    Colors.MYRTLE_GREEN,
    "mingcute:snowstorm-fill"
)
class FallingDustPathStreamDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    @Default("2000")
    override val refreshDuration: Duration = Duration.ofMillis(2000),
    @Help("How fast the stream travels in blocks per second")
    @Default("20.0")
    val speed: Double = 20.0,
    @Help("The material of the falling dust particles")
    @Default("\"BEACON\"")
    @MaterialProperties(MaterialProperty.BLOCK)
    val material: Material = Material.BEACON,
) : PathStreamDisplayEntry<FallingDustPathStreamDisplay> {
    override val klass: KClass<FallingDustPathStreamDisplay> get() = FallingDustPathStreamDisplay::class
    override fun createDisplay(
        ref: Ref<RoadNetworkEntry>,
        player: Player,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position
    ): FallingDustPathStreamDisplay = FallingDustPathStreamDisplay(
        ref, player, startPosition, endPosition, refreshDuration, speed, material
    )
}

class FallingDustPathStreamDisplay(
    ref: Ref<RoadNetworkEntry>,
    player: Player,
    startPosition: (Player) -> Position,
    endPosition: (Player) -> Position,
    refreshDuration: Duration = Duration.ofMillis(1700),
    val speed: Double = 20.0,
    val material: Material = Material.SAND,
) : PathStreamDisplay(ref, player, startPosition, endPosition, refreshDuration) {
    private val lines = ConcurrentHashMap<PathLine, Unit>()

    override suspend fun refreshPath() {
        val (_, paths) = calculatePathing() ?: return
        val line = paths.flatten()
        if (line.isEmpty()) return
        lines[PathLine(line, speed = speed)] = Unit
    }

    override fun displayPath() {
        lines.keys.retainAll { line ->
            val location = line.currentPosition ?: return@retainAll false


            WrapperPlayServerParticle(
                Particle(
                    ParticleTypes.FALLING_DUST, ParticleBlockStateData(
                        SpigotConversionUtil.fromBukkitBlockData(material.createBlockData())
                    )
                ),
                true,
                location.withY { it + 0.8 }.toPacketVector3d(),
                Vector3f(0.2f, 0.0f, 0.2f),
                0f,
                1
            ) sendPacketTo player
            line.shouldContinue()
        }
    }
}