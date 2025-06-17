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
import com.typewritermc.engine.paper.interaction.interactionContext
import com.typewritermc.engine.paper.utils.sendMiniWithResolvers
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder as MiniPlaceholder
import org.bukkit.entity.Player

@Entry("message_cinematic", "Send a chat message", Colors.CYAN, "flowbite:message-dots-solid")
/**
 * The `Message Cinematic` entry sends a chat message when a cinematic reaches a segment.
 *
 * ## How could this be used?
 * Great for brief instructions or narration without dialogue animations.
 */
class MessageCinematicEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    @Segments(icon = "flowbite:message-dots-solid")
    val segments: List<MessageSegment> = emptyList(),
) : PrimaryCinematicEntry {
    override fun create(player: Player): CinematicAction = MessageCinematicAction(player, this)
}

data class MessageSegment(
    override val startFrame: Int = 0,
    override val endFrame: Int = 0,
    @Placeholder
    @Colored
    @MultiLine
    val message: Var<String> = ConstVar("")
) : Segment

class MessageCinematicAction(
    private val player: Player,
    entry: MessageCinematicEntry,
) : SimpleCinematicAction<MessageSegment>() {

    override val segments: List<MessageSegment> = entry.segments

    override suspend fun startSegment(segment: MessageSegment) {
        super.startSegment(segment)
        val context = player.interactionContext
        val text = segment.message.get(player, context).parsePlaceholders(player)
        val component = MiniPlaceholder.parsed("message", text)
        player.sendMiniWithResolvers("<message>", component)
    }
}
