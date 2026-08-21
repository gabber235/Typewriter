package com.typewritermc.realm.deployment

import com.typewritermc.engine.EngineCapabilityId
import com.typewritermc.engine.EngineId
import com.typewritermc.engine.SemanticVersion
import com.typewritermc.services.libs.filetransfer.FileDigest
import com.typewritermc.services.libs.filetransfer.FileKey

/** Identifies the runtime role and compatibility rules of an immutable deployment artifact. */
enum class ArtifactKind {
    REALM,
    PANEL_ENGINE,
    EXECUTION_ENGINE,
    ENGINE_CAPABILITY,
    EXTENSION,
}

/**
 * Pins one immutable artifact by stable file identity, exact version, size, digest, and optional signature.
 *
 * Filesystem paths never enter manifests. Consumers verify size and digest on every local or remote resolution path.
 */
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

/** Selects the child runtime source set that owns one extension activator. */
sealed interface ActivationTarget {
    data object Common : ActivationTarget

    data object Realm : ActivationTarget

    data object Panel : ActivationTarget

    data class Engine(
        val id: EngineId,
    ) : ActivationTarget

    data class Capability(
        val id: EngineCapabilityId,
    ) : ActivationTarget
}

/** Associates one extension activator class with the runtime target that may instantiate it. */
data class ManifestActivator(
    val extensionId: String,
    val className: String,
    val target: ActivationTarget,
)

/**
 * Pins the Realm, implied panel engine, extensions, and activators for one Realm deployment revision.
 *
 * Only common, Realm, and panel activators are valid. Construction rejects artifact kinds or activation targets that
 * could leak execution engine code into the Realm classloader.
 */
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

/**
 * Pins one execution engine, its complete transitive capabilities, extensions, and activators.
 *
 * Only common, capability, and matching engine activators are valid. Engine code and all extension code are replaced as
 * one deployment while content revisions remain independent.
 */
data class ExecutionDeploymentManifest(
    val revision: Long,
    val targetEngine: EngineId,
    val engine: ArtifactReference,
    val capabilities: List<ArtifactReference>,
    val extensions: List<ArtifactReference>,
    val activators: List<ManifestActivator>,
) {
    init {
        require(revision >= 1) { "Manifest revision must be positive." }
        require(engine.kind == ArtifactKind.EXECUTION_ENGINE) { "Execution engine artifact kind is invalid." }
        require(capabilities.all { it.kind == ArtifactKind.ENGINE_CAPABILITY }) {
            "Engine capability artifact kind is invalid."
        }
        require(extensions.all { it.kind == ArtifactKind.EXTENSION }) { "Execution extension artifact kind is invalid." }
        require(
            activators.all { activator ->
                activator.target is ActivationTarget.Common ||
                    activator.target is ActivationTarget.Engine ||
                    activator.target is ActivationTarget.Capability
            },
        ) { "Execution manifest contains a Realm or panel activator." }
    }
}

/** Verifies an artifact signature against the trusted signer configuration of the current environment. */
fun interface ArtifactSignatureVerifier {
    suspend fun verify(reference: ArtifactReference): Boolean
}

/**
 * Enforces artifact signature policy before resolution or activation.
 *
 * Missing signatures are accepted only in explicit development mode. Present signatures are always verified, including
 * development mode, so corrupted signed artifacts cannot silently fall back to unsigned behavior.
 */
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

/** Reports signature validity without exposing verifier implementation failures as successful validation. */
sealed interface ManifestValidationResult {
    data object Valid : ManifestValidationResult

    data class MissingSignature(
        val key: FileKey,
    ) : ManifestValidationResult

    data class InvalidSignature(
        val key: FileKey,
    ) : ManifestValidationResult
}
