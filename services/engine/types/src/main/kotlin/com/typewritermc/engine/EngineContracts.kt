package com.typewritermc.engine

import io.github.z4kn4fein.semver.Version
import io.github.z4kn4fein.semver.toVersion

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

@JvmInline
value class EngineLayerId private constructor(
    val value: String,
) {
    companion object {
        fun of(value: String): EngineLayerId {
            require(identifierPattern.matches(value)) { "Invalid engine layer id: $value" }
            return EngineLayerId(value)
        }
    }
}

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

data class VersionRequirement(
    val minimum: SemanticVersion,
) {
    fun accepts(version: SemanticVersion): Boolean = version.major == minimum.major && version >= minimum

    fun merge(other: VersionRequirement): VersionRequirement? {
        if (minimum.major != other.minimum.major) return null
        return VersionRequirement(maxOf(minimum, other.minimum))
    }
}

data class EngineLayerRequirement(
    val id: EngineLayerId,
    val version: VersionRequirement,
)

data class EngineLayerDescriptor(
    val id: EngineLayerId,
    val version: SemanticVersion,
    val requires: List<EngineLayerRequirement> = emptyList(),
)

data class EngineDescriptor(
    val id: EngineId,
    val version: SemanticVersion,
    val layers: List<EngineLayerRequirement> = emptyList(),
)

private val identifierPattern = Regex("[a-z][a-z0-9]*(?:[._-][a-z0-9]+)*(?::[a-z][a-z0-9]*(?:[._-][a-z0-9]+)*)?")
