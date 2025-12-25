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
    @Help("The target value to reach for completion.")
    val target: Var<Int> = ConstVar(0),
    @Help("The display supports the <count> and <target> tags from the fact.")
    @Default("\"<count>/<target>\"")
    override val display: Var<String> = ConstVar(""),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : ObjectiveEntry {
    override fun display(player: Player?): String {
        val text = when {
            player == null -> inactiveObjectiveDisplay
            count.get(player).absoluteValue == target.get(player).absoluteValue -> countableObjectiveDisplay
            criteria.matches(player) -> showingObjectiveDisplay
            else -> inactiveObjectiveDisplay
        }
        return text
            .replaceTagPlaceholders("display", display.get(player) ?: "")
            .replaceTagPlaceholders("count", count.get(player).toString())
            .replaceTagPlaceholders("target", target.get(player).toString())
            .parsePlaceholders(player)
    }
}