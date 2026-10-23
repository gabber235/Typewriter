package com.typewritermc.services.libs.filetransfer.blob

import kotlinx.serialization.Serializable
import java.security.MessageDigest

/** The largest blob a host stores, including local imports that never cross the transport. */
const val MAXIMUM_BLOB_SIZE: Long = 512L * 1024L * 1024L

/** The largest blob that crosses the transport; equals max_bytes of the blob routes in transport-routes.yaml. */
const val MAXIMUM_TRANSFERRED_BLOB_SIZE: Long = 128L * 1024L * 1024L

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
                MessageDigest.getInstance("SHA-256").digest(bytes).toHexString(),
            )
    }
}

/** Declares the exact digest and byte count of one immutable blob. */
@Serializable
data class BlobMetadata(
    val digest: ArtifactDigest,
    val size: Long,
)

/** Represents expected storage outcomes; infrastructure failures still throw. */
sealed interface BlobResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : BlobResult<Value>

    data object NotFound : BlobResult<Nothing>

    data class Invalid(
        val reason: String,
    ) : BlobResult<Nothing>
}

/** A store either keeps verified content or rejects it; there is nothing to be absent. */
sealed interface StoreResult {
    data class Stored(
        val metadata: BlobMetadata,
    ) : StoreResult

    data class Invalid(
        val reason: String,
    ) : StoreResult
}

/**
 * Stores immutable artifact bytes by digest, independently from the deployment metadata that references them.
 *
 * Content moves whole: the transport splits large payloads in both directions. [fetch] returns content that
 * hashes to the digest. [store] verifies content against [BlobMetadata] before it becomes visible, and storing
 * content that is already present succeeds without change, so callers may retry a store whose reply was lost.
 */
interface BlobEndpoint {
    suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata>

    suspend fun fetch(digest: ArtifactDigest): BlobResult<ByteArray>

    suspend fun store(
        expected: BlobMetadata,
        content: ByteArray,
    ): StoreResult
}

fun <Value> BlobResult<Value>.requireValue(): Value =
    when (this) {
        is BlobResult.Success -> value
        BlobResult.NotFound -> error("Blob is absent")
        is BlobResult.Invalid -> error(reason)
    }

/** The stored metadata, or a failure carrying the store's reason. */
fun StoreResult.requireStored(): BlobMetadata =
    when (this) {
        is StoreResult.Stored -> metadata
        is StoreResult.Invalid -> error(reason)
    }
