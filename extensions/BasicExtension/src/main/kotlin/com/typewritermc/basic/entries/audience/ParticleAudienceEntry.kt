package com.typewritermc.basic.entries.audience

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerParticle
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.distanceSqrt
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.interaction.interactionContext
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.engine.paper.utils.toPacketVector3d
import com.typewritermc.engine.paper.utils.toPacketVector3f
import io.github.retrooper.packetevents.util.SpigotConversionUtil
import org.bukkit.Particle
import org.bukkit.entity.Player

@Entry(
    "particle_audience",
    "Displays a simple particle whenever the player is near a certain location",
    Colors.GREEN,
    "fa6-solid:fire-flame-simple"
)
/**
 * The `Particle Audience` entry displays a simple particle whenever the player is near a certain location.
 *
 * ## How could this be used?
 * When needing to interact with a specific thing, like block or entity, this can be used to spawn particles around it when the player is near.
 */
class ParticleAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    val position: Var<Position> = ConstVar(Position.ORIGIN),
    @Help("The distance the player needs to be from the location to spawn the particle.")
    @Default("30.0")
    val radius: Var<Double> = ConstVar(30.0),
    val particle: Var<Particle> = ConstVar(Particle.FLAME),
    @Help("The amount of particles to spawn every tick.")
    val count: Var<Int> = ConstVar(1),
    val offset: Var<Vector> = ConstVar(Vector.ZERO),
    @Help("The speed of the particles. For some particles, this is the \"extra\" data value to control particle behavior.")
    val speed: Var<Double> = ConstVar(0.0),
) : AudienceFilterEntry {
    override suspend fun display(): AudienceFilter = ParticleAudienceFilter(
        ref(),
        position,
        radius,
        particle,
        count,
        offset,
        speed,
    )
}

class ParticleAudienceFilter(
    ref: Ref<ParticleAudienceEntry>,
    val position: Var<Position>,
    val radius: Var<Double>,
    val particle: Var<Particle>,
    val count: Var<Int>,
    val offset: Var<Vector>,
    val speed: Var<Double>
) : AudienceFilter(ref), TickableDisplay {
    override fun filter(player: Player): Boolean {
        val distanceSquared = player.position.distanceSqrt(position.get(player)) ?: Double.MAX_VALUE
        val showRange = radius.get(player)
        return distanceSquared <= showRange * showRange
    }

    override fun tick() {
        consideredPlayers.filter { it.refresh() }.forEach { player ->
            val context = player.interactionContext

            WrapperPlayServerParticle(
                com.github.retrooper.packetevents.protocol.particle.Particle(
                    SpigotConversionUtil.fromBukkitParticle(particle.get(player, context)),
                ),
                true,
                position.get(player, context).toPacketVector3d(),
                offset.get(player, context).toPacketVector3f(),
                speed.get(player, context).toFloat(),
                count.get(player, context),
                true,
            ) sendPacketTo player
        }
    }
}
