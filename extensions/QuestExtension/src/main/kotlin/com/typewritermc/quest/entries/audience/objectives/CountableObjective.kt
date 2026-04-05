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
 * Represents a single target specification token.
 * Implementations: [ExactTarget], [RangeTarget], [LowerBoundTarget], [UpperBoundTarget],
 * [UniversalTarget], [EmptyTarget].
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
         * Parses a comma-separated target string into a simplified [CompositeTarget].
         * Invalid tokens are silently dropped. An empty or blank string returns [EmptyTarget].
         * A combination that covers all integers returns [UniversalTarget].
         */
        fun parse(raw: String): TargetSpec {
            if (raw.isBlank()) return EmptyTarget

            val tokens = raw.split(",")
                .map { it.trim() }
                .filter { it.isNotEmpty() }
                .mapNotNull { parseToken(it) }

            if (tokens.isEmpty()) return EmptyTarget

            // Remove any token fully subsumed by another token in the list
            val simplified = tokens.filter { candidate ->
                tokens.none { other -> other !== candidate && other.subsumes(candidate) }
            }

            // Check if the simplified set covers all integers
            val hasLower = simplified.any { it is UpperBoundTarget } // ..N covers -inf to N
            val hasUpper = simplified.any { it is LowerBoundTarget } // N.. covers N to +inf
            if (hasLower && hasUpper) {
                val lower = simplified.filterIsInstance<UpperBoundTarget>().maxOf { it.max }
                val upper = simplified.filterIsInstance<LowerBoundTarget>().minOf { it.min }
                if (upper <= lower + 1) return UniversalTarget
            }

            return when {
                simplified.size == 1 -> simplified.first()
                else -> CompositeTarget(simplified)
            }
        }

        private fun parseToken(token: String): TargetSpec? = when {
            token == "*" -> UniversalTarget
            token.endsWith("..") -> {
                token.dropLast(2).trim().toIntOrNull()?.let { LowerBoundTarget(it) }
            }
            token.startsWith("..") -> {
                token.drop(2).trim().toIntOrNull()?.let { UpperBoundTarget(it) }
            }
            token.toIntOrNull() != null -> ExactTarget(token.toIntOrNull()!!)
            token.contains("-") -> {
                val parts = token.split("-", limit = 2)
                val from = parts[0].trim().toIntOrNull()
                val to = parts.getOrNull(1)?.trim()?.toIntOrNull()
                if (from != null && to != null && from <= to) RangeTarget(from, to) else null
            }
            else -> null
        }
    }
}

/** matches exactly one value. */
data class ExactTarget(val value: Int) : TargetSpec {
    override fun contains(value: Int) = value == this.value
    override fun subsumes(other: TargetSpec) = other is ExactTarget && other.value == value
    override fun display() = value.toString()
}

/** matches an inclusive integer range [min]..[max]. */
data class RangeTarget(val min: Int, val max: Int) : TargetSpec {
    override fun contains(value: Int) = value in min..max
    override fun subsumes(other: TargetSpec) = when (other) {
        is ExactTarget -> other.value in min..max
        is RangeTarget -> other.min >= min && other.max <= max
        else -> false
    }
    override fun display() = "$min-$max"
}

/** matches any value >= [min] (open-ended upper, e.g. "32.."). */
data class LowerBoundTarget(val min: Int) : TargetSpec {
    override fun contains(value: Int) = value >= min
    override fun subsumes(other: TargetSpec) = when (other) {
        is ExactTarget -> other.value >= min
        is RangeTarget -> other.min >= min
        is LowerBoundTarget -> other.min >= min
        else -> false
    }
    override fun display() = "$min.."
}

/** matches any value <= [max] (open-ended lower, e.g. "..10"). */
data class UpperBoundTarget(val max: Int) : TargetSpec {
    override fun contains(value: Int) = value <= max
    override fun subsumes(other: TargetSpec) = when (other) {
        is ExactTarget -> other.value <= max
        is RangeTarget -> other.max <= max
        is UpperBoundTarget -> other.max <= max
        else -> false
    }
    override fun display() = "..$max"
}

/** matches all integers. Produced when the spec set covers the entire number line. */
object UniversalTarget : TargetSpec {
    override fun contains(value: Int) = true
    override fun subsumes(other: TargetSpec) = true
    override fun display() = "*"
}

/** matches nothing. Produced from a blank or entirely invalid spec string */
object EmptyTarget : TargetSpec {
    override fun contains(value: Int) = false
    override fun subsumes(other: TargetSpec) = other is EmptyTarget
    override fun display() = ""
}

/** simplified union of multiple [TargetSpec] tokens */
data class CompositeTarget(val specs: List<TargetSpec>) : TargetSpec {
    override fun contains(value: Int) = specs.any { it.contains(value) }
    override fun subsumes(other: TargetSpec) = specs.any { it.subsumes(other) }
    override fun display() = specs.joinToString(",") { it.display() }
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
        val complete = targetSpec.contains(currentCount.absoluteValue)

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
