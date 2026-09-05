package com.typewritermc.region.content

import com.github.retrooper.packetevents.protocol.particle.data.ParticleDustData
import com.github.retrooper.packetevents.protocol.particle.type.ParticleTypes
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerParticle
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.Color
import com.typewritermc.engine.paper.utils.toPacketVector3d
import com.typewritermc.engine.paper.utils.toPacketVector3f
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.shape.Shape
import io.github.retrooper.packetevents.util.SpigotConversionUtil
import org.bukkit.Location
import org.bukkit.entity.Player
import com.github.retrooper.packetevents.protocol.particle.Particle as PacketParticle

internal val previewRenderDistance by snippet(
    "region.content.preview_render_distance",
    48.0,
    "Max distance in blocks from the player at which region editor preview particles render.",
)

internal val previewDensity by snippet(
    "region.content.preview_density",
    0.1,
    "Samples per unit boundary area for region editor shape previews.",
)

internal const val MAX_PREVIEW_PARTICLES = 512
private const val SURFACE_DUST_SIZE = 1.4f

/**
 * A sparse dust sampling of the boundary surface. The editor renders it between the solid
 * display entity edge lines, capped at [MAX_PREVIEW_PARTICLES] and limited by the
 * `region.content.preview_render_distance` and `region.content.preview_density` snippets.
 */
internal fun renderSurfacePreview(
    player: Player,
    transform: ResolvedTransform,
    shape: Shape,
    color: Color,
    budget: ParticleBudget = ParticleBudget(MAX_PREVIEW_PARTICLES),
) {
    if (transform.world.identifier != player.world.uid.toString()) return

    val eye = player.location
    for (local in shape.sampleBoundary(previewDensity)) {
        val worldPos = transform.toWorld(local)
        if (!withinPreviewDistance(worldPos, eye)) continue
        if (!budget.take()) return
        emitDustParticle(player, worldPos, color, SURFACE_DUST_SIZE)
    }
}

/** A per tick particle cap shared by the edge and surface passes. */
internal class ParticleBudget(private var remaining: Int) {
    fun take(): Boolean {
        if (remaining <= 0) return false
        remaining -= 1
        return true
    }
}

internal fun withinPreviewDistance(worldPos: Vector, eye: Location): Boolean {
    val dx = worldPos.x - eye.x
    val dy = worldPos.y - eye.y
    val dz = worldPos.z - eye.z
    return dx * dx + dy * dy + dz * dz <= previewRenderDistance * previewRenderDistance
}

/** A single particle of any type, used for capture markers. */
internal fun emitPreviewParticle(player: Player, worldPos: Vector, particle: org.bukkit.Particle) {
    WrapperPlayServerParticle(
        PacketParticle(SpigotConversionUtil.fromBukkitParticle(particle)),
        true,
        worldPos.toPacketVector3d(),
        Vector.ZERO.toPacketVector3f(),
        0f,
        1,
        true,
    ) sendPacketTo player
}

internal fun emitDustParticle(player: Player, worldPos: Vector, color: Color, size: Float) {
    WrapperPlayServerParticle(
        PacketParticle(ParticleTypes.DUST, ParticleDustData(size, color.red, color.green, color.blue)),
        true,
        worldPos.toPacketVector3d(),
        Vector.ZERO.toPacketVector3f(),
        0f,
        1,
        true,
    ) sendPacketTo player
}
