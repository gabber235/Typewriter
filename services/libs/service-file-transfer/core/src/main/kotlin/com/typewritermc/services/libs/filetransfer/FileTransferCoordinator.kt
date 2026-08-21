package com.typewritermc.services.libs.filetransfer

/**
 * Copies one immutable file revision between arbitrary endpoints using bounded resumable chunks.
 *
 * A transfer resumes from the destination accepted offset. The coordinator validates source and destination progress but
 * delegates final size and digest verification to [FileTransferEndpoint.complete]. Cancellation propagates to the caller
 * and does not implicitly cancel destination state, allowing a later retry to resume.
 */
class FileTransferCoordinator(
    val chunkSize: Int = DEFAULT_CHUNK_SIZE,
) {
    init {
        require(chunkSize in 1..MAXIMUM_CHUNK_SIZE) { "Chunk size is outside the supported range" }
    }

    suspend fun upload(
        transferId: TransferId,
        key: FileKey,
        source: FileTransferEndpoint,
        destination: FileTransferEndpoint,
    ): FileTransferResult<FileMetadata> = transfer(transferId, key, source, destination)

    suspend fun download(
        transferId: TransferId,
        key: FileKey,
        source: FileTransferEndpoint,
        destination: FileTransferEndpoint,
    ): FileTransferResult<FileMetadata> = transfer(transferId, key, source, destination)

    suspend fun transfer(
        transferId: TransferId,
        key: FileKey,
        source: FileTransferEndpoint,
        destination: FileTransferEndpoint,
    ): FileTransferResult<FileMetadata> {
        val metadata = source.metadata(key).valueOrReturn { return it }
        val session = destination.beginWrite(transferId, metadata).valueOrReturn { return it }
        if (session.acceptedOffset !in 0..metadata.size) {
            return FileTransferResult.Failure(
                FileTransferError.InvalidOffset(metadata.size, session.acceptedOffset),
            )
        }

        var offset = session.acceptedOffset
        while (offset < metadata.size) {
            val maximumBytes = minOf(chunkSize.toLong(), metadata.size - offset).toInt()
            val chunk = source.read(key, offset, maximumBytes).valueOrReturn { return it }
            if (chunk.offset != offset) {
                return FileTransferResult.Failure(FileTransferError.InvalidOffset(offset, chunk.offset))
            }
            if (chunk.bytes.isEmpty() || chunk.bytes.size > maximumBytes) {
                return FileTransferResult.Failure(FileTransferError.InvalidChunk("Source returned an invalid chunk size"))
            }
            val nextOffset = destination.write(transferId, offset, chunk.bytes).valueOrReturn { return it }
            val expectedOffset = offset + chunk.bytes.size
            if (nextOffset != expectedOffset) {
                return FileTransferResult.Failure(FileTransferError.InvalidOffset(expectedOffset, nextOffset))
            }
            offset = nextOffset
        }
        return destination.complete(transferId)
    }

    private inline fun <Value> FileTransferResult<Value>.valueOrReturn(failure: (FileTransferResult.Failure) -> Nothing): Value =
        when (this) {
            is FileTransferResult.Success -> value
            is FileTransferResult.Failure -> failure(this)
        }

    companion object {
        const val DEFAULT_CHUNK_SIZE = 256 * 1024
        const val MAXIMUM_CHUNK_SIZE = 1024 * 1024
    }
}
