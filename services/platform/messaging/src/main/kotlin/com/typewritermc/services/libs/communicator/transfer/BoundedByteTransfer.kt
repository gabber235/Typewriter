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

/** Assembles one bounded response and verifies its declared size and digest. */
class BoundedByteTransferAssembler(
    private val transferId: String,
    private val limits: BoundedTransferLimits = BoundedTransferLimits(),
) {
    private var metadata: BoundedTransferChunk? = null
    private val parts = mutableMapOf<Int, ByteArray>()

    fun accept(chunk: BoundedTransferChunk): ByteArray? {
        require(chunk.transferId == transferId) { "Transfer identity does not match request" }
        require(chunk.chunkCount in 1..limits.maxChunks && chunk.index in 0 until chunk.chunkCount)
        require(chunk.encodedSize in 0..minOf(limits.maxEncodedSize, Int.MAX_VALUE.toLong()))
        val bytes = chunk.payload.toByteArray()
        require(bytes.size <= limits.chunkSize)
        val first = metadata
        require(
            first == null ||
                (first.chunkCount == chunk.chunkCount && first.encodedSize == chunk.encodedSize && first.sha256 == chunk.sha256),
        ) {
            "Transfer metadata changed during assembly"
        }
        metadata = first ?: chunk.copy(payload = Payload.copyOf(byteArrayOf()))
        val prior = parts[chunk.index]
        require(prior == null || prior.contentEquals(bytes)) { "Transfer chunk changed during assembly" }
        parts[chunk.index] = bytes
        require(parts.values.sumOf { it.size.toLong() } <= chunk.encodedSize)
        if (parts.size != chunk.chunkCount) return null
        val complete = java.io.ByteArrayOutputStream(chunk.encodedSize.toInt())
        repeat(chunk.chunkCount) { complete.write(parts.getValue(it)) }
        val result = complete.toByteArray()
        require(result.size.toLong() == chunk.encodedSize)
        require(MessageDigest.getInstance("SHA-256").digest(result).toHex() == chunk.sha256) { "Transfer digest verification failed" }
        return result
    }
}

const val DEFAULT_BOUNDED_TRANSFER_CHUNK_SIZE = 512 * 1024
const val DEFAULT_BOUNDED_TRANSFER_MAX_CHUNKS = 64

private fun ByteArray.toHex(): String = joinToString("") { byte -> "%02x".format(byte) }
