package com.typewritermc.services.libs.filetransfer.blob

import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.atomic.AtomicInteger

/**
 * [BlobEndpoint] holding blobs in memory for tests.
 *
 * [store] verifies size and digest like a real endpoint. [put], [replace] and [remove] change the
 * content directly, so a test can seed blobs or simulate lost and damaged content.
 */
class InMemoryBlobEndpoint : BlobEndpoint {
    private val blobs = ConcurrentHashMap<ArtifactDigest, ByteArray>()
    private val storeCount = AtomicInteger()

    /** Every store that reached this endpoint, so tests can tell whether unchanged content travelled again. */
    val stores: Int get() = storeCount.get()

    /** Seeds [content] under its own digest without counting a store. */
    fun put(content: ByteArray): BlobMetadata {
        val metadata = BlobMetadata(ArtifactDigest.sha256(content), content.size.toLong())
        blobs[metadata.digest] = content.copyOf()
        return metadata
    }

    /** Puts [content] under [digest] without verification, as damaged storage would. */
    fun replace(
        digest: ArtifactDigest,
        content: ByteArray,
    ) {
        blobs[digest] = content.copyOf()
    }

    /** Returns the stored bytes of [digest]; fails when the blob is absent. */
    fun content(digest: ArtifactDigest): ByteArray = checkNotNull(blobs[digest]) { "No blob $digest" }.copyOf()

    fun remove(digest: ArtifactDigest) {
        blobs.remove(digest)
    }

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> =
        blobs[digest]?.let { BlobResult.Success(BlobMetadata(digest, it.size.toLong())) } ?: BlobResult.NotFound

    override suspend fun fetch(digest: ArtifactDigest): BlobResult<ByteArray> =
        blobs[digest]?.let { BlobResult.Success(it.copyOf()) } ?: BlobResult.NotFound

    override suspend fun store(
        expected: BlobMetadata,
        content: ByteArray,
    ): StoreResult {
        storeCount.incrementAndGet()
        if (content.size.toLong() != expected.size) return StoreResult.Invalid("Unexpected blob size.")
        if (ArtifactDigest.sha256(content) != expected.digest) return StoreResult.Invalid("Unexpected blob digest.")
        blobs[expected.digest] = content.copyOf()
        return StoreResult.Stored(expected)
    }
}
