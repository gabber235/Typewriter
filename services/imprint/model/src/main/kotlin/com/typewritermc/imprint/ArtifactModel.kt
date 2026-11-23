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

/**
 * Stable logical artifact identity shared by build manifests, deployment selection, and discovery origins.
 * Coordinates may change without changing this identity. Construction rejects empty or unsafe identifier segments;
 * it does not resolve an artifact or establish its availability.
 */
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

/**
 * Exact semantic version attached to a built artifact. Construction requires complete strict semantic version
 * syntax. Ordering uses semantic version precedence through [semanticVersion], while the original string remains
 * the serialized value.
 */
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

    /** Converts this constraint to the Maven range syntax used for dependency resolution. */
    val mavenRange: String
        get() = expression.toConstraint().toMavenFormat()

    /** Returns whether [version] satisfies this constraint. */
    fun accepts(version: ArtifactVersion): Boolean = expression.toConstraint().isSatisfiedBy(version.semanticVersion)

    /** Returns whether two expressions describe the same semantic constraint. */
    fun isEquivalentTo(other: VersionConstraint): Boolean = expression.toConstraint() == other.expression.toConstraint()

    /** Returns the semantic intersection, or null when the two constraints have no satisfying version. */
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
    REALM,
    ENGINE,
    CAPABILITY,
    EXTENSION,
}

/**
 * Compatibility requirement for one logical artifact. The constraint records acceptable versions before
 * resolution; [ResolvedArtifact] records the exact selection. Consumers must validate the selected version against
 * this requirement.
 */
@Serializable
data class ArtifactRequirement(
    val id: ArtifactId,
    val version: VersionConstraint,
)

/**
 * Exact identity, version, and kind selected during a build. Used for dependency provenance and compatibility
 * checks in manifests. This descriptor contains no artifact bytes or download location and does not prove that a
 * runtime has installed the artifact.
 */
@Serializable
data class ResolvedArtifact(
    val id: ArtifactId,
    val version: ArtifactVersion,
    val kind: ArtifactKind,
)

/** Identifies an open-ended contribution producer by one safe resource path segment. */
@JvmInline
@Serializable
value class ProducerId(
    val value: String,
) {
    init {
        require(value.matches(PATH_SEGMENT_PATTERN)) { "Contribution producer must be one safe path segment." }
    }
}

/**
 * Names a contribution within its producer using a safe relative resource path. Segments start with a letter or
 * digit and may also contain underscores, periods, and hyphens.
 */
@JvmInline
@Serializable
value class ContributionName(
    val value: String,
) {
    init {
        require(value.isNotBlank() && value.split('/').all(PATH_SEGMENT_PATTERN::matches)) {
            "Contribution name must be a safe relative path."
        }
    }
}

/** Identifies the declaration source across copies embedded in different artifacts. */
@JvmInline
@Serializable
value class ContributionSourceId(
    val value: String,
) {
    init {
        require(value.matches(Regex("[A-Za-z0-9][A-Za-z0-9_.-]*(?::[A-Za-z0-9][A-Za-z0-9_.-]*)*"))) {
            "Contribution source id must contain valid alphanumeric identifier segments."
        }
    }

    override fun toString(): String = value
}

/**
 * Opaque generated discovery payload. Its source identifies authored content, while the enclosing manifest
 * identifies the artifact that carries executable code. The producer owns payload encoding and interpretation.
 */
@Serializable
data class GeneratedContribution(
    val source: ContributionSourceId,
    val sourcePart: String,
    val producer: ProducerId,
    val name: ContributionName,
    val payload: ByteArray,
) {
    init {
        requireValidSourcePart(sourcePart)
    }
}

/**
 * Paper plugin a source part needs, by the name Paper reports for it. A null [version] accepts any version of the
 * plugin. Construction checks the name only; the deployment resolver decides whether an engine satisfies it.
 */
@Serializable
data class PluginRequirement(
    val name: String,
    val version: VersionConstraint? = null,
) {
    init {
        require(name.matches(PLUGIN_NAME_PATTERN)) { "Plugin name $name is not a name Paper reports." }
    }
}

/**
 * Paper plugin an engine host reports enabled, by the name and version Paper reports for it. Plugin versions follow no
 * standard, so [version] keeps the reported text and [leadingVersion] reads the version a range is checked against.
 */
@Serializable
data class EnabledPlugin(
    val name: String,
    val version: String,
) {
    /**
     * The leading numeric version of [version], with missing minor and patch numbers as zero: `1.7.3` for `1.7.3-b131`,
     * `2.11.6` for `2.11.6-SNAPSHOT`, `1.7.0` for `v1.7`. Null when [version] starts with no number.
     */
    val leadingVersion: ArtifactVersion?
        get() =
            LEADING_VERSION_PATTERN.find(version)?.let { match ->
                val (major, minor, patch) = match.destructured
                ArtifactVersion("${major.toBigInteger()}.${minor.ifEmpty { "0" }.toBigInteger()}.${patch.ifEmpty { "0" }.toBigInteger()}")
            }
}

/**
 * Entry type whose behaviour a source part's handlers run: the canonical text (dense Skir JSON) of the entry's
 * `TypeDefinitionId`, so a reader compares it with `TypeDefinitionId.canonicalText` without Imprint knowing the
 * type catalog.
 */
@JvmInline
@Serializable
value class EntryTypeId(
    val canonicalText: String,
) {
    init {
        require(canonicalText.isNotBlank()) { "An entry type id must not be blank." }
    }

    override fun toString(): String = canonicalText
}

/**
 * Named compilation unit inside an extension artifact. Every targeted part inherits common code implicitly;
 * [includes] names additional targeted parts whose output is visible to it. [plugins] lists every Paper plugin the
 * part needs, its own and those of the parts it includes, and [handledEntries] the entry types whose behaviour the
 * part's own handlers run. The enclosing [ExtensionManifest] validates names, inclusion cycles and plugin
 * inheritance, while build tooling validates compatibility between included targets.
 */
@Serializable
sealed interface ExtensionSourcePart {
    val name: String
    val includes: List<String>
    val plugins: List<PluginRequirement>
    val handledEntries: List<EntryTypeId>
}

/** Describes the source part inherited by every targeted extension source part. It never needs a plugin. */
@Serializable
@SerialName("common")
data class CommonExtensionSourcePart(
    override val handledEntries: List<EntryTypeId> = emptyList(),
) : ExtensionSourcePart {
    override val name: String get() = COMMON_SOURCE_PART
    override val includes: List<String> get() = emptyList()
    override val plugins: List<PluginRequirement> get() = emptyList()

    init {
        requireDistinctContents(this)
    }
}

/**
 * Extension code compiled against one engine contract. [requirement] preserves its supported version range and
 * [resolved] records the engine used to compile it. Construction checks identity and kind; build resolution
 * performs version compatibility checks.
 */
@Serializable
@SerialName("engine")
data class EngineExtensionSourcePart(
    override val name: String,
    val requirement: ArtifactRequirement,
    val resolved: ResolvedArtifact,
    override val includes: List<String> = emptyList(),
    override val plugins: List<PluginRequirement> = emptyList(),
    override val handledEntries: List<EntryTypeId> = emptyList(),
) : ExtensionSourcePart {
    init {
        requireValidSourcePart(name)
        require(name != COMMON_SOURCE_PART) { "A targeted source part cannot use the reserved common name." }
        require(resolved.kind == ArtifactKind.ENGINE) { "An engine source part must resolve an engine artifact." }
        require(requirement.id == resolved.id) { "An engine source part requirement must match its resolved artifact." }
        requireDistinctContents(this)
    }
}

/**
 * Extension code compiled against a set of capability contracts. Requirements express direct compatibility and
 * resolved descriptors record the selected capability graph. A runtime uses the source part metadata to decide
 * eligibility; compilation alone does not make the part available in every deployment.
 */
@Serializable
@SerialName("capabilities")
data class CapabilityExtensionSourcePart(
    override val name: String,
    val requirements: List<ArtifactRequirement>,
    val resolved: List<ResolvedArtifact>,
    override val includes: List<String> = emptyList(),
    override val plugins: List<PluginRequirement> = emptyList(),
    override val handledEntries: List<EntryTypeId> = emptyList(),
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
        requireDistinctContents(this)
    }
}

/** Source part compiled once and implicitly available to every targeted extension part. */
const val COMMON_SOURCE_PART = "common"

private val SOURCE_PART_PATTERN = Regex("[A-Za-z][A-Za-z0-9_]*")
private val PATH_SEGMENT_PATTERN = Regex("[A-Za-z0-9][A-Za-z0-9_.-]*")

/** The characters Paper allows in a plugin name; a space is legal there but never leads or trails. */
private val PLUGIN_NAME_PATTERN = Regex("[A-Za-z0-9_.-](?:[A-Za-z0-9 _.-]*[A-Za-z0-9_.-])?")

private fun requireDistinctContents(part: ExtensionSourcePart) {
    part.plugins.groupBy(PluginRequirement::name).filterValues { it.size > 1 }.keys.firstOrNull()?.let { name ->
        throw IllegalArgumentException("Extension source part ${part.name} lists plugin $name more than once.")
    }
    require(part.handledEntries.distinct().size == part.handledEntries.size) {
        "Extension source part ${part.name} lists a handled entry more than once."
    }
}

private fun requireValidSourcePart(name: String) {
    require(name.matches(SOURCE_PART_PATTERN)) { "Extension source part name is invalid." }
}

private val LEADING_VERSION_PATTERN = Regex("^[vV]?(\\d+)(?:\\.(\\d+))?(?:\\.(\\d+))?")
