package com.typewritermc.realm.deployment

import com.typewritermc.engine.SemanticVersion
import com.typewritermc.services.libs.filetransfer.FileDigest
import com.typewritermc.services.libs.filetransfer.FileKey

/** Identifies the runtime role and compatibility rules of an immutable deployment artifact. */
enum class ArtifactKind {
    REALM,
    ENGINE,
    CAPABILITY,
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
