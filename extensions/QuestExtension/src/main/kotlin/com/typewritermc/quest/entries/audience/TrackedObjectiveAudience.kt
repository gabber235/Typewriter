package com.typewritermc.quest.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.core.entries.ref
import com.typewritermc.quest.events.AsyncTrackedQuestUpdate
import com.typewritermc.quest.trackedShowingObjectives
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler

@Entry(
    "tracked_objective_audience",
    "Filters an audience based on if they have a tracked objective",
    Colors.MEDIUM_SEA_GREEN,
    "mdi:target-account"
)
/**
 * The `Tracked Objective Audience` entry filters an audience based on if they have a tracked objective.
 * It looks if the player has an objective showing from the quest that is being tracked.
 *
 * ## How could this be used?
 * This could be used to show a boss bar or sidebar based on if a player has an objective showing.
 */
class TrackedObjectiveAudience(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val inverted: Boolean = false,
) : AudienceFilterEntry, Invertible {
    override suspend fun display(): AudienceFilter = TrackedObjectiveAudienceFilter(
        ref()
    )
}

class TrackedObjectiveAudienceFilter(
    ref: Ref<out AudienceFilterEntry>
) : AudienceFilter(ref), TickableDisplay {
    override fun filter(player: Player): Boolean = player.trackedShowingObjectives().any()

    override fun tick() {
        consideredPlayers.forEach { it.refresh() }
    }

    @EventHandler
    private fun onTrackedQuestUpdate(event: AsyncTrackedQuestUpdate) {
        event.player.refresh()
    }
}