package com.typewritermc.loader.rollout

import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.registrar.ServiceId
import kotlinx.serialization.Serializable

/** Identifies the logical Realm coordinated by [CoordinatedRollout] and its host participants. */
@JvmInline
@Serializable
value class RealmId(
    val value: String,
)

/**
 * Records a snapshot accepted after rollout stability checks and the projection blob each host runs for it.
 *
 * Reconciliation repairs hosts to this snapshot without choosing new artifact content; artifact maintenance keeps
 * the projection blobs alive.
 */
@Serializable
data class CommittedDeployment(
    val snapshot: DeploymentSnapshot,
    val projections: Map<ServiceId, ArtifactDigest>,
)
