package com.typewritermc.engine.runtime

import com.typewritermc.engine.LoadedCompiledArtifact
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import com.typewritermc.services.libs.filetransfer.blob.readVerified
import skirout.editor.v1.compiled_content.PublishedContent

/** Loads and verifies generic compiled artifacts while leaving their payloads opaque. */
class BlobCompiledArtifactSource(
    private val blobs: BlobEndpoint,
) {
    suspend fun load(content: PublishedContent): LoadedPublishedContent =
        LoadedPublishedContent(
            content,
            content.outputs.map { output ->
                LoadedCompiledArtifact(
                    output.reference,
                    blobs.readVerified(ArtifactDigest(DigestAlgorithm.SHA_256, output.blob.digest), output.blob.size),
                )
            },
        )
}
