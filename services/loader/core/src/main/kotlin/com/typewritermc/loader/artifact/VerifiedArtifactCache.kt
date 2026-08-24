package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.rollout.VerifiedArtifactSource
import java.nio.file.Path

class VerifiedArtifactCache(
    private val source: BlobEndpoint,
    private val cache: FileDigestBlobStore,
) : VerifiedArtifactSource {
    override suspend fun fetch(digest: ArtifactDigest): Path {
        if (cache.metadata(digest) is BlobResult.Success) return cache.pathFor(digest)
        val metadata = source.metadata(digest).requireSuccess()
        val transfer = TransferId.create()
        var offset = cache.beginWrite(transfer, metadata).requireSuccess().offset
        while (offset < metadata.size) {
            val chunk = source.read(digest, offset, DEFAULT_CHUNK_SIZE).requireSuccess()
            require(chunk.bytes.isNotEmpty()) { "Artifact source returned an empty incomplete chunk." }
            offset = cache.write(transfer, offset, chunk.bytes).requireSuccess()
        }
        cache.complete(transfer).requireSuccess()
        return cache.pathFor(digest)
    }
}

private fun <Value> BlobResult<Value>.requireSuccess(): Value =
    when (this) {
        is BlobResult.Success -> value
        BlobResult.NotFound -> error("Artifact blob was not found.")
        is BlobResult.Invalid -> error(reason)
        is BlobResult.Conflict -> error(reason)
    }
