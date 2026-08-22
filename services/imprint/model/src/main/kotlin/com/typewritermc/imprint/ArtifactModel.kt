package com.typewritermc.imprint

import io.github.z4kn4fein.semver.Version
import io.github.z4kn4fein.semver.constraints.Condition
import io.github.z4kn4fein.semver.constraints.ConditionFormatter
import io.github.z4kn4fein.semver.constraints.DefaultFormatter
import io.github.z4kn4fein.semver.constraints.EqualityCondition
import io.github.z4kn4fein.semver.constraints.RangeCondition
import io.github.z4kn4fein.semver.constraints.toConstraint
import io.github.z4kn4fein.semver.constraints.toConstraintOrNull
import io.github.z4kn4fein.semver.constraints.toMavenFormat
import io.github.z4kn4fein.semver.toVersion
import io.github.z4kn4fein.semver.toVersionOrNull
import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

/** Identifies one Typewriter artifact independently from its Gradle or Maven coordinates. */
@JvmInline
@Serializable
value class ArtifactId(
    val value: String,
) {
    init {
        require(value.matches(VALID_PATTERN)) {
            "Artifact id must contain valid alphanumeric identifier segments."
        }
    }

    override fun toString(): String = value

    private companion object {
        val VALID_PATTERN = Regex("[A-Za-z0-9][A-Za-z0-9_.-]*(?::[A-Za-z0-9][A-Za-z0-9_.-]*)*")
    }
}

/** Stores an exact Semantic Versioning value used as an artifact identity. */
@JvmInline
@Serializable
value class ArtifactVersion(
    val value: String,
) : Comparable<ArtifactVersion> {
    init {
        require(value.toVersionOrNull(strict = true) != null) {
            "Artifact version must use complete semantic version syntax."
        }
    }

    val semanticVersion: Version
        get() = value.toVersion(strict = true)

    override fun compareTo(other: ArtifactVersion): Int = semanticVersion.compareTo(other.semanticVersion)

    override fun toString(): String = value
}

/**
 * Stores one compatibility expression using the complete Kotlin SemVer constraint language.
 *
 * The original expression remains the manifest contract. Gradle resolution uses [mavenRange], while resolved artifacts
 * are checked again using [accepts].
 */
@JvmInline
@Serializable
value class VersionConstraint(
    val expression: String,
) {
    init {
        require(expression.isNotBlank() && expression.toConstraintOrNull() != null) {
            "Version constraint must use valid semantic version constraint syntax."
        }
    }

    val mavenRange: String
        get() = expression.toConstraint().toMavenFormat()

    fun accepts(version: ArtifactVersion): Boolean = expression.toConstraint().isSatisfiedBy(version.semanticVersion)

    fun isEquivalentTo(other: VersionConstraint): Boolean = expression.toConstraint() == other.expression.toConstraint()

    fun intersect(other: VersionConstraint): VersionConstraint? {
        val formatter = DefaultFormatter()
        val left = expression.toConstraint().conditions()
        val right = other.expression.toConstraint().conditions()
        val intersections =
            left
                .flatMap { leftCondition ->
                    right.mapNotNull { rightCondition ->
                        val candidateExpression =
                            "${formatter.formatCondition(leftCondition)} ${formatter.formatCondition(rightCondition)}"
                        val candidate = candidateExpression.toConstraintOrNull() ?: return@mapNotNull null
                        candidate.conditions().filter(::isSatisfiable).takeIf(List<Condition>::isNotEmpty)
                    }
                }.flatten()
        if (intersections.isEmpty()) return null

        val normalized = intersections.joinToString(" || ") { formatter.formatCondition(it) }
        return VersionConstraint(normalized)
    }

    override fun toString(): String = expression
}

private fun io.github.z4kn4fein.semver.constraints.Constraint.conditions(): List<Condition> {
    val collector = ConditionCollector()
    format(collector)
    return collector.conditions
}

private class ConditionCollector : ConditionFormatter {
    val conditions = mutableListOf<Condition>()
    override val orSeparator: String = ""

    override fun formatCondition(condition: Condition): String {
        conditions += condition
        return ""
    }
}

private fun isSatisfiable(condition: Condition): Boolean =
    when (condition) {
        is RangeCondition -> {
            condition.start.version < condition.end.version ||
                (
                    condition.start.isSatisfiedBy(condition.end.version) &&
                        condition.end.isSatisfiedBy(condition.start.version)
                )
        }

        is EqualityCondition -> {
            true
        }

        else -> {
            true
        }
    }

/** Identifies the public contract implemented by an artifact. */
@Serializable
enum class ArtifactKind {
    ENGINE,
    CAPABILITY,
    EXTENSION,
}

/** Records one declared compatibility requirement. */
@Serializable
data class ArtifactRequirement(
    val id: ArtifactId,
    val version: VersionConstraint,
)

/** Records the exact artifact selected while building another artifact. */
@Serializable
data class ResolvedArtifact(
    val id: ArtifactId,
    val version: ArtifactVersion,
    val kind: ArtifactKind,
)

/** Carries one opaque generated resource into a final artifact manifest. */
@Serializable
data class GeneratedContribution(
    val origin: ArtifactId,
    val sourcePart: String,
    val producer: String,
    val name: String,
    val payload: ByteArray,
) {
    init {
        requireValidSourcePart(sourcePart)
        require(producer.matches(PATH_SEGMENT_PATTERN)) { "Contribution producer must be one safe path segment." }
        require(name.isNotBlank() && name.split('/').all(PATH_SEGMENT_PATTERN::matches)) {
            "Contribution name must be a safe relative path."
        }
    }
}

/** Describes one source part embedded in an extension JAR. */
@Serializable
sealed interface ExtensionSourcePart {
    val name: String
    val includes: List<String>
}

/** Describes the source part inherited by every targeted extension source part. */
@Serializable
@SerialName("common")
data object CommonExtensionSourcePart : ExtensionSourcePart {
    override val name: String = COMMON_SOURCE_PART
    override val includes: List<String> = emptyList()
}

/** Describes one extension source part compiled against a single engine. */
@Serializable
@SerialName("engine")
data class EngineExtensionSourcePart(
    override val name: String,
    val requirement: ArtifactRequirement,
    val resolved: ResolvedArtifact,
    override val includes: List<String> = emptyList(),
) : ExtensionSourcePart {
    init {
        requireValidSourcePart(name)
        require(name != COMMON_SOURCE_PART) { "A targeted source part cannot use the reserved common name." }
        require(resolved.kind == ArtifactKind.ENGINE) { "An engine source part must resolve an engine artifact." }
        require(requirement.id == resolved.id) { "An engine source part requirement must match its resolved artifact." }
    }
}

/** Describes one extension source part compiled against one or more capabilities. */
@Serializable
@SerialName("capabilities")
data class CapabilityExtensionSourcePart(
    override val name: String,
    val requirements: List<ArtifactRequirement>,
    val resolved: List<ResolvedArtifact>,
    override val includes: List<String> = emptyList(),
) : ExtensionSourcePart {
    init {
        requireValidSourcePart(name)
        require(name != COMMON_SOURCE_PART) { "A targeted source part cannot use the reserved common name." }
        require(requirements.isNotEmpty()) { "A capability source part must declare at least one capability." }
        require(resolved.all { it.kind == ArtifactKind.CAPABILITY }) {
            "A capability source part may resolve only capability artifacts."
        }
        require(requirements.all { requirement -> resolved.any { it.id == requirement.id } }) {
            "Every capability source part requirement must have a resolved artifact."
        }
    }
}

const val COMMON_SOURCE_PART = "common"

private val SOURCE_PART_PATTERN = Regex("[A-Za-z][A-Za-z0-9_]*")
private val PATH_SEGMENT_PATTERN = Regex("[^/\\\\.][^/\\\\]*")

private fun requireValidSourcePart(name: String) {
    require(name.matches(SOURCE_PART_PATTERN)) { "Extension source part name is invalid." }
}
