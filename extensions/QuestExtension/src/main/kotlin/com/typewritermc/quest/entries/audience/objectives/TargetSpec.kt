package com.typewritermc.quest.entries.audience.objectives

/**
 * Represents a single target specification token.
 * Implementations: [ExactTarget], [RangeTarget], [LowerBoundTarget], [UpperBoundTarget],
 * [UniversalTarget], [EmptyTarget], [CompositeTarget].
 */
sealed interface TargetSpec {
    /**
     * Checks if the provided value satisfies the current target specification.
     *
     * @param value The value to be checked against the target specification.
     * @return True if the value is considered within the target specification; otherwise, false.
     */
    fun contains(value: Int): Boolean

    /**
     * Determines whether the current TargetSpec fully encompasses another TargetSpec.
     * This means that all values accepted by the provided TargetSpec are also accepted
     * by the current TargetSpec.
     *
     * @param other The TargetSpec to check for inclusion within the current TargetSpec.
     * @return True if the current TargetSpec subsumes the provided TargetSpec; otherwise, false.
     */
    fun subsumes(other: TargetSpec): Boolean

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

            // Deduplicate before the subsumption pass so "5,5" doesn't eliminate itself
            val deduped = tokens.distinct()

            // Remove any token fully subsumed by another token in the list
            val simplified = deduped.filter { candidate ->
                deduped.none { other -> other != candidate && other.subsumes(candidate) }
            }

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

    companion object {
        fun tryParse(token: String): ExactTarget? =
            token.toIntOrNull()?.let { ExactTarget(it) }
    }
}

/** Matches an inclusive integer range [min]-[max]. */
data class RangeTarget(val min: Int, val max: Int) : TargetSpec {
    override fun contains(value: Int) = value in min..max
    override fun subsumes(other: TargetSpec) = when (other) {
        is ExactTarget -> other.value in min..max
        is RangeTarget -> other.min >= min && other.max <= max
        else -> false
    }

    companion object {
        private val RANGE_REGEX = Regex("""^(-?\d+)-(-?\d+)$""")

        fun tryParse(token: String): RangeTarget? {
            val match = RANGE_REGEX.matchEntire(token) ?: return null
            val from = match.groupValues[1].toIntOrNull() ?: return null
            val to = match.groupValues[2].toIntOrNull() ?: return null
            return if (from <= to) RangeTarget(from, to) else null
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

    companion object {
        fun tryParse(token: String): UpperBoundTarget? {
            if (!token.startsWith("..")) return null
            return token.drop(2).trim().toIntOrNull()?.let { UpperBoundTarget(it) }
        }
    }
}

/** Matches all integers. Produced when the spec set covers the entire number line, or explicitly via "*" or "..". */
object UniversalTarget : TargetSpec {
    override fun contains(value: Int) = true
    override fun subsumes(other: TargetSpec) = true

    fun tryParse(token: String): UniversalTarget? =
        if (token == "*" || token == "..") UniversalTarget else null
}

/** Matches nothing. Produced from a blank or entirely invalid spec string. */
object EmptyTarget : TargetSpec {
    override fun contains(value: Int) = false
    override fun subsumes(other: TargetSpec) = other is EmptyTarget
}

/** A simplified union of multiple [TargetSpec] tokens. */
data class CompositeTarget(val specs: List<TargetSpec>) : TargetSpec {
    override fun contains(value: Int) = specs.any { it.contains(value) }
    override fun subsumes(other: TargetSpec) = specs.any { it.subsumes(other) }
}
