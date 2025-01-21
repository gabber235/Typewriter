package com.typewritermc.quest.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.AudienceFilterEntry
import com.typewritermc.engine.paper.entry.entries.Invertible
import com.typewritermc.quest.QuestEntry
import com.typewritermc.quest.events.AsyncTrackedQuestUpdate
import com.typewritermc.quest.isQuestTracked
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler

@Entry(
    "tracked_quest_audience",
    "Filters an audience based on if they have a quest tracked",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:notebook-heart"
)
/**
 * The `Tracked Quest Audience` entry filters an audience based on if they have a quest tracked.
 *
 * If no quest is referenced, it will filter based on if any quest is tracked.
 *
 * ## How could this be used?
 *
 * This could be used to show a boss bar or sidebar based on if a player has a quest tracked.
 */
class TrackedQuestAudience(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    @Help("When not set, it will filter based on if any quest is tracked.")
    val quest: Ref<QuestEntry> = emptyRef(),
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = TrackedQuestAudienceFilter(
        ref(),
        quest
    )
}

class TrackedQuestAudienceFilter(
    ref: Ref<out AudienceFilterEntry>,
    private val quest: Ref<QuestEntry>
) : AudienceFilter(ref) {
    override fun filter(player: Player): Boolean = player.isQuestTracked(quest)

    @EventHandler
    private fun onTrackedQuestUpdate(event: AsyncTrackedQuestUpdate) {
        if (quest.isSet) {
            event.player.updateFilter(event.to == quest)
            return
        }

        event.player.updateFilter(event.to != null)
    }
}