package com.typewritermc.basic.entries.audience

import com.google.gson.annotations.SerializedName
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.books.pages.PageType
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Page
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.AudienceFilterEntry
import com.typewritermc.engine.paper.entry.entries.Invertible
import com.typewritermc.engine.paper.entry.temporal.isPlayingTemporal
import com.typewritermc.engine.paper.events.AsyncCinematicEndEvent
import com.typewritermc.engine.paper.events.AsyncCinematicStartEvent
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler

@Entry(
    "cinematic_audience",
    "Filters an audience based on if they are in a cinematic",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:movie"
)
/**
 * The `Cinematic Audience` entry filters an audience based on if they are in a cinematic.
 *
 * If no cinematic is referenced, it will filter based on if any cinematic is active.
 *
 * ## How could this be used?
 * This could be used to hide the sidebar or boss bar when a cinematic is playing.
 */
class CinematicAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    @Help("When not set it will filter based on if any cinematic is active.")
    @Page(PageType.CINEMATIC)
    @SerializedName("cinematic")
    val pageId: String = "",
    override val inverted: Boolean = false
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = CinematicAudienceFilter(
        ref(),
        pageId,
    )
}

class CinematicAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    private val pageId: String,
) : AudienceFilter(ref) {
    override fun filter(player: Player): Boolean {
        val inCinematic = if (pageId.isNotBlank()) player.isPlayingTemporal(pageId) else player.isPlayingTemporal()
        return inCinematic
    }

    @EventHandler
    fun onCinematicStart(event: AsyncCinematicStartEvent) {
        if (pageId.isNotBlank() && event.pageId != pageId) return
        event.player.updateFilter(true)
    }

    @EventHandler
    fun onCinematicEnd(event: AsyncCinematicEndEvent) {
        if (pageId.isNotBlank() && event.pageId != pageId) return
        event.player.updateFilter(false)
    }
}

