package com.typewritermc.basic.entries.cinematic

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Colored
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.MultiLine
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.extension.annotations.Segments
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.CinematicAction
import com.typewritermc.engine.paper.entry.entries.PrimaryCinematicEntry
import com.typewritermc.engine.paper.entry.entries.Segment
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.temporal.SimpleCinematicAction
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.interaction.acceptActionBarMessage
import com.typewritermc.engine.paper.interaction.interactionContext
import com.typewritermc.engine.paper.utils.asMini
import net.kyori.adventure.text.Component
import org.bukkit.entity.Player

@Entry("actionbar_message_cinematic", "Show an action bar message", Colors.CYAN, "bxs:message-square-detail")
/**
 * The `Action Bar Message Cinematic` entry displays a message in the action bar during a cinematic.
 *
 * ## How could this be used?
 * Use this to quickly show hints or short context without the typing animation from dialogue cinematics.
 */
class ActionBarMessageCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    @Segments(icon = "bxs:message-square-detail")
    val segments: List<ActionBarMessageSegment> = emptyList(),
) : PrimaryCinematicEntry {
    override fun create(player: Player): CinematicAction = ActionBarMessageCinematicAction(player, this)
}

data class ActionBarMessageSegment(
    override val startFrame: Int = 0,
    override val endFrame: Int = 0,
    @Placeholder
    @Colored
    @MultiLine
    val message: Var<String> = ConstVar("")
) : Segment

class ActionBarMessageCinematicAction(
    private val player: Player,
    entry: ActionBarMessageCinematicEntry,
) : SimpleCinematicAction<ActionBarMessageSegment>() {

    override val segments: List<ActionBarMessageSegment> = entry.segments

    private fun send(component: Component) {
        player.acceptActionBarMessage(component)
        player.sendActionBar(component)
    }

    override suspend fun startSegment(segment: ActionBarMessageSegment) {
        super.startSegment(segment)
        val context = player.interactionContext
        val component = segment.message.get(player, context).parsePlaceholders(player).asMini()
        send(component)
    }

    override suspend fun tickSegment(segment: ActionBarMessageSegment, frame: Int) {
        super.tickSegment(segment, frame)
        if ((frame - segment.startFrame) % 20 == 0) {
            val context = player.interactionContext
            val component = segment.message.get(player, context).parsePlaceholders(player).asMini()
            send(component)
        }
    }

    override suspend fun stopSegment(segment: ActionBarMessageSegment) {
        super.stopSegment(segment)
        send(Component.empty())
    }
}
