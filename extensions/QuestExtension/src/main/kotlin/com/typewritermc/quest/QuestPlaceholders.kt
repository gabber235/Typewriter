package com.typewritermc.quest

import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.utils.point.formatted
import com.typewritermc.engine.paper.extensions.placeholderapi.PlaceholderHandler
import com.typewritermc.engine.paper.snippets.snippet
import org.bukkit.entity.Player

private val noneTracked by snippet("quest.tracked.none", "<gray>None tracked</gray>")
private val trackedObjectiveLocationFormat by snippet("quest.tracked.objective.format", "[%.0f, %.0f, %.0f]")

@Singleton
class QuestPlaceholders : PlaceholderHandler {
    override fun onPlaceholderRequest(player: Player?, params: String): String? {
        if (player == null) return null
        if (params == "tracked_quest") {
            return player.trackedQuest()?.get()?.display(player) ?: noneTracked
        }

        if (params == "tracked_objectives") {
            return player.trackedShowingObjectives().joinToString(", ") { it.display(player) }
                .ifBlank { noneTracked }
        }

        if (params == "tracked_objectives_locations") {
            return player.trackedShowingObjectives().filterIsInstance<LocatableObjective>()
                .flatMap { it.positions(player) }
                .joinToString { it.formatted(trackedObjectiveLocationFormat) }
        }

        return null
    }
}