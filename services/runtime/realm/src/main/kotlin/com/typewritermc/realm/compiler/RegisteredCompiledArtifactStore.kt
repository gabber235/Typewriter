package com.typewritermc.realm.compiler

import com.typewritermc.authoring.PublicationId
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.engine.CompiledArtifact
import com.typewritermc.engine.CompiledArtifactReference
import com.typewritermc.engine.CompiledBlobPointer
import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.PublishedContent
import com.typewritermc.engine.PublishedOutput
import com.typewritermc.scripting.RuntimeMemberSignature
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobTransfer
import com.typewritermc.services.libs.filetransfer.blob.ByteArrayBlobSource

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
        val source = ByteArrayBlobSource(bytes)
        return BlobTransfer().copyVerified(source, blobs, source.digest).pointer()
    }
}

private fun BlobMetadata.pointer() = CompiledBlobPointer(ContentDigest(digest.value), size)
