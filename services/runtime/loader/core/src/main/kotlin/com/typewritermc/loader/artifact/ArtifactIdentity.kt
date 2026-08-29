package com.typewritermc.loader.artifact

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.DigestAlgorithm
import kotlinx.serialization.Serializable

@Serializable
data class ArtifactCoordinate(
    val id: ArtifactId,
    val version: ArtifactVersion,
)

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
