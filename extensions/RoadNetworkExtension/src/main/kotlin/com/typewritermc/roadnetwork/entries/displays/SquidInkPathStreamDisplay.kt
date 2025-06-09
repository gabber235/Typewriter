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

enum class InkVariant {
    NORMAL,
    GLOW,
}

@Entry(
    "squid_ink_path_stream_display",
    "Displaying a path stream with (glow) squid ink particles",
    Colors.MYRTLE_GREEN,
    "fe:squid"
)
class InkPathStreamDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    @Default("1700")
    override val refreshDuration: Duration = Duration.ofMillis(1700),
    @Help("How fast the stream travels in blocks per second")
    @Default("20.0")
    val speed: Double = 20.0,
    @Default("\"GLOW\"")
    val variant: InkVariant = InkVariant.GLOW,
) : PathStreamDisplayEntry<SquidInkPathStreamDisplay> {
    override val klass: KClass<SquidInkPathStreamDisplay> get() = SquidInkPathStreamDisplay::class
    override fun createDisplay(
        ref: Ref<RoadNetworkEntry>,
        player: Player,
        startPosition: (Player) -> Position,
        endPosition: (Player) -> Position
    ): SquidInkPathStreamDisplay =
        SquidInkPathStreamDisplay(ref, player, startPosition, endPosition, refreshDuration, speed, variant)
}

class SquidInkPathStreamDisplay(
    ref: Ref<RoadNetworkEntry>,
    player: Player,
    startPosition: (Player) -> Position,
    endPosition: (Player) -> Position,
    refreshDuration: Duration = Duration.ofMillis(1700),
    val speed: Double = 20.0,
    val variant: InkVariant = InkVariant.GLOW,
) : PathStreamDisplay(ref, player, startPosition, endPosition, refreshDuration) {
    private val lines = ConcurrentHashMap<PathLine, Unit>()

    override suspend fun refreshPath() {
        val (_, paths) = calculatePathing() ?: return
        lines[PathLine(paths.flatten(), speed)] = Unit
    }

    override fun displayPath() {
        lines.keys.retainAll { line ->
            val location = line.currentPosition ?: return@retainAll false
            val particle = when (variant) {
                InkVariant.NORMAL -> ParticleTypes.SQUID_INK
                InkVariant.GLOW -> ParticleTypes.GLOW_SQUID_INK
            }
            WrapperPlayServerParticle(
                Particle(particle),
                true,
                location.withY { it + 0.2 }.toPacketVector3d(),
                Vector3f(0.3f, 0.0f, 0.3f),
                0f,
                1
            ) sendPacketTo player

            line.shouldContinue()
        }
    }
}