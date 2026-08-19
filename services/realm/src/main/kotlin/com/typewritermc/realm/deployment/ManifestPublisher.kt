package com.typewritermc.realm.deployment

import com.typewritermc.engine.EngineId
import java.util.concurrent.atomic.AtomicLong

data class RealmManifestDraft(
    val targetEngine: EngineId,
    val targetEngineMajor: Int,
    val realm: ArtifactReference,
    val panelEngine: ArtifactReference,
    val extensions: List<ArtifactReference>,
    val activators: List<ManifestActivator>,
)

data class ExecutionManifestDraft(
    val targetEngine: EngineId,
    val engine: ArtifactReference,
    val layers: List<ArtifactReference>,
    val extensions: List<ArtifactReference>,
    val activators: List<ManifestActivator>,
)

data class PublishedDeploymentManifests(
    val realm: RealmDeploymentManifest,
    val execution: ExecutionDeploymentManifest,
)

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
                    layers = execution.layers.sortedBy { it.key.id.value },
                    extensions = execution.extensions.sortedBy { it.key.id.value },
                    activators = execution.activators.sortedWith(activatorOrder),
                ),
        )
    }

    private companion object {
        val activatorOrder = compareBy(ManifestActivator::extensionId, ManifestActivator::className)
    }
}
