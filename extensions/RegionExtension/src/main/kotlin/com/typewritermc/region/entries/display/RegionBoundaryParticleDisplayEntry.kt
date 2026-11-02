package com.typewritermc.region.entries.display

import com.github.retrooper.packetevents.protocol.particle.Particle as PacketParticle
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerParticle
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.utils.toPacketVector3d
import com.typewritermc.engine.paper.utils.toPacketVector3f
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefaults
import com.typewritermc.region.data.RegionReferenceData
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.tracker.RegionTracker
import io.github.retrooper.packetevents.util.SpigotConversionUtil
import java.time.Duration
import java.time.Instant
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import org.bukkit.Particle
import org.bukkit.entity.Player

@Entry(
    "region_boundary_particle",
    "Renders a region's boundary as particles",
    Colors.GREEN,
    "fa6-solid:fire-flame-simple"
)
/**
 * Emits the configured particle at samples along the region's boundary, once per [delay],
 * for each player in the audience. Particles fade on their own, so nothing is cached.
 *
 * Wrap this in an [com.typewritermc.region.entries.audience.InRegionAudienceEntry] or a
 * [com.typewritermc.region.entries.audience.BoundaryProximityAudienceEntry] to show the
 * boundary only to players inside, outside, or near it.
 *
 * ## How could this be used?
 *
 * Outline a quest area in soul fire so players can see where it starts, or trace the edge of
 * a safe zone in sparks that only appears once a player walks close to it.
 */
class RegionBoundaryParticleDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The region whose boundary to render.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
    @Help("Particles per unit boundary area. Zero is not off: every boundary gets at least eight samples.")
    @Default("0.5")
    val density: Var<Double> = ConstVar(0.5),
    @Help("The particle to draw the boundary with.")
    @Default("\"ELECTRIC_SPARK\"")
    val particle: Var<Particle> = ConstVar(Particle.ELECTRIC_SPARK),
    @Help("Particles emitted per sample, per emission.")
    @Default("1")
    val count: Var<Int> = ConstVar(1),
    @Help("Random offset the client applies to each particle.")
    val offset: Var<Vector> = ConstVar(Vector.ZERO),
    @Help("Extra particle data. For most particles this is the speed.")
    val speed: Var<Double> = ConstVar(0.0),
    @Help("Delay between emissions, per player.")
    @Default("50")
    val delay: Var<Duration> = ConstVar(Duration.ofMillis(50)),
    @Help("Render the full boundary, or only a window near the player.")
    val area: BoundaryRenderArea = FullBoundary(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay =
        RegionBoundaryParticleDisplay(region, density, area, id, particle, count, offset, speed, delay)
}

class RegionBoundaryParticleDisplay(
    region: RegionData,
    private val density: Var<Double>,
    area: BoundaryRenderArea,
    entryId: String?,
    private val particle: Var<Particle>,
    private val count: Var<Int>,
    private val offset: Var<Vector>,
    private val speed: Var<Double>,
    private val delay: Var<Duration>,
) : RegionBoundaryDisplay(region, area, entryId) {
    private val nextEmissions = ConcurrentHashMap<UUID, Instant>()

    override fun onDisplayPlayerRemoved(player: Player) {
        nextEmissions.remove(player.uniqueId)
    }

    override fun renderForPlayer(player: Player, tracker: RegionTracker, transform: ResolvedTransform) {
        val now = Instant.now()
        val next = nextEmissions[player.uniqueId]
        if (next != null && now.isBefore(next)) return
        nextEmissions[player.uniqueId] = now.plus(delay.get(player))

        val window = nearWindow(player)
        val packetParticle = PacketParticle(SpigotConversionUtil.fromBukkitParticle(particle.get(player)))
        val emitCount = count.get(player)
        val packetOffset = offset.get(player).toPacketVector3f()
        val extra = speed.get(player).toFloat()
        for (local in tracker.shape.sampleBoundary(density.get(player))) {
            val worldPos = transform.toWorld(local)
            if (window != null && !window.contains(worldPos.x, worldPos.y, worldPos.z)) continue
            WrapperPlayServerParticle(
                packetParticle,
                true,
                worldPos.toPacketVector3d(),
                packetOffset,
                extra,
                emitCount,
                true,
            ) sendPacketTo player
        }
    }

    override fun dispose() {
        nextEmissions.clear()
        super.dispose()
    }
}
