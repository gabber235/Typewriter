package com.typewritermc.realm.deployment

import com.typewritermc.engine.EngineId
import com.typewritermc.engine.EngineLayerId
import com.typewritermc.engine.SemanticVersion
import com.typewritermc.services.libs.filetransfer.FileDigest
import com.typewritermc.services.libs.filetransfer.FileKey

enum class ArtifactKind {
    REALM,
    PANEL_ENGINE,
    EXECUTION_ENGINE,
    ENGINE_LAYER,
    EXTENSION,
}

data class ArtifactReference(
    val kind: ArtifactKind,
    val key: FileKey,
    val version: SemanticVersion,
    val size: Long,
    val digest: FileDigest,
    val signature: String?,
) {
    init {
        require(size >= 0) { "Artifact size must not be negative." }
    }
}

sealed interface ActivationTarget {
    data object Common : ActivationTarget

    data object Realm : ActivationTarget

    data object Panel : ActivationTarget

    data class Engine(
        val id: EngineId,
    ) : ActivationTarget

    data class Layer(
        val id: EngineLayerId,
    ) : ActivationTarget
}

data class ManifestActivator(
    val extensionId: String,
    val className: String,
    val target: ActivationTarget,
)

data class RealmDeploymentManifest(
    val revision: Long,
    val targetEngine: EngineId,
    val targetEngineMajor: Int,
    val realm: ArtifactReference,
    val panelEngine: ArtifactReference,
    val extensions: List<ArtifactReference>,
    val activators: List<ManifestActivator>,
) {
    init {
        require(revision >= 1) { "Manifest revision must be positive." }
        require(targetEngineMajor >= 1) { "Target engine major must be positive." }
        require(realm.kind == ArtifactKind.REALM) { "Realm artifact kind is invalid." }
        require(panelEngine.kind == ArtifactKind.PANEL_ENGINE) { "Panel engine artifact kind is invalid." }
        require(extensions.all { it.kind == ArtifactKind.EXTENSION }) { "Realm extension artifact kind is invalid." }
        require(
            activators.all {
                it.target is ActivationTarget.Common || it.target is ActivationTarget.Realm ||
                    it.target is ActivationTarget.Panel
            },
        ) {
            "Realm manifest contains an execution activator."
        }
    }
}

data class ExecutionDeploymentManifest(
    val revision: Long,
    val targetEngine: EngineId,
    val engine: ArtifactReference,
    val layers: List<ArtifactReference>,
    val extensions: List<ArtifactReference>,
    val activators: List<ManifestActivator>,
) {
    init {
        require(revision >= 1) { "Manifest revision must be positive." }
        require(engine.kind == ArtifactKind.EXECUTION_ENGINE) { "Execution engine artifact kind is invalid." }
        require(layers.all { it.kind == ArtifactKind.ENGINE_LAYER }) { "Engine layer artifact kind is invalid." }
        require(extensions.all { it.kind == ArtifactKind.EXTENSION }) { "Execution extension artifact kind is invalid." }
        require(
            activators.all { activator ->
                activator.target is ActivationTarget.Common ||
                    activator.target is ActivationTarget.Engine ||
                    activator.target is ActivationTarget.Layer
            },
        ) { "Execution manifest contains a Realm or panel activator." }
    }
}

fun interface ArtifactSignatureVerifier {
    suspend fun verify(reference: ArtifactReference): Boolean
}

class ManifestPolicy(
    private val developmentMode: Boolean,
    private val verifier: ArtifactSignatureVerifier,
) {
    suspend fun validate(reference: ArtifactReference): ManifestValidationResult {
        if (reference.signature == null && !developmentMode) {
            return ManifestValidationResult.MissingSignature(reference.key)
        }
        if (reference.signature != null && !verifier.verify(reference)) {
            return ManifestValidationResult.InvalidSignature(reference.key)
        }
        return ManifestValidationResult.Valid
    }
}

sealed interface ManifestValidationResult {
    data object Valid : ManifestValidationResult

    data class MissingSignature(
        val key: FileKey,
    ) : ManifestValidationResult

    data class InvalidSignature(
        val key: FileKey,
    ) : ManifestValidationResult
}
