package com.typewritermc.engine

import io.github.z4kn4fein.semver.Version
import io.github.z4kn4fein.semver.toVersion

/**
 * Identifies an execution engine across manifests, extension targets, and runtime selection.
 *
 * Create identifiers at configuration or protocol boundaries with [of]. The factory rejects values that cannot remain
 * stable in artifact names and metadata.
 */
@JvmInline
value class EngineId private constructor(
    val value: String,
) {
    companion object {
        fun of(value: String): EngineId {
            require(identifierPattern.matches(value)) { "Invalid engine id: $value" }
            return EngineId(value)
        }
    }
}

/**
 * Identifies a complete contract that an engine implements and extensions may compile against.
 *
 * Capabilities compose transitively. Selecting an engine selects its capabilities, so extension authors should not
 * construct capability selections independently from an engine target.
 */
@JvmInline
value class EngineCapabilityId private constructor(
    val value: String,
) {
    companion object {
        fun of(value: String): EngineCapabilityId {
            require(identifierPattern.matches(value)) { "Invalid engine capability id: $value" }
            return EngineCapabilityId(value)
        }
    }
}

/**
 * Represents an API version used for runtime compatibility and exact artifact selection.
 *
 * Compatibility treats the major component as the breaking contract boundary. Ordering follows Semantic Versioning,
 * including pre release precedence, while build metadata does not affect precedence.
 */
class SemanticVersion private constructor(
    private val version: Version,
) : Comparable<SemanticVersion> {
    val major: Int get() = version.major
    val minor: Int get() = version.minor
    val patch: Int get() = version.patch
    val preRelease: String get() = version.preRelease.orEmpty()
    val buildMetadata: String get() = version.buildMetadata.orEmpty()

    override fun compareTo(other: SemanticVersion): Int = version.compareTo(other.version)

    override fun equals(other: Any?): Boolean = other is SemanticVersion && version == other.version

    override fun hashCode(): Int = version.hashCode()

    override fun toString(): String = version.toString()

    companion object {
        fun of(
            major: Int,
            minor: Int,
            patch: Int,
            preRelease: String = "",
            buildMetadata: String = "",
        ): SemanticVersion {
            require(major >= 0) { "Major version must not be negative." }
            require(minor >= 0) { "Minor version must not be negative." }
            require(patch >= 0) { "Patch version must not be negative." }
            return SemanticVersion(Version(major, minor, patch, preRelease, buildMetadata))
        }

        fun parse(value: String): SemanticVersion = SemanticVersion(value.toVersion(strict = true))
    }
}

/**
 * Describes the compatible version range beginning at [minimum] and ending before the next major version.
 *
 * [merge] returns the narrowest compatible requirement. It returns `null` when requirements cross a breaking major
 * version boundary.
 */
data class VersionRequirement(
    val minimum: SemanticVersion,
) {
    fun accepts(version: SemanticVersion): Boolean = version.major == minimum.major && version >= minimum

    fun merge(other: VersionRequirement): VersionRequirement? {
        if (minimum.major != other.minimum.major) return null
        return VersionRequirement(maxOf(minimum, other.minimum))
    }
}

/**
 * Requests one engine capability at a compatible API version.
 *
 * Requirements are resolved transitively from the selected engine and merged before an extension source layout or
 * deployment manifest is produced.
 */
data class EngineCapabilityRequirement(
    val id: EngineCapabilityId,
    val version: VersionRequirement,
)

/**
 * Publishes the complete contract and transitive requirements of one engine capability artifact.
 *
 * An engine claiming this capability must implement the entire contract. Partial or optional implementations belong in
 * separate capabilities.
 */
data class EngineCapabilityDescriptor(
    val id: EngineCapabilityId,
    val version: SemanticVersion,
    val requires: List<EngineCapabilityRequirement> = emptyList(),
)

/**
 * Declares an execution engine API and the capabilities it implements.
 *
 * Extension tooling uses this descriptor to derive capability source sets. Runtime manifests pin the exact engine and
 * capability artifact versions separately.
 */
data class EngineDescriptor(
    val id: EngineId,
    val version: SemanticVersion,
    val capabilities: List<EngineCapabilityRequirement> = emptyList(),
)

private val identifierPattern = Regex("[a-z][a-z0-9]*(?:[._-][a-z0-9]+)*(?::[a-z][a-z0-9]*(?:[._-][a-z0-9]+)*)?")
