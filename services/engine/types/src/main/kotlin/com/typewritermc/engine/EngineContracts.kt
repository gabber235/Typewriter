package com.typewritermc.engine

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

@ConsistentCopyVisibility
data class SemanticVersion private constructor(
    val major: Int,
    val minor: Int,
    val patch: Int,
) : Comparable<SemanticVersion> {
    override fun compareTo(other: SemanticVersion): Int =
        compareValuesBy(this, other, SemanticVersion::major, SemanticVersion::minor, SemanticVersion::patch)

    override fun toString(): String = "$major.$minor.$patch"

    companion object {
        private val pattern = Regex("(0|[1-9]\\d*)\\.(0|[1-9]\\d*)\\.(0|[1-9]\\d*)")

        fun of(
            major: Int,
            minor: Int,
            patch: Int,
        ): SemanticVersion {
            require(major >= 0) { "Major version must not be negative." }
            require(minor >= 0) { "Minor version must not be negative." }
            require(patch >= 0) { "Patch version must not be negative." }
            return SemanticVersion(major, minor, patch)
        }

        fun parse(value: String): SemanticVersion {
            val match =
                requireNotNull(pattern.matchEntire(value)) {
                    "Version must use canonical major.minor.patch syntax: $value"
                }
            return of(
                match.groupValues[1].toInt(),
                match.groupValues[2].toInt(),
                match.groupValues[3].toInt(),
            )
        }
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
