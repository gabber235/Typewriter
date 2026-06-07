package com.typewritermc.basic.entries.cinematic

import com.github.retrooper.packetevents.wrapper.play.server.WrapperPlayServerHurtAnimation
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Segments
import com.typewritermc.core.extension.annotations.LabelKey
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.packetevents.sendPacketTo
import org.bukkit.entity.Player
import kotlin.random.Random

@Entry(
    "screen_shake_cinematic",
    "Shake the screen",
    Colors.CYAN,
    "ant-design:shake-outlined"
)
/**
 * The `Screen Shake Cinematic` entry is used to shake the screen.
 *
 * ## How could this be used?
 * It could be used to simulate an earthquake or a sudden impact.
 */
class ScreenShakeCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    @Segments(icon = "ant-design:shake-outlined")
    val segments: List<ScreenShakeSegment> = emptyList(),
) : PrimaryCinematicEntry {
    override fun create(player: Player): CinematicAction {
        return ScreenShakeCinematicAction(
            player,
            this
        )
    }
}

data class ScreenShakeSegment(
    override val startFrame: Int = 0,
    override val endFrame: Int = 0,
    @LabelKey("basic.screen_shake_cinematic.fields.frameDelay.label")
    @Help(key = "basic.screen_shake_cinematic.fields.frameDelay.help")
    val frameDelay: Int = 0,
) : Segment

class ScreenShakeCinematicAction(
    private val player: Player,
    private val entry: ScreenShakeCinematicEntry,
) : CinematicAction {

    override suspend fun tick(frame: Int) {
        super.tick(frame)

        val segment = (entry.segments activeSegmentAt frame) ?: return
        val baseFrame = frame - segment.startFrame
        if (segment.frameDelay > 0 && baseFrame % segment.frameDelay != 0) return

        val packet = WrapperPlayServerHurtAnimation(player.entityId, Random.nextFloat() * 360 - 180)
        packet.sendPacketTo(player)
    }

    override fun canFinish(frame: Int): Boolean = entry.segments canFinishAt frame
}