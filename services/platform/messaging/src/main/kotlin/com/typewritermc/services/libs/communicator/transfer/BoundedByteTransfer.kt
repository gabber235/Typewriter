package com.typewritermc.services.libs.communicator.transfer

import com.typewritermc.services.libs.communicator.transport.Payload
import java.security.MessageDigest
import java.util.UUID

data class BoundedTransferLimits(
    val chunkSize: Int = DEFAULT_BOUNDED_TRANSFER_CHUNK_SIZE,
    val maxChunks: Int = DEFAULT_BOUNDED_TRANSFER_MAX_CHUNKS,
) {
    init {
        require(chunkSize > 0) { "Transfer chunk size must be positive." }
        require(maxChunks > 0) { "Transfer chunk count must be positive." }
    }

    val maxEncodedSize: Long = chunkSize.toLong() * maxChunks
}

data class BoundedTransferChunk(
    val transferId: String,
    val index: Int,
    val chunkCount: Int,
    val encodedSize: Long,
    val sha256: String,
    val payload: Payload,
)

sealed interface BoundedTransferPlan {
    data class Ready(
        val chunks: List<BoundedTransferChunk>,
    ) : BoundedTransferPlan

    data class Unavailable(
        val encodedSize: Long,
        val maxEncodedSize: Long,
    ) : BoundedTransferPlan
}

class BoundedByteTransferEncoder(
    private val limits: BoundedTransferLimits = BoundedTransferLimits(),
    private val nextTransferId: () -> String = { UUID.randomUUID().toString() },
) {
    fun encode(bytes: ByteArray): BoundedTransferPlan {
        if (bytes.size.toLong() > limits.maxEncodedSize) {
            return BoundedTransferPlan.Unavailable(bytes.size.toLong(), limits.maxEncodedSize)
        }
        val payloads =
            if (bytes.isEmpty()) {
                listOf(byteArrayOf())
            } else {
                (bytes.indices step limits.chunkSize).map { start ->
                    bytes.copyOfRange(start, minOf(start + limits.chunkSize, bytes.size))
                }
            }
        val transferId = nextTransferId()
        val digest = MessageDigest.getInstance("SHA-256").digest(bytes).toHex()
        return BoundedTransferPlan.Ready(
            payloads.mapIndexed { index, payload ->
                BoundedTransferChunk(
                    transferId = transferId,
                    index = index,
                    chunkCount = payloads.size,
                    encodedSize = bytes.size.toLong(),
                    sha256 = digest,
                    payload = Payload.copyOf(payload),
                )
            },
        )
    }
}

const val DEFAULT_BOUNDED_TRANSFER_CHUNK_SIZE = 512 * 1024
const val DEFAULT_BOUNDED_TRANSFER_MAX_CHUNKS = 64

private fun ByteArray.toHex(): String = joinToString("") { byte -> "%02x".format(byte) }
