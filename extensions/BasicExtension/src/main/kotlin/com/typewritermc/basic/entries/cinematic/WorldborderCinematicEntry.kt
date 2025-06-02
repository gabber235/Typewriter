package com.typewritermc.basic.entries.cinematic

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerWorldBorderSize
import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayWorldBorderLerpSize
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Segments
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.CinematicAction
import com.typewritermc.engine.paper.entry.entries.PrimaryCinematicEntry
import com.typewritermc.engine.paper.entry.entries.Segment
import com.typewritermc.engine.paper.entry.temporal.SimpleCinematicAction
import com.typewritermc.engine.paper.extensions.packetevents.sendPacket
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import org.bukkit.entity.Player
import java.time.Duration
import java.util.*

@Entry("worldborder_cinematic", "A cinematic that resizes the worldborder over time", Colors.CYAN, "mdi:resize")
/**
 * The `Worldborder cinematic` entry can animate the worldborder client-side.
 * The border animation speed is not linked to the server's tick rate, since the animation fully runs on the client.
 *
 * ## How could this be used?
 *
 * This entry could be used to show the worldborder changing size during a cinematic, for example to emphasize a narrator talking about
 * how the border could change on a server based on certain conditions.
 */
class WorldborderCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    @Segments(icon = "mdi:resize")
    val segments: List<WorldborderSegment> = emptyList(),
) : PrimaryCinematicEntry {
    override fun create(player: Player): CinematicAction {
        return WorldborderCinematicAction(
            player,
            this,
        )
    }
}

data class WorldborderSegment(
    override val startFrame: Int = 0,
    override val endFrame: Int = 0,
    val newSize: Double = 0.0,
    val oldSize: Optional<Double> = Optional.empty(),
    val transitionTime: Duration = Duration.ofMillis(1000),
    val fadeBack: Boolean = false
) : Segment

class WorldborderCinematicAction(
    private val player: Player,
    entry: WorldborderCinematicEntry,
) : SimpleCinematicAction<WorldborderSegment>() {

    override val segments: List<WorldborderSegment> = entry.segments

    override suspend fun startSegment(segment: WorldborderSegment) {
        super.startSegment(segment)

        val oldSize = segment.oldSize.orElseGet(this::borderSize)
        val packet = WrapperPlayWorldBorderLerpSize(oldSize, segment.newSize, segment.transitionTime.toMillis())
        packet.sendPacketTo(player)
    }

    private fun borderSize(): Double {
        return player.world.worldBorder.size
    }

    override suspend fun stopSegment(segment: WorldborderSegment) {
        super.stopSegment(segment)

        val packet = if (!segment.fadeBack) WrapperPlayServerWorldBorderSize(borderSize())
        else WrapperPlayWorldBorderLerpSize(segment.newSize, borderSize(), segment.transitionTime.toMillis())
        player.sendPacket(packet)
    }
}