package com.typewritermc.basic.entries.audience

import com.typewritermc.basic.entries.cinematic.CinematicSkippableEvent
import com.typewritermc.basic.entries.cinematic.SkipConfirmationKey
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.AudienceFilterEntry
import com.typewritermc.engine.paper.entry.entries.Invertible
import com.typewritermc.engine.paper.events.AsyncCinematicEndEvent
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import java.util.*
import java.util.concurrent.ConcurrentHashMap

@Entry(
    "cinematic_skippable_audience",
    "An audience filter based on if the player can skip the cinematic they are in",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:skip-next"
)
/**
 * The `Cinematic Skippable Audience` entry filters an audience based if the player can skip the cinematic they are in.
 *
 * You can use this entry as a placeholder for the confirmation key.
 * So %typewriter_<entry id>% will be replaced with the current confirmation key.
 *
 * ## How could this be used?
 * This could be used to show a boss bar or sidebar based on if the player can skip the cinematic they are in.
 */
class CinematicSkippableAudienceEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<out AudienceEntry>> = emptyList(),
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible, PlaceholderEntry {
    override suspend fun display(): AudienceFilter {
        return CinematicSkippableAudienceDisplay(ref())
    }

    override fun parser(): PlaceholderParser = placeholderParser {
        supply { player ->
            val default = SkipConfirmationKey.SNEAK

            if (player == null) return@supply default.bedrockKeybind
            val display = ref().findDisplay() as? CinematicSkippableAudienceDisplay ?: return@supply default.keybind(player)
            display.confirmationKey(player)?.keybind(player) ?: default.keybind(player)
        }
    }
}

class CinematicSkippableAudienceDisplay(
    ref: Ref<out AudienceFilterEntry>,
) : AudienceFilter(ref) {
    override fun filter(player: Player): Boolean = false

    private val confirmationKeys = ConcurrentHashMap<UUID, SkipConfirmationKey>()

    @EventHandler
    fun onCinematicSkippable(event: CinematicSkippableEvent) {
        if (!canConsider(event.player)) return

        event.player.updateFilter(event.canSkip)

        confirmationKeys.compute(event.player.uniqueId) { _, _ ->
            if (event.canSkip) event.confirmationKey else null
        }
    }

    @EventHandler
    fun onPlayerCinematicEnd(event: AsyncCinematicEndEvent) {
        if (!canConsider(event.player)) return
        event.player.updateFilter(false)
        confirmationKeys.remove(event.player.uniqueId)
    }

    fun confirmationKey(player: Player): SkipConfirmationKey? = confirmationKeys[player.uniqueId]
}

