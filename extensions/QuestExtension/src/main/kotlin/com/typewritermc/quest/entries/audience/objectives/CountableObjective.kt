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

private val countableObjectiveDisplay by snippet(
    "quest.objectives.countable.completed",
    "<green>✔</green> <gray><display></gray>"
)

// Display snippets — translatable by end users
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

/**
 * Represents a single target specification token.
 * Implementations: [ExactTarget], [RangeTarget], [LowerBoundTarget], [UpperBoundTarget],
 * [UniversalTarget], [EmptyTarget], [CompositeTarget].
 */
sealed interface TargetSpec {
    /** Returns true if [value] satisfies this spec. */
    fun contains(value: Int): Boolean

    /** Returns true if every value that satisfies [other] also satisfies this spec. */
    fun subsumes(other: TargetSpec): Boolean

    /** Human-readable display string for use in objective text. */
    fun display(): String

    companion object {
        /**
         * Parses a comma-separated target string into a simplified [TargetSpec].
         * Invalid tokens are silently dropped. A blank string returns [EmptyTarget].
         * A combination covering all integers returns [UniversalTarget].
         */
        fun parse(raw: String): TargetSpec {
            if (raw.isBlank()) return EmptyTarget

            val parsers: List<(String) -> TargetSpec?> = listOf(
                UniversalTarget::tryParse,
                ExactTarget::tryParse,
                LowerBoundTarget::tryParse,
                UpperBoundTarget::tryParse,
                RangeTarget::tryParse,
            )

            val tokens = raw.split(",")
                .map { it.trim() }
                .filter { it.isNotEmpty() }
                .mapNotNull { token -> parsers.firstNotNullOfOrNull { it(token) } }

            if (tokens.isEmpty()) return EmptyTarget

            // Remove any token fully subsumed by another token in the list
            val simplified = tokens.filter { candidate ->
                tokens.none { other -> other !== candidate && other.subsumes(candidate) }
            }

            // Check if the simplified set covers all integers
            val maxUpperBound = simplified.filterIsInstance<UpperBoundTarget>().maxOfOrNull { it.max }
            val minLowerBound = simplified.filterIsInstance<LowerBoundTarget>().minOfOrNull { it.min }
            if (maxUpperBound != null && minLowerBound != null && minLowerBound <= maxUpperBound + 1) {
                return UniversalTarget
            }

            return when {
                simplified.size == 1 -> simplified.first()
                else -> CompositeTarget(simplified)
            }
        }
    }
}

/** Matches exactly one value. */
data class ExactTarget(val value: Int) : TargetSpec {
    override fun contains(value: Int) = value == this.value
    override fun subsumes(other: TargetSpec) = other is ExactTarget && other.value == value
    override fun display() = displayExact.replaceTagPlaceholders("value", value.toString())

    companion object {
        fun tryParse(token: String): ExactTarget? =
            token.toIntOrNull()?.let { ExactTarget(it) }
    }
}

/** Matches an inclusive integer range [min]..[max]. */
data class RangeTarget(val min: Int, val max: Int) : TargetSpec {
    override fun contains(value: Int) = value in min..max
    override fun subsumes(other: TargetSpec) = when (other) {
        is ExactTarget -> other.value in min..max
        is RangeTarget -> other.min >= min && other.max <= max
        else -> false
    }
    override fun display() = displayRange
        .replaceTagPlaceholders("min", min.toString())
        .replaceTagPlaceholders("max", max.toString())

    companion object {
        fun tryParse(token: String): RangeTarget? {
            if (!token.contains("-")) return null
            val parts = token.split("-", limit = 2)
            val from = parts[0].trim().toIntOrNull()
            val to = parts.getOrNull(1)?.trim()?.toIntOrNull()
            return if (from != null && to != null && from <= to) RangeTarget(from, to) else null
        }
    }
}

/** Matches any value >= [min] (e.g. "32.."). */
data class LowerBoundTarget(val min: Int) : TargetSpec {
    override fun contains(value: Int) = value >= min
    override fun subsumes(other: TargetSpec) = when (other) {
        is ExactTarget -> other.value >= min
        is RangeTarget -> other.min >= min
        is LowerBoundTarget -> other.min >= min
        else -> false
    }
    override fun display() = displayLowerBound.replaceTagPlaceholders("min", min.toString())

    companion object {
        fun tryParse(token: String): LowerBoundTarget? {
            if (!token.endsWith("..")) return null
            return token.dropLast(2).trim().toIntOrNull()?.let { LowerBoundTarget(it) }
        }
    }
}

/** Matches any value <= [max] (e.g. "..10"). */
data class UpperBoundTarget(val max: Int) : TargetSpec {
    override fun contains(value: Int) = value <= max
    override fun subsumes(other: TargetSpec) = when (other) {
        is ExactTarget -> other.value <= max
        is RangeTarget -> other.max <= max
        is UpperBoundTarget -> other.max <= max
        else -> false
    }
    override fun display() = displayUpperBound.replaceTagPlaceholders("max", max.toString())

    companion object {
        fun tryParse(token: String): UpperBoundTarget? {
            if (!token.startsWith("..")) return null
            return token.drop(2).trim().toIntOrNull()?.let { UpperBoundTarget(it) }
        }
    }
}

/** Matches all integers. Produced when the spec set covers the entire number line. */
object UniversalTarget : TargetSpec {
    override fun contains(value: Int) = true
    override fun subsumes(other: TargetSpec) = true
    override fun display() = displayUniversal

    fun tryParse(token: String): UniversalTarget? =
        if (token == "*") UniversalTarget else null
}

/** Matches nothing. Produced from a blank or entirely invalid spec string. */
object EmptyTarget : TargetSpec {
    override fun contains(value: Int) = false
    override fun subsumes(other: TargetSpec) = other is EmptyTarget
    override fun display() = displayEmpty
}

/** A simplified union of multiple [TargetSpec] tokens. */
data class CompositeTarget(val specs: List<TargetSpec>) : TargetSpec {
    override fun contains(value: Int) = specs.any { it.contains(value) }
    override fun subsumes(other: TargetSpec) = specs.any { it.subsumes(other) }
    override fun display() = specs.joinToString(displayCompositeSeparator) { it.display() }
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
        "The target value(s) to reach for completion. Supports exact values (5), inclusive ranges (28-61), " +
        "open-ended upper (32..), open-ended lower (..10), and comma-separated combinations (28-61,63,70..). " +
        "Redundant ranges are simplified automatically. Leave blank to never complete."
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
