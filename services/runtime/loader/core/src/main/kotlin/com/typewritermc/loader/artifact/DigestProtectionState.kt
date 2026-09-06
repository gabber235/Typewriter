package com.typewritermc.loader.artifact

import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.loader.shared.SharedArtifactDescriptor

/**
 * Collects retention roots before blob garbage collection.
 *
 * Current and previous deployments, shared descriptors, transfers, accepted candidates, and rollout projections
 * protect their digests. The caller supplies a coherent view and coordinates concurrent publication.
 */
data class DigestProtectionState(
    val currentDeployment: DeploymentSnapshot?,
    val previousDeployment: DeploymentSnapshot?,
    val currentSharedArtifacts: Collection<SharedArtifactDescriptor>,
    val activeTransferDigests: Set<ArtifactDigest>,
    val acceptedCandidateDigests: Set<ArtifactDigest>,
    val rolloutProjectionDigests: Set<ArtifactDigest>,
) {
    fun protectedDigests(): Set<ArtifactDigest> =
        buildSet {
            currentDeployment?.content?.digests()?.let(::addAll)
            previousDeployment?.content?.digests()?.let(::addAll)
            currentSharedArtifacts.mapNotNullTo(this) { it.digest }
            addAll(activeTransferDigests)
            addAll(acceptedCandidateDigests)
            addAll(rolloutProjectionDigests)
        }
}

private fun com.typewritermc.loader.deployment.DeploymentContent.digests(): Set<ArtifactDigest> =
    buildSet {
        add(realm.digest)
        add(primaryEngine.digest)
        add(panelEngine.digest)
        extensions.mapTo(this) { it.digest }
    }
