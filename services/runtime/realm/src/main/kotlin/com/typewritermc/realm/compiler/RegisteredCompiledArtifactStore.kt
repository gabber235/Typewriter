package com.typewritermc.realm.compiler

import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PublishedContent
import com.typewritermc.engine.PublishedOutput
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.BlobEndpoint
import com.typewritermc.loader.api.artifact.BlobMetadata
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.DEFAULT_CHUNK_SIZE
import com.typewritermc.loader.api.artifact.TransferId
import com.typewritermc.scripting.RuntimeMemberSignature

/** Stores the complete published output set without interpreting payload media types. */
class RegisteredCompiledArtifactStore(
    private val blobs: BlobEndpoint,
) {
    suspend fun store(
        publication: PublicationId,
        catalog: CatalogGeneration,
        implementationToken: String,
        runtimeSignatures: Set<RuntimeMemberSignature>,
        artifacts: Collection<CompiledArtifact>,
    ): PublishedContent =
        PublishedContent(
            publication = publication,
            formatRevision = 2,
            catalog = catalog,
            implementationToken = implementationToken,
            runtimeSignatures = runtimeSignatures,
            outputs =
                artifacts.map { artifact ->
                    PublishedOutput(
                        reference =
                            CompiledArtifactReference(
                                root = artifact.root,
                                formatRevision = artifact.formatRevision,
                                mediaType = artifact.mediaType,
                                semanticDigest = artifact.semanticDigest,
                            ),
                        blob = write(artifact.payload),
                    )
                },
        )

    private suspend fun write(bytes: ByteArray): CompiledBlobPointer {
        val digest = ArtifactDigest.sha256(bytes)
        val expected = BlobMetadata(digest, bytes.size.toLong())
        when (val existing = blobs.metadata(digest)) {
            is BlobResult.Success -> return existing.value.pointer()
            BlobResult.NotFound -> Unit
            is BlobResult.Conflict -> error(existing.reason)
            is BlobResult.Invalid -> error(existing.reason)
        }
        val transfer = TransferId.create()
        val session = blobs.beginWrite(transfer, expected).success("begin compiled artifact write")
        var offset = session.offset
        while (offset < bytes.size) {
            val end = minOf(bytes.size, offset.toInt() + DEFAULT_CHUNK_SIZE)
            offset = blobs.write(transfer, offset, bytes.copyOfRange(offset.toInt(), end)).success("write compiled artifact")
        }
        return blobs.complete(transfer).success("complete compiled artifact write").pointer()
    }
}

private fun BlobMetadata.pointer() = CompiledBlobPointer(ContentDigest(digest.value), size)

private fun <T> BlobResult<T>.success(operation: String): T =
    when (this) {
        is BlobResult.Success -> value
        BlobResult.NotFound -> error("$operation failed because the blob was not found.")
        is BlobResult.Conflict -> error("$operation failed: $reason")
        is BlobResult.Invalid -> error("$operation failed: $reason")
    }
