package com.typewritermc.engine.runtime

import com.typewritermc.engine.LoadedCompiledArtifact
import com.typewritermc.engine.LoadedPublishedContent
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import com.typewritermc.services.libs.filetransfer.blob.requireValue
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
                    blobs.fetchVerified(ArtifactDigest(DigestAlgorithm.SHA_256, output.blob.digest), output.blob.size),
                )
            },
        )
}

/** Fetches whole content and checks it against the descriptor's size and digest before the engine reads it. */
private suspend fun BlobEndpoint.fetchVerified(
    digest: ArtifactDigest,
    expectedSize: Long,
): ByteArray =
    fetch(digest).requireValue().also { bytes ->
        require(bytes.size.toLong() == expectedSize && ArtifactDigest.sha256(bytes) == digest) {
            "Compiled artifact $digest does not match its descriptor."
        }
    }
