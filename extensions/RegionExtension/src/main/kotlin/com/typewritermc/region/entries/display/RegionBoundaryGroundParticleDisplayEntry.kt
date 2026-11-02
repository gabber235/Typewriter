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
import com.typewritermc.region.content.resolveBukkitWorld
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
    "region_boundary_ground_particle",
    "Renders where a region meets the ground as particles",
    Colors.GREEN,
    "mdi:vector-polyline"
)
/**
 * Emits the configured particle along the line where the region intersects the ground: the
 * walkable surface inside the region's vertical span, right where the footprint ends. A
 * hovering region, or one whose span holds no surface, shows nothing.
 *
 * Unlike the full boundary displays, this draws only the ring players can actually walk
 * across, so it marks the border on the terrain itself and follows hills and floors.
 * Emission points are spread evenly along the line, one per block, with a point on every
 * corner. The terrain is resampled every couple of seconds, and immediately when the
 * region moves.
 *
 * Particles do not persist between emissions, so a solid line under an [animation] renders
 * identical to a still one; only a dashed [pattern] makes the flow visible, as its lit
 * stretches move along the line.
 *
 * ## How could this be used?
 *
 * Draw the edge of a claim or arena on the ground, or mark how far a quest area stretches
 * across hilly terrain without filling the air with particles.
 */
class RegionBoundaryGroundParticleDisplayEntry(
    override val id: String = "",
    override val name: String = "",
    @Help("The region whose ground line to render.")
    @Default(RegionDefaults.REGION_REFERENCE)
    val region: RegionData = RegionReferenceData(),
    @Help("The particle to draw the ground line with.")
    @Default("\"ELECTRIC_SPARK\"")
    val particle: Var<Particle> = ConstVar(Particle.ELECTRIC_SPARK),
    @Help("Particles emitted per point, per emission.")
    @Default("1")
    val count: Var<Int> = ConstVar(1),
    @Help("Random offset the client applies to each particle.")
    val offset: Var<Vector> = ConstVar(Vector.ZERO),
    @Help("Extra particle data. For most particles this is the speed.")
    val speed: Var<Double> = ConstVar(0.0),
    @Help("Delay between emissions, per player.")
    @Default("50")
    val delay: Var<Duration> = ConstVar(Duration.ofMillis(50)),
    @Help("Whether the line flows around the region, and how fast. A solid line shows no motion; pick a dashed pattern to see it flow.")
    @Default("""{"case":"static","value":{}}""")
    val animation: GroundLineAnimation = StaticGroundLine(),
    @Help("Whether the line is drawn solid or as marching dashes.")
    @Default("""{"case":"solid","value":{}}""")
    val pattern: GroundLinePattern = SolidLine(),
    @Help("Render the full ground line, or only a window near the player.")
    val area: BoundaryRenderArea = FullBoundary(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay =
        RegionBoundaryGroundParticleDisplay(region, area, id, particle, count, offset, speed, delay, animation, pattern)
}

class RegionBoundaryGroundParticleDisplay(
    region: RegionData,
    area: BoundaryRenderArea,
    entryId: String?,
    private val particle: Var<Particle>,
    private val count: Var<Int>,
    private val offset: Var<Vector>,
    private val speed: Var<Double>,
    private val delay: Var<Duration>,
    private val animation: GroundLineAnimation,
    private val pattern: GroundLinePattern,
) : RegionBoundaryDisplay(region, area, entryId) {
    private val nextEmissions = ConcurrentHashMap<UUID, Instant>()
    private val caches = GroundCachePool()
    private val startedAt: Instant = Instant.now()

    override fun onDisplayPlayerRemoved(player: Player) {
        nextEmissions.remove(player.uniqueId)
        caches.forget(player.uniqueId)
    }

    override fun renderForPlayer(player: Player, tracker: RegionTracker, transform: ResolvedTransform) {
        val now = Instant.now()
        val next = nextEmissions[player.uniqueId]
        if (next != null && now.isBefore(next)) return
        nextEmissions[player.uniqueId] = now.plus(delay.get(player))

        val world = resolveBukkitWorld(transform.world.identifier) ?: return
        if (world.uid != player.world.uid) return
        val path = caches.cacheFor(tracker, player.uniqueId)
            .pathFor(tracker.shape, transform, world, now)
        if (path.totalArc < 1e-6) return

        val phase = groundLinePhase(animation, path, player, Duration.between(startedAt, now))
        val window = nearWindow(player)
        val packetParticle = PacketParticle(SpigotConversionUtil.fromBukkitParticle(particle.get(player)))
        val emitCount = count.get(player)
        val packetOffset = offset.get(player).toPacketVector3f()
        val extra = speed.get(player).toFloat()

        for ((index, vertex) in path.vertices.withIndex()) {
            if (!pattern.emitsAt(path.arcOf(index) - phase, player)) continue
            val position = vertex.position
            if (window != null && !window.contains(position.x, position.y, position.z)) continue
            WrapperPlayServerParticle(
                packetParticle,
                true,
                position.toPacketVector3d(),
                packetOffset,
                extra,
                emitCount,
                true,
            ) sendPacketTo player
        }
    }

    override fun dispose() {
        nextEmissions.clear()
        caches.clear()
        super.dispose()
    }
}
