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
import org.bukkit.entity.Player
import kotlin.math.cos
import kotlin.math.sin
import kotlin.math.sqrt

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
    @Default("false")
    val showHitbox: Boolean = false,
) : GenericEntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): GenericEntityActivity {
        return EyeHeightDebugActivity(currentLocation, showHitbox)
    }
}

class EyeHeightDebugActivity(
    override var currentPosition: PositionProperty,
    val showHitbox: Boolean,
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

        val half = state.width / 2.0
        val eyePosition = Vector3d(
            pos.x + direction.x * half,
            pos.y + eyeHeight,
            pos.z + direction.z * half
        )

        sendDustParticle(context.viewers, eyePosition, Color(0xFFa0fc95.toInt()))

        if (showHitbox) {
            drawBoxEdges(
                context.viewers,
                pos.x - half,
                pos.y,
                pos.z - half,
                pos.x + half,
                pos.y + state.height,
                pos.z + half,
                Color.WHITE,
            )
        }

        return TickResult.CONSUMED
    }

    override fun dispose(context: ActivityContext) {}
}

private fun sendDustParticle(viewers: List<Player>, position: Vector3d, color: Color) {
    val particlePacket = WrapperPlayServerParticle(
        Particle(
            ParticleTypes.DUST,
            ParticleDustData(0.3f, color.toPacketColor())
        ),
        false,
        position,
        Vector3f(0f, 0f, 0f),
        0.0f,
        1
    )

    viewers.forEach(particlePacket::sendPacketTo)
}

private fun drawBoxEdges(
    viewers: List<Player>,
    minX: Double,
    minY: Double,
    minZ: Double,
    maxX: Double,
    maxY: Double,
    maxZ: Double,
    color: Color,
) {
    val step = 0.25

    drawEdge(viewers, minX, minY, minZ, maxX, minY, minZ, color, step)
    drawEdge(viewers, maxX, minY, minZ, maxX, minY, maxZ, color, step)
    drawEdge(viewers, maxX, minY, maxZ, minX, minY, maxZ, color, step)
    drawEdge(viewers, minX, minY, maxZ, minX, minY, minZ, color, step)

    drawEdge(viewers, minX, maxY, minZ, maxX, maxY, minZ, color, step)
    drawEdge(viewers, maxX, maxY, minZ, maxX, maxY, maxZ, color, step)
    drawEdge(viewers, maxX, maxY, maxZ, minX, maxY, maxZ, color, step)
    drawEdge(viewers, minX, maxY, maxZ, minX, maxY, minZ, color, step)

    drawEdge(viewers, minX, minY, minZ, minX, maxY, minZ, color, step)
    drawEdge(viewers, maxX, minY, minZ, maxX, maxY, minZ, color, step)
    drawEdge(viewers, maxX, minY, maxZ, maxX, maxY, maxZ, color, step)
    drawEdge(viewers, minX, minY, maxZ, minX, maxY, maxZ, color, step)
}

private fun drawEdge(
    viewers: List<Player>,
    x1: Double,
    y1: Double,
    z1: Double,
    x2: Double,
    y2: Double,
    z2: Double,
    color: Color,
    step: Double,
) {
    val dx = x2 - x1
    val dy = y2 - y1
    val dz = z2 - z1
    val length = sqrt(dx * dx + dy * dy + dz * dz)
    if (length == 0.0) {
        sendDustParticle(viewers, Vector3d(x1, y1, z1), color)
        return
    }

    var t = 0.0
    while (t <= length) {
        val fraction = t / length
        sendDustParticle(
            viewers,
            Vector3d(x1 + dx * fraction, y1 + dy * fraction, z1 + dz * fraction),
            color,
        )
        t += step
    }
}
