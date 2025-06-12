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

@Entry(
    "cinematic_section_fact",
    "Whether the player is within a certain section of a cinematic",
    Colors.PURPLE,
    "mdi:camera-burst"
)
/**
 * The 'Cinematic Section Fact' is a fact that can return different values depending
 * on what part of a cinematic the player is in.
 *
 * The specified `sections` can be used to map a certain range of cinematic frames to a value
 * that will then be returned by the fact if the player is in that range. If none of the ranges
 * match or the player is not currently in a cinematic, the value from `default` will be returned instead.
 *
 * Optionally, a cinematic page can be specified to only check for the given sections
 * in that page, instead of any active cinematic.
 *
 *
 * <fields.ReadonlyFactInfo />
 *
 * ## How could this be used?
 * With this fact, it is possible to make an entry act differently depending on
 * what section of a cinematic the player is in.
 */
class CinematicSectionFactEntry(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
    @Page(PageType.CINEMATIC)
    @SerializedName("cinematic")
    val pageId: String = "",
    val sections: List<CinematicSection> = emptyList(),
    @Help("Will be returned when the player is not in a cinematic, or not in any of the given sections")
    val default: Int = 0,
) : ReadableFactEntry {
    override fun readSinglePlayer(player: Player): FactData {
        val inCinematic = if (pageId.isNotBlank()) player.isPlayingTemporal(pageId) else player.isPlayingTemporal()
        if (!inCinematic) return FactData(default)

        val frame = player.currentTemporalFrame() ?: return FactData(default)
        val output = sections.firstOrNull { it.frameRange.contains(frame) }?.value
        return FactData(output ?: default)
    }

    data class CinematicSection(
        @Help("The range of cinematic frames the player has to be in")
        val frameRange: ClosedRange<Int> = IntRange.EMPTY,
        val value: Int = 0
    )
}
