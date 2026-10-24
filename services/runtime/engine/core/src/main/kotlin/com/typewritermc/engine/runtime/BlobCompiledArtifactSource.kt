package com.typewritermc.engine.runtime

import com.typewritermc.engine.ContentDigest
import com.typewritermc.engine.LoadedCompiledArtifact
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.engine.PublishedContent
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import com.typewritermc.services.libs.filetransfer.blob.readVerified

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
                    blobs.readVerified(output.blob.digest.asArtifactDigest(), output.blob.size),
                )
            },
        )
}

private fun ContentDigest.asArtifactDigest(): ArtifactDigest = ArtifactDigest(DigestAlgorithm.SHA_256, value)
