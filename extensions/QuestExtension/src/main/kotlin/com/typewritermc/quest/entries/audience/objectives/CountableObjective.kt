package com.typewritermc.quest.entries.audience.objectives

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.entry.matches
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.replaceTagPlaceholders
import com.typewritermc.quest.entries.ObjectiveEntry
import com.typewritermc.quest.entries.QuestEntry
import com.typewritermc.quest.entries.inactiveObjectiveDisplay
import com.typewritermc.quest.entries.showingObjectiveDisplay
import org.bukkit.entity.Player
import java.util.*
import kotlin.math.absoluteValue

private val countableObjectiveDisplay by snippet(
    "quest.objectives.countable.completed",
    "<green>✔</green> <gray><display></gray>"
)

/**
 * Checks whether [count] satisfies the target specification [raw].
 * Supports:
 *   - Single values: "5"
 *   - Inclusive ranges: "28-61"
 *   - Open-ended upper: "32.." (32 and above)
 *   - Open-ended lower: "..10" (10 and below)
 *   - Combinations: "28-61,63,70.."
 */
private fun matchesTarget(count: Int, raw: String): Boolean {
    return raw.split(",").any { part ->
        val trimmed = part.trim()
        when {
            trimmed.endsWith("..") -> {
                val from = trimmed.dropLast(2).trim().toIntOrNull()
                from != null && count >= from
            }
            trimmed.startsWith("..") -> {
                val to = trimmed.drop(2).trim().toIntOrNull()
                to != null && count <= to
            }
            trimmed.contains("-") -> {
                val rangeParts = trimmed.split("-", limit = 2)
                val from = rangeParts[0].trim().toIntOrNull()
                val to = rangeParts.getOrNull(1)?.trim()?.toIntOrNull()
                from != null && to != null && count in from..to
            }
            else -> trimmed.toIntOrNull() == count
        }
    }
}

/**
 * Converts a target string to a human-readable display value.
 * Strips open-ended range syntax per token, e.g. "32..,50" displays as "32,50".
 */
private fun displayTarget(raw: String): String = raw
    .split(",")
    .joinToString(",") { part ->
        val trimmed = part.trim()
        when {
            trimmed.endsWith("..") -> trimmed.dropLast(2).trim()
            trimmed.startsWith("..") -> trimmed.drop(2).trim()
            else -> trimmed
        }
    }

@Entry(
    "countable_objective",
    "An objective that can show a fact",
    Colors.BLUE_VIOLET,
    "material-symbols:add-diamond-outline"
)
class CountableObjective(
    override val id: String = "",
    override val name: String = "",
    override val quest: Ref<QuestEntry> = emptyRef(),
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val criteria: List<Criteria> = emptyList(),
    @Help("The value that is being counted towards the target.")
    val count: Var<Int> = ConstVar(0),
    @Help(
        "The target value(s) to reach for completion. Supports ranges (28-61), individual values (63), " +
        "open-ended upper (32..), open-ended lower (..10), and combinations (28-61,63,70..)."
    )
    val target: Var<String> = ConstVar("0"),
    @Help("The display supports the <count> and <target> tags from the fact.")
    @Default("\"<count>/<target>\"")
    override val display: Var<String> = ConstVar(""),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : ObjectiveEntry {

    override fun display(player: Player?): String {
        if (player == null) return inactiveObjectiveDisplay

        val currentCount = count.get(player)
        val targetStr = target.get(player) ?: ""
        val displayStr = display.get(player) ?: ""
        val complete = matchesTarget(currentCount.absoluteValue, targetStr)

        val text = when {
            complete -> countableObjectiveDisplay
            criteria.matches(player) -> showingObjectiveDisplay
            else -> inactiveObjectiveDisplay
        }

        return text
            .replaceTagPlaceholders("display", displayStr)
            .replaceTagPlaceholders("count", currentCount.toString())
            .replaceTagPlaceholders("target", displayTarget(targetStr))
            .parsePlaceholders(player)
    }
}
