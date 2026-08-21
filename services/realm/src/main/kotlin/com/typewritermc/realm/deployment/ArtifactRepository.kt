package com.typewritermc.realm.deployment

import com.typewritermc.engine.SemanticVersion
import com.typewritermc.services.libs.filetransfer.FileId
import com.typewritermc.services.libs.filetransfer.FileKey
import com.typewritermc.services.libs.filetransfer.FileRevision
import com.typewritermc.services.libs.filetransfer.FileTransferResult
import com.typewritermc.services.libs.filetransfer.storage.FileSystemFileTransferEndpoint

/** Produces an optional authenticity signature after immutable artifact storage has verified content. */
fun interface ArtifactSigner {
    suspend fun sign(
        key: FileKey,
        digest: String,
    ): String?
}

/**
 * Imports versioned runtime artifacts into the stable host store owned outside the replaceable Realm runtime.
 *
 * Artifact keys derive from logical identity and exact version. Reimporting identical content is idempotent, while
 * different content for an existing key fails through the immutable file transfer contract.
 */
class ImmutableArtifactRepository(
    val endpoint: FileSystemFileTransferEndpoint,
    private val signer: ArtifactSigner,
) {
    suspend fun import(
        id: String,
        version: SemanticVersion,
        kind: ArtifactKind,
        bytes: ByteArray,
    ): ArtifactImportResult {
        val key = FileKey(FileId.of(id), FileRevision.of(version.toString()))
        return when (val result = endpoint.import(key, bytes)) {
            is FileTransferResult.Failure -> {
                ArtifactImportResult.Failure(result)
            }

            is FileTransferResult.Success -> {
                val metadata = result.value
                ArtifactImportResult.Success(
                    ArtifactReference(
                        kind = kind,
                        key = metadata.key,
                        version = version,
                        size = metadata.size,
                        digest = metadata.digest,
                        signature = signer.sign(metadata.key, metadata.digest.value),
                    ),
                )
            }
        }
    }
}

/** Reports the published artifact reference or the exact storage failure that prevented import. */
sealed interface ArtifactImportResult {
    data class Success(
        val reference: ArtifactReference,
    ) : ArtifactImportResult

    data class Failure(
        val transfer: FileTransferResult.Failure,
    ) : ArtifactImportResult
}
