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

@Serializable
data class BlobMetadata(
    val digest: ArtifactDigest,
    val size: Long,
)

data class BlobChunk(
    val offset: Long,
    val bytes: ByteArray,
    val complete: Boolean,
)

data class BlobWriteSession(
    val transfer: TransferId,
    val expected: BlobMetadata,
    val offset: Long,
)

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

data class PublishSharedArtifact(
    val id: SharedArtifactId,
    val expectedRevision: SharedArtifactRevision?,
    val label: String,
    val mediaType: String,
    val blob: BlobMetadata,
    val metadata: ProducerMetadata?,
    val provenance: SharedArtifactProvenance,
)

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

@Serializable
data class SharedArtifactChanged(
    val realmId: String,
    val artifact: SharedArtifactDescriptor,
    val catalogRevision: SharedCatalogRevision,
)

@Serializable
data class SharedArtifactCatalog(
    val revision: SharedCatalogRevision,
    val artifacts: List<SharedArtifactDescriptor>,
)

interface SharedArtifactAccess : BlobEndpoint {
    suspend fun publish(command: PublishSharedArtifact): PublishResult

    suspend fun delete(
        id: SharedArtifactId,
        expectedRevision: SharedArtifactRevision,
        provenance: SharedArtifactProvenance,
    ): PublishResult

    suspend fun catalog(): SharedArtifactCatalog
}
