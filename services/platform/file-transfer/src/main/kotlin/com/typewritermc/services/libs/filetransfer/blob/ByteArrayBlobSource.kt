package com.typewritermc.services.libs.filetransfer.blob

/** Exposes a defensive byte copy as one immutable read only blob. */
class ByteArrayBlobSource(
    bytes: ByteArray,
) : BlobEndpoint {
    private val bytes = bytes.copyOf()
    val digest = ArtifactDigest.sha256(this.bytes)
    private val metadata = BlobMetadata(digest, this.bytes.size.toLong())

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> =
        if (digest == this.digest) BlobResult.Success(metadata) else BlobResult.NotFound

    override suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk> {
        if (digest != this.digest) return BlobResult.NotFound
        if (offset !in 0..metadata.size || maximumBytes !in 1..MAXIMUM_CHUNK_SIZE) {
            return BlobResult.Invalid("Invalid byte range")
        }
        val end = minOf(metadata.size, offset + maximumBytes).toInt()
        return BlobResult.Success(BlobChunk(offset, bytes.copyOfRange(offset.toInt(), end), end.toLong() == metadata.size))
    }

    override suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession> = BlobResult.Invalid("Read only source")

    override suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long> = BlobResult.Invalid("Read only source")

    override suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata> = BlobResult.Invalid("Read only source")
}
