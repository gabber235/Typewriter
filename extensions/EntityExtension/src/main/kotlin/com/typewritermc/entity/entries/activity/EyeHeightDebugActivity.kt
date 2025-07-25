package com.typewritermc.entity.entries.activity

import com.github.retrooper.packetevents.protocol.particle.Particle
import com.github.retrooper.packetevents.protocol.particle.data.ParticleDustData
import com.github.retrooper.packetevents.protocol.particle.type.ParticleTypes
import com.github.retrooper.packetevents.util.Vector3d
import com.github.retrooper.packetevents.util.Vector3f
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerParticle
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.engine.paper.entry.entity.ActivityContext
import com.typewritermc.engine.paper.entry.entity.GenericEntityActivity
import com.typewritermc.engine.paper.entry.entity.PositionProperty
import com.typewritermc.engine.paper.entry.entity.TickResult
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import com.typewritermc.engine.paper.utils.Color
import kotlin.math.cos
import kotlin.math.sin

@Entry(
    "eye_height_debug_activity",
    "A debug activity that visualizes the entity's eye height",
    Colors.BLUE,
    "fa6-solid:eye"
)
/**
 * The `EyeHeightDebugActivityEntry` is an activity that visualizes the entity's eye height
 * it is primarily used for debugging purposes.
 * In normal situations, this activity should not be used.
 */
class EyeHeightDebugActivityEntry(
    override val id: String = "",
    override val name: String = "",
    @Default(Vector.UNIT_JSON)
    val directionOffset: Vector = Vector.UNIT,
    val color: Color = Color.WHITE,
) : GenericEntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): GenericEntityActivity {
        return EyeHeightDebugActivity(currentLocation, directionOffset, color)
    }
}

class EyeHeightDebugActivity(
    override var currentPosition: PositionProperty,
    val directionOffset: Vector,
    val color: Color
) : GenericEntityActivity {
    override fun initialize(context: ActivityContext) {}

    override fun tick(context: ActivityContext): TickResult {
        val pos = currentPosition
        val state = context.entityState
        val eyeHeight = state.eyeHeight

        val yawRad = Math.toRadians(pos.yaw.toDouble())
        val pitchRad = Math.toRadians(pos.pitch.toDouble())
        val direction = Vector(
            -sin(yawRad) * cos(pitchRad),
            -sin(pitchRad),
            cos(yawRad) * cos(pitchRad)
        )

        val eyePosition = Vector3d(
            pos.x + direction.x * directionOffset.x,
            pos.y + eyeHeight * directionOffset.y,
            pos.z + direction.z * directionOffset.z
        )

        val particlePacket = WrapperPlayServerParticle(
            Particle(
                ParticleTypes.DUST,
                ParticleDustData(0.3f, color.toPacketColor())
            ),
            false,
            eyePosition,
            Vector3f(0f, 0f, 0f),
            0.0f,
            1
        )

        context.viewers.forEach(particlePacket::sendPacketTo)

        return TickResult.CONSUMED
    }

    override fun dispose(context: ActivityContext) {}
}
