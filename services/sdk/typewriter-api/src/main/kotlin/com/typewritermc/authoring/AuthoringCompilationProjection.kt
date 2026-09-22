package com.typewritermc.authoring

import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeExpression

/** Stable identity for one opaque compilation output format. */
@JvmInline
value class AuthoringCompilationProjectionId(
    val value: String,
) {
    init {
        require(value.isNotBlank()) { "Compilation projection ids must not be blank." }
    }
}

/** Identifies one compiled resource without exposing its domain model. */
data class AuthoringCompilationRoot(
    val projection: AuthoringCompilationProjectionId,
    val resource: ResourceId,
)

/** SHA256 identity supplied by a compilation adapter. */
@JvmInline
value class AuthoringContentDigest(
    val value: String,
) {
    init {
        require(value.matches(Regex("[0-9a-f]{64}"))) {
            "Compilation content digests must be lowercase SHA256 values."
        }
    }
}

/** An opaque immutable output produced by one compilation projection. */
data class AuthoringCompiledArtifact(
    val root: AuthoringCompilationRoot,
    val formatRevision: Int,
    val mediaType: String,
    val inputFingerprint: AuthoringContentDigest,
    val semanticDigest: AuthoringContentDigest,
    val payload: ByteArray,
) {
    init {
        require(formatRevision > 0) { "Compiled artifact format revisions must be positive." }
        require(mediaType.isNotBlank()) { "Compiled artifact media types must not be blank." }
    }
}

data class AuthoringCompileDiagnostic(
    val code: String,
    val message: String,
    val severity: Severity,
    val source: ResourceId? = null,
    val target: ResourceId? = null,
) {
    enum class Severity {
        ERROR,
        WARNING,
    }
}

sealed interface AuthoringCompilationResult {
    val root: AuthoringCompilationRoot

    data class Success(
        val artifact: AuthoringCompiledArtifact,
    ) : AuthoringCompilationResult {
        override val root: AuthoringCompilationRoot
            get() = artifact.root
    }

    data class Removed(
        override val root: AuthoringCompilationRoot,
    ) : AuthoringCompilationResult

    data class Blocked(
        override val root: AuthoringCompilationRoot,
        val inputFingerprint: AuthoringContentDigest,
        val diagnostics: List<AuthoringCompileDiagnostic>,
    ) : AuthoringCompilationResult
}

/** Produces opaque compiled artifacts from a bounded graph slice. */
interface AuthoringCompilationProjection {
    val id: AuthoringCompilationProjectionId
    val root: TypeExpression
    val graphRequirement: GraphReadRequirement

    fun affectedRoots(
        change: AuthoringChangeSummary,
        before: AuthoringWorkingGraph,
        proposed: AuthoringWorkingGraph,
    ): Set<ResourceId>

    suspend fun compile(
        root: ResourceId,
        graph: AuthoringWorkingGraph,
    ): AuthoringCompilationResult
}
