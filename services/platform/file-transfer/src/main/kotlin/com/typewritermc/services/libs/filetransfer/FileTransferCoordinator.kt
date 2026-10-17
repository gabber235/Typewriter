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
    private val bytes = SequentialByteTransfer(chunkSize)

    init {
        require(chunkSize in 1..MAXIMUM_CHUNK_SIZE) { "Chunk size is outside the supported range" }
    }

    /**
     * Names a transfer from the publishing side to the receiving side.
     *
     * The endpoint roles are semantic only. This delegates to [transfer], so resume, progress checks, and completion
     * verification are identical to [download].
     */
    suspend fun upload(
        transferId: TransferId,
        key: FileKey,
        source: FileTransferEndpoint,
        destination: FileTransferEndpoint,
    ): FileTransferResult<FileMetadata> = transfer(transferId, key, source, destination)

    /**
     * Names a transfer from the serving side to the receiving side.
     *
     * The endpoint roles are semantic only. This delegates to [transfer], so resume, progress checks, and completion
     * verification are identical to [upload].
     */
    suspend fun download(
        transferId: TransferId,
        key: FileKey,
        source: FileTransferEndpoint,
        destination: FileTransferEndpoint,
    ): FileTransferResult<FileMetadata> = transfer(transferId, key, source, destination)

    /**
     * Copies the selected revision from source to destination using its accepted resume offset.
     *
     * Each returned chunk and destination offset is checked for exact forward progress. Completion owns final
     * digest verification. Failure or cancellation leaves destination state available for resumption.
     */
    suspend fun transfer(
        transferId: TransferId,
        key: FileKey,
        source: FileTransferEndpoint,
        destination: FileTransferEndpoint,
    ): FileTransferResult<FileMetadata> =
        try {
            val metadata = source.metadata(key).requireTransferValue()
            val session = destination.beginWrite(transferId, metadata).requireTransferValue()
            bytes.copy(
                metadata.size,
                session.acceptedOffset,
                read = { offset, maximum ->
                    val chunk = source.read(key, offset, maximum).requireTransferValue()
                    ByteTransferChunk(chunk.offset, chunk.bytes, chunk.offset + chunk.bytes.size == metadata.size)
                },
                write = { offset, chunk -> destination.write(transferId, offset, chunk).requireTransferValue() },
            )
            destination.complete(transferId)
        } catch (failure: EndpointFailure) {
            failure.result
        } catch (failure: TransferProtocolException) {
            FileTransferResult.Failure(FileTransferError.InvalidChunk(requireNotNull(failure.message)))
        }

    companion object {
        const val DEFAULT_CHUNK_SIZE = 256 * 1024
        const val MAXIMUM_CHUNK_SIZE = 1024 * 1024
    }
}

private class EndpointFailure(
    val result: FileTransferResult.Failure,
) : RuntimeException(null, null, false, false)

private fun <Value> FileTransferResult<Value>.requireTransferValue(): Value =
    when (this) {
        is FileTransferResult.Success -> value
        is FileTransferResult.Failure -> throw EndpointFailure(this)
    }
