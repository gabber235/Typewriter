package com.typewritermc.realm.deployment

import com.typewritermc.engine.EngineId
import java.util.concurrent.atomic.AtomicLong

/** Collects the Realm side artifacts and activators before a shared deployment revision is assigned. */
data class RealmManifestDraft(
    val targetEngine: EngineId,
    val targetEngineMajor: Int,
    val realm: ArtifactReference,
    val panelEngine: ArtifactReference,
    val extensions: List<ArtifactReference>,
    val activators: List<ManifestActivator>,
)

/** Collects the execution side artifacts and activators before a shared deployment revision is assigned. */
data class ExecutionManifestDraft(
    val targetEngine: EngineId,
    val engine: ArtifactReference,
    val capabilities: List<ArtifactReference>,
    val extensions: List<ArtifactReference>,
    val activators: List<ManifestActivator>,
)

/** Returns the Realm and execution manifests that share one atomic logical deployment revision. */
data class PublishedDeploymentManifests(
    val realm: RealmDeploymentManifest,
    val execution: ExecutionDeploymentManifest,
)

/**
 * Publishes deterministic paired manifests for one compatible Realm and execution target.
 *
 * Publication assigns one strictly increasing revision to both manifests and sorts extensions, capabilities, and
 * activators for reproducible output. Mismatched Realm and execution targets fail before advancing the revision.
 */
class ManifestPublisher(
    initialRevision: Long = 0,
) {
    private val revision = AtomicLong(initialRevision)

    fun publish(
        realm: RealmManifestDraft,
        execution: ExecutionManifestDraft,
    ): PublishedDeploymentManifests {
        require(realm.targetEngine == execution.targetEngine) { "Realm and execution targets must match." }
        val deploymentRevision = revision.incrementAndGet()
        return PublishedDeploymentManifests(
            realm =
                RealmDeploymentManifest(
                    revision = deploymentRevision,
                    targetEngine = realm.targetEngine,
                    targetEngineMajor = realm.targetEngineMajor,
                    realm = realm.realm,
                    panelEngine = realm.panelEngine,
                    extensions = realm.extensions.sortedBy { it.key.id.value },
                    activators = realm.activators.sortedWith(activatorOrder),
                ),
            execution =
                ExecutionDeploymentManifest(
                    revision = deploymentRevision,
                    targetEngine = execution.targetEngine,
                    engine = execution.engine,
                    capabilities = execution.capabilities.sortedBy { it.key.id.value },
                    extensions = execution.extensions.sortedBy { it.key.id.value },
                    activators = execution.activators.sortedWith(activatorOrder),
                ),
        )
    }

    private companion object {
        val activatorOrder = compareBy(ManifestActivator::extensionId, ManifestActivator::className)
    }
}
