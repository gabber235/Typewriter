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

private val countableObjectiveDisplay by snippet(
    "quest.objectives.countable.completed",
    "<green>✔</green> <gray><display></gray>"
)

private val displayExact by snippet(
    "quest.objectives.countable.target.exact",
    "<value>"
)
private val displayRange by snippet(
    "quest.objectives.countable.target.range",
    "between <min> and <max>"
)
private val displayLowerBound by snippet(
    "quest.objectives.countable.target.lower_bound",
    "<min> or more"
)
private val displayUpperBound by snippet(
    "quest.objectives.countable.target.upper_bound",
    "<max> or less"
)
private val displayUniversal by snippet(
    "quest.objectives.countable.target.universal",
    "any value"
)
private val displayEmpty by snippet(
    "quest.objectives.countable.target.empty",
    "nothing"
)
private val displayCompositeSeparator by snippet(
    "quest.objectives.countable.target.separator",
    ", or "
)

private fun TargetSpec.display(): String = when (this) {
    is ExactTarget -> displayExact.replaceTagPlaceholders("value", value.toString())
    is RangeTarget -> displayRange
        .replaceTagPlaceholders("min", min.toString())
        .replaceTagPlaceholders("max", max.toString())

    is LowerBoundTarget -> displayLowerBound.replaceTagPlaceholders("min", min.toString())
    is UpperBoundTarget -> displayUpperBound.replaceTagPlaceholders("max", max.toString())
    is UniversalTarget -> displayUniversal
    is EmptyTarget -> displayEmpty
    is CompositeTarget -> specs.joinToString(displayCompositeSeparator) { it.display() }
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
        """
            The target value(s) to reach for completion. Supports exact values (5), inclusive ranges (28-61), 
            open-ended upper (32..), open-ended lower (..10), negative values (-5), negative ranges (-10--3), 
            and comma-separated combinations (28-61,63,70..). 
            Redundant ranges are simplified automatically. Leave blank to never complete.
        """
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
        val targetSpec = TargetSpec.parse(target.get(player))
        val displayStr = display.get(player)
        val complete = targetSpec.contains(currentCount)

        val text = when {
            complete -> countableObjectiveDisplay
            criteria.matches(player) -> showingObjectiveDisplay
            else -> inactiveObjectiveDisplay
        }

        return text
            .replaceTagPlaceholders("display", displayStr)
            .replaceTagPlaceholders("count", currentCount.toString())
            .replaceTagPlaceholders("target", targetSpec.display())
            .parsePlaceholders(player)
    }
}
