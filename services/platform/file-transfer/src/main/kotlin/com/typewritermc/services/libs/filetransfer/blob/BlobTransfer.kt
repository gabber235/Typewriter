package com.typewritermc.services.libs.filetransfer.blob

import com.typewritermc.services.libs.filetransfer.ByteTransferChunk
import com.typewritermc.services.libs.filetransfer.SequentialByteTransfer
import kotlinx.serialization.Serializable
import java.security.MessageDigest
import java.util.UUID

const val MAXIMUM_BLOB_SIZE: Long = 512L * 1024L * 1024L
const val DEFAULT_CHUNK_SIZE: Int = 256 * 1024
const val MAXIMUM_CHUNK_SIZE: Int = 1024 * 1024

@Serializable
enum class DigestAlgorithm {
    SHA_256,
}

/** Identifies immutable bytes through a canonical SHA 256 digest. */
@Serializable
data class ArtifactDigest(
    val algorithm: DigestAlgorithm,
    val value: String,
) {
    init {
        require(algorithm == DigestAlgorithm.SHA_256) { "Unsupported artifact digest algorithm." }
        require(value.matches(Regex("[0-9a-f]{64}"))) { "A SHA 256 digest must contain 64 lowercase hex characters." }
    }

    companion object {
        fun sha256(bytes: ByteArray): ArtifactDigest =
            ArtifactDigest(
                DigestAlgorithm.SHA_256,
                MessageDigest.getInstance("SHA-256").digest(bytes).joinToString("") { byte -> "%02x".format(byte) },
            )
    }
}

/** Identifies one resumable write session. */
@JvmInline
@Serializable
value class TransferId(
    val value: String,
) {
    companion object {
        fun create(): TransferId = TransferId(UUID.randomUUID().toString())
    }
}

/** Declares the exact digest and byte count of one immutable blob. */
@Serializable
data class BlobMetadata(
    val digest: ArtifactDigest,
    val size: Long,
)

/** Carries one bounded contiguous byte range and its completion observation. */
data class BlobChunk(
    val offset: Long,
    val bytes: ByteArray,
    val complete: Boolean,
)

/** Reports the exact offset accepted for the next write. */
data class BlobWriteSession(
    val transfer: TransferId,
    val expected: BlobMetadata,
    val offset: Long,
)

/** Represents expected storage and transfer outcomes. */
sealed interface BlobResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : BlobResult<Value>

    data object NotFound : BlobResult<Nothing>

    data class Invalid(
        val reason: String,
    ) : BlobResult<Nothing>

    data class Conflict(
        val reason: String,
    ) : BlobResult<Nothing>
}

/** Provides digest addressed reads and resumable verified writes. */
interface BlobEndpoint {
    suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata>

    suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk>

    suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession>

    suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long>

    suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata>
}

fun <Value> BlobResult<Value>.requireValue(): Value =
    when (this) {
        is BlobResult.Success -> value
        BlobResult.NotFound -> error("Blob or transfer session is absent")
        is BlobResult.Invalid -> error(reason)
        is BlobResult.Conflict -> error(reason)
    }

/** Copies immutable bytes between digest endpoints with exact progress checks. */
class BlobTransfer(
    private val bytes: SequentialByteTransfer = SequentialByteTransfer(),
) {
    suspend fun copyVerified(
        source: BlobEndpoint,
        destination: BlobEndpoint,
        digest: ArtifactDigest,
        transfer: TransferId = TransferId.create(),
    ): BlobMetadata {
        val expected = source.metadata(digest).requireValue()
        require(expected.digest == digest && expected.size in 0..MAXIMUM_BLOB_SIZE)
        when (val present = destination.metadata(digest)) {
            is BlobResult.Success -> {
                require(present.value == expected) { "Destination metadata disagrees" }
                return present.value
            }

            BlobResult.NotFound -> {}

            is BlobResult.Invalid -> {
                present.requireValue()
            }

            is BlobResult.Conflict -> {
                present.requireValue()
            }
        }
        val session = destination.beginWrite(transfer, expected).requireValue()
        require(session.transfer == transfer && session.expected == expected)
        bytes.copy(
            expected.size,
            session.offset,
            read = { offset, maximum ->
                val chunk = source.read(digest, offset, maximum).requireValue()
                ByteTransferChunk(chunk.offset, chunk.bytes, chunk.complete)
            },
            write = { offset, chunk -> destination.write(transfer, offset, chunk).requireValue() },
        )
        when (val existing = destination.metadata(digest)) {
            is BlobResult.Success -> {
                require(existing.value == expected)
                return existing.value
            }

            BlobResult.NotFound -> {}

            is BlobResult.Invalid -> {
                existing.requireValue()
            }

            is BlobResult.Conflict -> {
                existing.requireValue()
            }
        }
        return when (val completed = destination.complete(transfer)) {
            is BlobResult.Success -> completed.value.also { require(it == expected) }
            BlobResult.NotFound -> destination.metadata(digest).requireValue().also { require(it == expected) }
            is BlobResult.Invalid -> completed.requireValue()
            is BlobResult.Conflict -> completed.requireValue()
        }
    }
}
