package com.typewritermc.realm.deployment

import com.typewritermc.services.libs.filetransfer.FileTransferCoordinator
import com.typewritermc.services.libs.filetransfer.FileTransferEndpoint
import com.typewritermc.services.libs.filetransfer.FileTransferError
import com.typewritermc.services.libs.filetransfer.FileTransferResult
import com.typewritermc.services.libs.filetransfer.TransferId
import java.security.MessageDigest

class ArtifactResolver(
    private val providerHostId: String,
    private val consumerHostId: String,
    private val hostStore: FileTransferEndpoint,
    private val remoteSource: FileTransferEndpoint,
    private val consumerCache: FileTransferEndpoint,
    private val coordinator: FileTransferCoordinator,
) {
    suspend fun resolve(reference: ArtifactReference): ArtifactResolutionResult {
        val source = if (providerHostId == consumerHostId) hostStore else remoteSource
        if (providerHostId == consumerHostId) {
            return verify(source, reference, local = true)
        }
        val transferId = TransferId.of("artifact.${reference.key.id.value}.${reference.key.revision.value}")
        return when (val result = coordinator.download(transferId, reference.key, source, consumerCache)) {
            is FileTransferResult.Failure -> ArtifactResolutionResult.Failure(result.error)
            is FileTransferResult.Success -> verify(consumerCache, reference, local = false)
        }
    }

    private suspend fun verify(
        endpoint: FileTransferEndpoint,
        reference: ArtifactReference,
        local: Boolean,
    ): ArtifactResolutionResult {
        val metadata =
            when (val result = endpoint.metadata(reference.key)) {
                is FileTransferResult.Failure -> return ArtifactResolutionResult.Failure(result.error)
                is FileTransferResult.Success -> result.value
            }
        if (metadata.size != reference.size) {
            return ArtifactResolutionResult.Failure(FileTransferError.SizeMismatch(reference.size, metadata.size))
        }
        if (metadata.digest != reference.digest) {
            return ArtifactResolutionResult.Failure(FileTransferError.DigestMismatch(reference.digest, metadata.digest))
        }

        val digest = MessageDigest.getInstance("SHA-256")
        var offset = 0L
        while (offset < reference.size) {
            val maximumBytes = minOf(FileTransferCoordinator.DEFAULT_CHUNK_SIZE.toLong(), reference.size - offset).toInt()
            val chunk =
                when (val result = endpoint.read(reference.key, offset, maximumBytes)) {
                    is FileTransferResult.Failure -> return ArtifactResolutionResult.Failure(result.error)
                    is FileTransferResult.Success -> result.value
                }
            if (chunk.offset != offset) {
                return ArtifactResolutionResult.Failure(FileTransferError.InvalidOffset(offset, chunk.offset))
            }
            if (chunk.bytes.isEmpty() || chunk.bytes.size > maximumBytes) {
                return ArtifactResolutionResult.Failure(
                    FileTransferError.InvalidChunk("Artifact verification received an invalid chunk"),
                )
            }
            digest.update(chunk.bytes)
            offset += chunk.bytes.size
        }
        val actualDigest =
            com.typewritermc.services.libs.filetransfer.FileDigest.sha256(
                digest.digest().joinToString("") { byte -> "%02x".format(byte) },
            )
        if (actualDigest != reference.digest) {
            return ArtifactResolutionResult.Failure(FileTransferError.DigestMismatch(reference.digest, actualDigest))
        }
        return ArtifactResolutionResult.Success(ResolvedArtifact(reference, endpoint, local))
    }
}

data class ResolvedArtifact(
    val reference: ArtifactReference,
    val endpoint: FileTransferEndpoint,
    val local: Boolean,
)

sealed interface ArtifactResolutionResult {
    data class Success(
        val artifact: ResolvedArtifact,
    ) : ArtifactResolutionResult

    data class Failure(
        val error: FileTransferError,
    ) : ArtifactResolutionResult
}
