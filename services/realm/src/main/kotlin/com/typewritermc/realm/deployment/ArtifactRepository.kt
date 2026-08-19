package com.typewritermc.realm.deployment

import com.typewritermc.engine.SemanticVersion
import com.typewritermc.services.libs.filetransfer.FileId
import com.typewritermc.services.libs.filetransfer.FileKey
import com.typewritermc.services.libs.filetransfer.FileRevision
import com.typewritermc.services.libs.filetransfer.FileTransferResult
import com.typewritermc.services.libs.filetransfer.storage.FileSystemFileTransferEndpoint

fun interface ArtifactSigner {
    suspend fun sign(
        key: FileKey,
        digest: String,
    ): String?
}

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

sealed interface ArtifactImportResult {
    data class Success(
        val reference: ArtifactReference,
    ) : ArtifactImportResult

    data class Failure(
        val transfer: FileTransferResult.Failure,
    ) : ArtifactImportResult
}
