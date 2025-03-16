package com.typewritermc.quest

import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.engine.paper.extensions.placeholderapi.PlaceholderHandler
import com.typewritermc.engine.paper.snippets.snippet
import org.bukkit.entity.Player

private val noneTracked by snippet("quest.tracked.none", "<gray>None tracked</gray>")

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

        return null
    }
}