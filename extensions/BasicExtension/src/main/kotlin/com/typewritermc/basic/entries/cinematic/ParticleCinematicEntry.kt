package com.typewritermc.basic.entries.cinematic

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Segments
import com.typewritermc.core.extension.annotations.LabelKey
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.interaction.interactionContext
import com.typewritermc.engine.paper.utils.toBukkitLocation
import org.bukkit.Particle
import org.bukkit.entity.Player

@Entry("particle_cinematic", "Spawn particles for a cinematic", Colors.CYAN, "fa6-solid:fire-flame-simple")
/**
 * The `Particle Cinematic` entry is used to spawn particles for a cinematic.
 *
 * ## How could this be used?
 *
 * This can be used to add dramatic effects to a cinematic.
 * Like, blowing up a building and spawning a bunch of particles.
 * Or, adding focus to a certain area by spawning particles around it.
 */
class ParticleCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    val location: Var<Position> = ConstVar(Position.ORIGIN),
    val particle: Var<Particle> = ConstVar(Particle.FLAME),
    @LabelKey("basic.particle_cinematic.fields.count.label")
    @Help(key = "basic.particle_cinematic.fields.count.help")
    val count: Var<Int> = ConstVar(1),
    val offset: Var<Vector> = ConstVar(Vector.ZERO),
    @LabelKey("basic.particle_cinematic.fields.speed.label")
    @Help(key = "basic.particle_cinematic.fields.speed.help")
    val speed: Var<Double> = ConstVar(0.0),
    @Segments(icon = "fa6-solid:fire-flame-simple")
    val segments: List<ParticleSegment> = emptyList(),
) : CinematicEntry {
    override fun create(player: Player): CinematicAction {
        return ParticleCinematicAction(
            player,
            this,
        )
    }
}


data class ParticleSegment(
    override val startFrame: Int = 0,
    override val endFrame: Int = 0,
) : Segment

class ParticleCinematicAction(
    private val player: Player,
    private val entry: ParticleCinematicEntry,
) : CinematicAction {
    override suspend fun tick(frame: Int) {
        super.tick(frame)
        (entry.segments activeSegmentAt frame) ?: return
        val context = player.interactionContext

        player.spawnParticle(
            entry.particle.get(player, context),
            entry.location.get(player, context).toBukkitLocation(),
            entry.count.get(player, context),
            entry.offset.get(player, context).x,
            entry.offset.get(player, context).y,
            entry.offset.get(player, context).z,
            entry.speed.get(player, context),
        )
    }

    override fun canFinish(frame: Int): Boolean = entry.segments canFinishAt frame
}
