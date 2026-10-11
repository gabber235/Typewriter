package com.typewritermc.loader.artifact

import com.typewritermc.loader.rollout.VerifiedArtifactSource
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.BlobTransfer
import java.nio.file.Path

/**
 * Materializes artifact bytes in a local digest store before classpath use.
 *
 * A metadata hit returns the cached path without rehashing. Missing content is transferred sequentially and
 * verified on completion. Empty incomplete chunks fail; interrupted temporary transfers remain subject to store
 * lease cleanup.
 */
class VerifiedArtifactCache(
    private val source: BlobEndpoint,
    private val cache: FileDigestBlobStore,
) : VerifiedArtifactSource {
    /** Returns a verified local path, resuming an existing transfer only through the endpoint contract. */
    override suspend fun fetch(digest: ArtifactDigest): Path {
        if (cache.metadata(digest) is BlobResult.Success) return cache.pathFor(digest)
        BlobTransfer().copyVerified(source, cache, digest)
        return cache.pathFor(digest)
    }
}
