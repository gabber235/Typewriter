package com.typewritermc.loader.artifact

import com.typewritermc.loader.rollout.VerifiedArtifactSource
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.requireStored
import com.typewritermc.services.libs.filetransfer.blob.requireValue
import java.nio.file.Path

/**
 * Materializes artifact bytes in a local digest store before classpath use.
 *
 * A metadata hit returns the cached path without rehashing. Missing content is fetched whole and stored locally,
 * where the store verifies size and digest before the path becomes visible. A failed fetch leaves nothing behind.
 */
class VerifiedArtifactCache(
    private val source: BlobEndpoint,
    private val cache: FileDigestBlobStore,
) : VerifiedArtifactSource {
    override suspend fun fetch(digest: ArtifactDigest): Path {
        if (cache.metadata(digest) is BlobResult.Success) return cache.pathFor(digest)
        val expected = source.metadata(digest).requireValue()
        require(expected.digest == digest && expected.size <= TRANSFERRED_BLOB_MAX_BYTES) { "Artifact $digest cannot be transferred." }
        cache.store(expected, source.fetch(digest).requireValue()).requireStored()
        return cache.pathFor(digest)
    }
}
