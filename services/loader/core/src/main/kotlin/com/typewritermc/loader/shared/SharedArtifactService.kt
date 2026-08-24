package com.typewritermc.loader.shared

import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.BlobChunk
import com.typewritermc.loader.api.artifact.BlobMetadata
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.BlobWriteSession
import com.typewritermc.loader.api.artifact.PublishResult
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.api.artifact.TransferId
import com.typewritermc.loader.artifact.BlobEndpoint
import com.typewritermc.loader.artifactSpan
import com.typewritermc.services.libs.telemetry.ServiceTelemetry

interface SharedArtifactTransaction {
    suspend fun find(id: SharedArtifactId): SharedArtifactDescriptor?

    suspend fun save(descriptor: SharedArtifactDescriptor)

    suspend fun nextCatalogRevision(): SharedCatalogRevision

    suspend fun enqueue(change: SharedArtifactChanged)
}

interface SharedArtifactRepository {
    suspend fun <Value> transaction(block: suspend SharedArtifactTransaction.() -> Value): Value

    suspend fun catalog(): SharedArtifactCatalog
}

class SharedArtifactService(
    private val realmId: String,
    private val blobs: BlobEndpoint,
    private val repository: SharedArtifactRepository,
    private val telemetry: ServiceTelemetry? = null,
) : SharedArtifactAccess {
    override suspend fun publish(command: PublishSharedArtifact): PublishResult =
        telemetry.artifactSpan(
            "artifact.shared.publish",
            "artifact-shared-publish-failed",
        ) { span ->
            span?.annotate {
                attribute("realm.id", realmId)
                attribute("blob.digest", command.blob.digest.value)
                attribute("blob.bytes", command.blob.size)
            }
            if (blobs.metadata(command.blob.digest) !is BlobResult.Success) {
                error("Shared artifact blob is not present in the Realm store.")
            }
            repository.transaction {
                val current = find(command.id)
                if (current != null && current.sameContentAndMetadata(command)) {
                    return@transaction PublishResult.Unchanged(current)
                }
                if (current?.revision != command.expectedRevision) return@transaction PublishResult.Conflict(current)
                val next =
                    SharedArtifactDescriptor(
                        id = command.id,
                        revision = SharedArtifactRevision((current?.revision?.value ?: 0) + 1),
                        label = command.label,
                        mediaType = command.mediaType,
                        digest = command.blob.digest,
                        size = command.blob.size,
                        metadata = command.metadata,
                        provenance = command.provenance,
                        deleted = false,
                    )
                save(next)
                val catalogRevision = nextCatalogRevision()
                enqueue(SharedArtifactChanged(realmId, next, catalogRevision))
                PublishResult.Published(next, catalogRevision)
            }
        }

    override suspend fun delete(
        id: SharedArtifactId,
        expectedRevision: SharedArtifactRevision,
        provenance: SharedArtifactProvenance,
    ): PublishResult =
        repository.transaction {
            val current = find(id)
            if (current?.deleted == true && current.revision.value == expectedRevision.value + 1) {
                return@transaction PublishResult.Unchanged(current)
            }
            if (current?.revision != expectedRevision) return@transaction PublishResult.Conflict(current)
            if (current.deleted) return@transaction PublishResult.Unchanged(current)
            val tombstone =
                current.copy(
                    revision = SharedArtifactRevision(current.revision.value + 1),
                    digest = null,
                    size = null,
                    provenance = provenance,
                    deleted = true,
                )
            save(tombstone)
            val catalogRevision = nextCatalogRevision()
            enqueue(SharedArtifactChanged(realmId, tombstone, catalogRevision))
            PublishResult.Published(tombstone, catalogRevision)
        }

    override suspend fun catalog(): SharedArtifactCatalog = repository.catalog()

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> = blobs.metadata(digest)

    override suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk> = blobs.read(digest, offset, maximumBytes)

    override suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession> = blobs.beginWrite(transfer, expected)

    override suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long> = blobs.write(transfer, offset, bytes)

    override suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata> = blobs.complete(transfer)
}

private fun SharedArtifactDescriptor.sameContentAndMetadata(command: PublishSharedArtifact): Boolean =
    !deleted &&
        label == command.label &&
        mediaType == command.mediaType &&
        digest == command.blob.digest &&
        size == command.blob.size &&
        metadata == command.metadata
