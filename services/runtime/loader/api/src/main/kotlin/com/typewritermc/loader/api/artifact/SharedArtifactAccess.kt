package com.typewritermc.loader.api.artifact

import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import kotlinx.serialization.Serializable
import java.util.UUID

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
        val serviceId: String,
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
