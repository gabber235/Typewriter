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
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    override val refreshDuration: Duration = Duration.ofMillis(1700),
    @Default("{\"x\": 0.2, \"y\": 0.0, \"z\": 0.2}")
    val particleOffset: Vector = Vector(0.2, 0.0, 0.2),
    @Default("{\"x\": 0.0, \"y\": 0.15, \"z\": 0.0}")
    val positionOffset: Vector = Vector(0.0, 0.15, 0.0),
    @Default("1")
    val count: Int = 1,
    val particleSpeed: Float = 0f,
    @Help("How fast the stream travels in blocks per second")
    @Default("20.0")
    val travelSpeed: Double = 20.0,
    @Default("\"SOUL_FIRE_FLAME\"")
    val variant: FlameVariant = FlameVariant.SOUL_FIRE_FLAME,
) : PathStreamDisplayEntry {
    override fun createDisplay(player: Player): PathStreamDisplay = ParticlePathStreamDisplay(
        player,
        Particle(
            when (variant) {
                FlameVariant.FLAME -> ParticleTypes.FLAME
                FlameVariant.SOUL_FIRE_FLAME -> ParticleTypes.SOUL_FIRE_FLAME
            }
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
