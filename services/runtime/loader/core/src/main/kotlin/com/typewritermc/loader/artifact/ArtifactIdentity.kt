package com.typewritermc.loader.artifact

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.DigestAlgorithm
import kotlinx.serialization.Serializable

/**
 * Names a release independently of the bytes imported for it.
 *
 * Multiple imports may share a coordinate; candidate selection uses import revision to select among them, while
 * digests identify exact content.
 */
@Serializable
data class ArtifactCoordinate(
    val id: ArtifactId,
    val version: ArtifactVersion,
)

/**
 * Pins a deployable artifact to exact verified bytes and a declared release coordinate.
 *
 * Sizes count bytes and must be nonnegative. Capability artifacts cannot be deployed separately because they are
 * bundled into engines.
 */
@Serializable
data class DeploymentArtifact(
    val coordinate: ArtifactCoordinate,
    val kind: ArtifactKind,
    val digest: ArtifactDigest,
    val size: Long,
) {
    init {
        require(size >= 0) { "Artifact size must not be negative." }
        require(kind != ArtifactKind.CAPABILITY) { "Capabilities are distributed only inside engine artifacts." }
    }
}

/**
 * Retains the source of an accepted artifact for diagnostics and selection history.
 *
 * Provenance does not establish content integrity; the deployment digest supplies that identity.
 */
@Serializable
sealed interface ArtifactProvenance {
    @Serializable
    data class LocalInbox(
        val relativePath: String,
        val importRevision: Long,
    ) : ArtifactProvenance

    @Serializable
    data class OfficialRepository(
        val repository: RepositoryId,
        val objectId: String,
    ) : ArtifactProvenance
}

@JvmInline
@Serializable
value class RepositoryId(
    val value: String,
)
