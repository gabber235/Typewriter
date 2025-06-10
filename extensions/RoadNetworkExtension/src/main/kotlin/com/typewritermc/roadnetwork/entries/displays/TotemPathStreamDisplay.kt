package com.typewritermc.roadnetwork.entries.displays

import com.github.retrooper.packetevents.protocol.particle.Particle
import com.github.retrooper.packetevents.protocol.particle.type.ParticleTypes
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.entries.LinePathStreamProducer
import com.typewritermc.roadnetwork.entries.ParticlePathStreamDisplay
import com.typewritermc.roadnetwork.entries.PathStreamDisplay
import com.typewritermc.roadnetwork.entries.PathStreamDisplayEntry
import org.bukkit.entity.Player
import java.time.Duration

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
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    override val refreshDuration: Duration = Duration.ofMillis(1700),
    @Default("{\"x\": 0.3, \"y\": 0.0, \"z\": 0.3}")
    val particleOffset: Vector = Vector(0.3, 0.0, 0.3),
    @Default("{\"x\": 0.0, \"y\": 1.0, \"z\": 0.0}")
    val positionOffset: Vector = Vector(0.0, 1.0, 0.0),
    @Default("1")
    val count: Int = 1,
    val particleSpeed: Float = 0f,
    @Help("How fast the stream travels in blocks per second")
    @Default("20.0")
    val travelSpeed: Double = 20.0,
) : PathStreamDisplayEntry {
    override fun createDisplay(player: Player): PathStreamDisplay = ParticlePathStreamDisplay(
        player,
        Particle(ParticleTypes.TOTEM_OF_UNDYING),
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
        displays()
    )
}
