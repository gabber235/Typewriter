package com.typewritermc.services.libs.filetransfer

data class ByteTransferChunk(
    val offset: Long,
    val bytes: ByteArray,
    val complete: Boolean,
)

class TransferProtocolException(
    message: String,
) : IllegalArgumentException(message)

/** Copies bounded contiguous bytes while enforcing exact progress. */
class SequentialByteTransfer(
    private val chunkSize: Int = FileTransferCoordinator.DEFAULT_CHUNK_SIZE,
) {
    init {
        require(chunkSize in 1..FileTransferCoordinator.MAXIMUM_CHUNK_SIZE)
    }

    suspend fun copy(
        size: Long,
        acceptedOffset: Long,
        read: suspend (offset: Long, maximumBytes: Int) -> ByteTransferChunk,
        write: suspend (offset: Long, bytes: ByteArray) -> Long,
    ) {
        if (size < 0 || acceptedOffset !in 0..size) {
            throw TransferProtocolException("Invalid transfer size or offset")
        }
        var offset = acceptedOffset
        while (offset < size) {
            val maximum = minOf(chunkSize.toLong(), size - offset).toInt()
            val chunk = read(offset, maximum)
            if (chunk.offset != offset) throw TransferProtocolException("Source offset changed")
            if (chunk.bytes.isEmpty() || chunk.bytes.size > maximum) {
                throw TransferProtocolException("Invalid chunk size")
            }
            val next = offset + chunk.bytes.size
            if (chunk.complete != (next == size)) {
                throw TransferProtocolException("Source completion disagrees with metadata")
            }
            val accepted = write(offset, chunk.bytes)
            if (accepted != next) throw TransferProtocolException("Destination accepted a different offset")
            offset = next
        }
    }
}
