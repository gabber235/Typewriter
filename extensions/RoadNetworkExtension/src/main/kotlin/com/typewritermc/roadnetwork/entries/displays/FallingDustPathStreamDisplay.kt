package com.typewritermc.roadnetwork.entries.displays

import com.github.retrooper.packetevents.protocol.particle.Particle
import com.github.retrooper.packetevents.protocol.particle.data.ParticleBlockStateData
import com.github.retrooper.packetevents.protocol.particle.type.ParticleTypes
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.entries.LinePathStreamProducer
import com.typewritermc.roadnetwork.entries.ParticlePathStreamDisplay
import com.typewritermc.roadnetwork.entries.PathStreamDisplay
import com.typewritermc.roadnetwork.entries.PathStreamDisplayEntry
import io.github.retrooper.packetevents.util.SpigotConversionUtil
import org.bukkit.Material
import org.bukkit.entity.Player
import java.time.Duration

@Entry(
    "falling_dust_path_stream_display",
    "Displaying a path stream with falling block particles",
    Colors.MYRTLE_GREEN,
    "mingcute:snowstorm-fill"
)
class FallingDustPathStreamDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    @Default("2000")
    override val refreshDuration: Duration = Duration.ofMillis(2000),
    @Default("{\"x\": 0.2, \"y\": 0.0, \"z\": 0.2}")
    val particleOffset: Vector = Vector(0.2, 0.0, 0.2),
    @Default("{\"x\": 0.0, \"y\": 0.8, \"z\": 0.0}")
    val positionOffset: Vector = Vector(0.0, 0.8, 0.0),
    @Default("1")
    val count: Int = 1,
    val particleSpeed: Float = 0f,
    @Help("How fast the stream travels in blocks per second")
    @Default("20.0")
    val travelSpeed: Double = 20.0,
    @Help("The material of the falling dust particles")
    @Default("\"BEACON\"")
    @MaterialProperties(MaterialProperty.BLOCK)
    val material: Material = Material.BEACON,
) : PathStreamDisplayEntry {
    override fun createDisplay(player: Player): PathStreamDisplay = ParticlePathStreamDisplay(
        player,
        Particle(
            ParticleTypes.FALLING_DUST,
            ParticleBlockStateData(
                SpigotConversionUtil.fromBukkitBlockData(material.createBlockData())
            ),
        ),
        particleOffset,
        positionOffset,
        count,
        particleSpeed,
    )

    override fun createProducer(
        player: Player,
        roadNetwork: Ref<RoadNetworkEntry>,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position
    ) = LinePathStreamProducer(
        player,
        ref(),
        roadNetwork,
        startPosition,
        endPosition,
        refreshDuration,
        travelSpeed,
        displays(),
    )
}