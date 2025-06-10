package com.typewritermc.roadnetwork.entries

import com.github.retrooper.packetevents.protocol.particle.Particle
import com.github.retrooper.packetevents.protocol.particle.type.ParticleTypes
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerParticle
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.utils.toPacketVector3d
import com.typewritermc.engine.paper.utils.toPacketVector3f
import org.bukkit.entity.Player

class ParticlePathStreamDisplay(
    private val player: Player,
    private val particle: Particle<*> = Particle(ParticleTypes.TOTEM_OF_UNDYING),
    private val particleOffset: Vector = Vector(0.3, 0.0, 0.3),
    private val positionOffset: Vector = Vector(0.0, 1.0, 0.0),
    private val count: Int = 1,
    private val speed: Float = 0f
) : PathStreamDisplay {
    override fun display(position: Position) {
        WrapperPlayServerParticle(
            particle,
            true,
            (position + positionOffset).toPacketVector3d(),
            particleOffset.toPacketVector3f(),
            speed,
            count,
        ) sendPacketTo player
    }

    override fun dispose() {}
}