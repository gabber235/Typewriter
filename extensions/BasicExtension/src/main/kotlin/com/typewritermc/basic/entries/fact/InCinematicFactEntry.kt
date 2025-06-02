package com.typewritermc.basic.entries.fact

import com.google.gson.annotations.SerializedName
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Page
import com.typewritermc.engine.paper.entry.entries.GroupEntry
import com.typewritermc.engine.paper.entry.entries.ReadableFactEntry
import com.typewritermc.engine.paper.entry.temporal.currentTemporalFrame
import com.typewritermc.engine.paper.entry.temporal.isPlayingTemporal
import com.typewritermc.engine.paper.facts.FactData
import org.bukkit.entity.Player
import java.util.*

@Entry("in_cinematic_fact", "If the player is in a cinematic", Colors.PURPLE, "eos-icons:storage-class")
/**
 * The 'In Cinematic Fact' is a fact that returns 1 if the player has an active cinematic, and 0 if not.
 *
 * If no cinematic is referenced, it will filter based on if any cinematic is active.
 * If the player has an active cinematic, this fact can optionally be used to check
 * whether the player is within a certain range of frames.
 *
 * <fields.ReadonlyFactInfo />
 *
 * ## How could this be used?
 * With this fact, it is possible to make an entry only take action if the player does not have an active cinematic.
 */
class InCinematicFactEntry(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
    @Help("When not set, it will filter based on if any cinematic is active.")
    @Page(PageType.CINEMATIC)
    @SerializedName("cinematic")
    val pageId: String = "",
    val beforeFrame: Optional<Int> = Optional.empty(),
    val afterFrame: Optional<Int> = Optional.empty()
) : ReadableFactEntry {
    override fun readSinglePlayer(player: Player): FactData {
        val inCinematic = if (pageId.isNotBlank())
            player.isPlayingTemporal(pageId)
        else
            player.isPlayingTemporal()

        val frame = player.currentTemporalFrame() ?: 0
        val isOutOfRange = (beforeFrame.isPresent && beforeFrame.get() <= frame)
                || (afterFrame.isPresent && afterFrame.get() > frame)
        return FactData((inCinematic && !isOutOfRange).toInt())
    }
}
