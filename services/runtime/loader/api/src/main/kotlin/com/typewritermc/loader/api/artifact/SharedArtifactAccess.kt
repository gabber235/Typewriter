package com.typewritermc.loader.api.artifact

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

/**
 * Addresses immutable artifact bytes by SHA256.
 *
 * Only 64 lowercase hexadecimal characters and SHA_256 are accepted. [sha256] computes this identity from bytes;
 * coordinate or label changes do not change content identity.
 */
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

@JvmInline
@Serializable
value class TransferId(
    val value: String,
) {
    companion object {
        fun create(): TransferId = TransferId(UUID.randomUUID().toString())
    }
}

/**
 * Declares expected immutable bytes by digest and size in bytes.
 *
 * This data class does not validate size. Endpoint implementations enforce transfer limits before accepting
 * writes.
 */
@Serializable
data class BlobMetadata(
    val digest: ArtifactDigest,
    val size: Long,
)

/**
 * Returns a byte range and whether it reaches the end of the blob.
 *
 * Offsets count bytes from the start. Consumers should verify continuity and completion against metadata; the byte
 * array is mutable and must not be modified while another operation uses it.
 */
data class BlobChunk(
    val offset: Long,
    val bytes: ByteArray,
    val complete: Boolean,
)

/**
 * Reports the persisted byte offset from which a transfer can continue.
 *
 * A full offset may indicate that the final blob already exists. Check endpoint metadata before assuming there is
 * a temporary session to complete.
 */
data class BlobWriteSession(
    val transfer: TransferId,
    val expected: BlobMetadata,
    val offset: Long,
)

/**
 * Represents expected blob outcomes without exposing storage paths.
 *
 * NotFound covers absent blobs or sessions, Invalid covers rejected input, and Conflict covers incompatible
 * transfer state. Unexpected storage and transport failures may still throw.
 */
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

/**
 * Transfers immutable digest addressed bytes in bounded contiguous chunks.
 *
 * Use metadata and read for retrieval. Writers begin or resume a session, write at its accepted offset, and
 * complete to verify and publish content. The endpoint owns temporary state; this contract exposes no cancellation
 * operation.
 */
interface BlobEndpoint {
    suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata>

    suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk>

    /**
     * Begins or resumes a transfer for exact expected content.
     *
     * Reuse a transfer id only for the same metadata. Inspect the returned offset, which may already equal the
     * full size when content is present.
     */
    suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession>

    /**
     * Appends bytes at the endpoint accepted offset and returns the next offset.
     *
     * Call sequentially per transfer. A mismatched offset is a conflict rather than permission to overwrite
     * already accepted bytes.
     */
    suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long>

    /**
     * Verifies the completed transfer and makes its immutable blob available.
     *
     * The temporary session may be removed on success. Repeating completion is not guaranteed to succeed; check
     * metadata for the final digest when recovering from an uncertain response.
     */
    suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata>
}

/**
 * Identifies a logical shared artifact across revisions using a UUID version 7 value.
 *
 * Blob digests identify bytes, while this id remains stable when content or metadata changes.
 */
@JvmInline
@Serializable
value class SharedArtifactId(
    val value: String,
) {
    init {
        require(UUID.fromString(value).version() == 7) { "Shared artifact ids must use UUID version 7." }
    }
}

@JvmInline
@Serializable
value class SharedArtifactRevision(
    val value: Long,
) {
    init {
        require(value >= 1) { "Shared artifact revision must be positive." }
    }
}

@JvmInline
@Serializable
value class SharedCatalogRevision(
    val value: Long,
) {
    init {
        require(value >= 0) { "Shared catalog revision must not be negative." }
    }
}

@Serializable
data class ProducerMetadata(
    val values: Map<String, String>,
)

@Serializable
sealed interface SharedArtifactProvenance {
    @Serializable
    data class PanelUpload(
        val userId: String,
    ) : SharedArtifactProvenance

    @Serializable
    data class HostedRuntime(
        val hostId: String,
        val runtimeId: String,
    ) : SharedArtifactProvenance

    @Serializable
    data class LocalInbox(
        val relativePath: String,
    ) : SharedArtifactProvenance
}

/**
 * Publishes the current revision of a shared artifact or its tombstone.
 *
 * Live descriptors require digest and size. Deleted descriptors must omit both so consumers do not treat a
 * tombstone as downloadable content. Provenance records the producer of this revision.
 */
@Serializable
data class SharedArtifactDescriptor(
    val id: SharedArtifactId,
    val revision: SharedArtifactRevision,
    val label: String,
    val mediaType: String,
    val digest: ArtifactDigest?,
    val size: Long?,
    val metadata: ProducerMetadata?,
    val provenance: SharedArtifactProvenance,
    val deleted: Boolean,
) {
    init {
        require(label.isNotBlank()) { "Shared artifact label must not be blank." }
        require(mediaType.isNotBlank()) { "Shared artifact media type must not be blank." }
        require(deleted || (digest != null && size != null)) { "A live shared artifact must reference blob content." }
        require(!deleted || (digest == null && size == null)) { "A deleted shared artifact cannot reference blob content." }
    }
}

/**
 * Requests publication of an already uploaded blob with optimistic revision checking.
 *
 * A null expected revision means creation. The service may return Unchanged for identical live content and
 * metadata even when the expected revision is stale; provenance alone does not force a revision.
 */
data class PublishSharedArtifact(
    val id: SharedArtifactId,
    val expectedRevision: SharedArtifactRevision?,
    val label: String,
    val mediaType: String,
    val blob: BlobMetadata,
    val metadata: ProducerMetadata?,
    val provenance: SharedArtifactProvenance,
)

/**
 * Distinguishes a new revision, an idempotent unchanged result, and an optimistic concurrency conflict.
 *
 * Published carries the new catalog revision. Conflict exposes the current descriptor when one exists so callers
 * can refresh before retrying.
 */
sealed interface PublishResult {
    data class Published(
        val descriptor: SharedArtifactDescriptor,
        val catalogRevision: SharedCatalogRevision,
    ) : PublishResult

    data class Unchanged(
        val descriptor: SharedArtifactDescriptor,
    ) : PublishResult

    data class Conflict(
        val current: SharedArtifactDescriptor?,
    ) : PublishResult
}

/**
 * Carries one committed shared artifact revision for catalog invalidation.
 *
 * Publication is separate from the repository commit and may be retried. Consumers should tolerate duplicate
 * delivery and use catalog revisions to detect stale state.
 */
@Serializable
data class SharedArtifactChanged(
    val realmId: String,
    val artifact: SharedArtifactDescriptor,
    val catalogRevision: SharedCatalogRevision,
)

/**
 * Returns the shared artifact descriptors at a catalog revision, including tombstones.
 *
 * The catalog revision orders catalog changes; each artifact also has its own revision.
 */
@Serializable
data class SharedArtifactCatalog(
    val revision: SharedCatalogRevision,
    val artifacts: List<SharedArtifactDescriptor>,
)

/**
 * Combines immutable blob transfer with revisioned logical artifact publication for a Realm.
 *
 * Upload and complete bytes before publishing their descriptor. Deletion creates a tombstone rather than
 * immediately removing blob bytes; retention and garbage collection belong to the host.
 */
interface SharedArtifactAccess : BlobEndpoint {
    suspend fun publish(command: PublishSharedArtifact): PublishResult

    suspend fun delete(
        id: SharedArtifactId,
        expectedRevision: SharedArtifactRevision,
        provenance: SharedArtifactProvenance,
    ): PublishResult

    suspend fun catalog(): SharedArtifactCatalog
}
