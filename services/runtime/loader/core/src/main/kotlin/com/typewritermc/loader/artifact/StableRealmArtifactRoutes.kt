package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.artifact.ProducerMetadata
import com.typewritermc.loader.api.artifact.PublishResult
import com.typewritermc.loader.api.artifact.PublishSharedArtifact
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.api.artifact.SharedArtifactDescriptor
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.api.artifact.SharedArtifactRevision
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.sharedBlobFetch
import com.typewritermc.protocol.transport.generated.sharedBlobMetadata
import com.typewritermc.protocol.transport.generated.sharedBlobStore
import com.typewritermc.protocol.transport.generated.sharedCatalogFetch
import com.typewritermc.protocol.transport.generated.sharedPublish
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import com.typewritermc.services.libs.filetransfer.blob.MAXIMUM_TRANSFERRED_BLOB_SIZE
import com.typewritermc.services.libs.filetransfer.blob.StoreResult
import okio.ByteString.Companion.toByteString
import skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse
import skirout.service.v1.artifact.FetchArtifactBlobResponse
import skirout.service.v1.artifact.FetchSharedArtifactCatalogResponse
import skirout.service.v1.artifact.ProducerMetadataEntry
import skirout.service.v1.artifact.PublishSharedArtifactRequest
import skirout.service.v1.artifact.PublishSharedArtifactResponse
import skirout.service.v1.artifact.StoreArtifactBlobResponse
import skirout.service.v1.artifact.ArtifactDigest as SkirArtifactDigest
import skirout.service.v1.artifact.BlobMetadata as SkirBlobMetadata
import skirout.service.v1.artifact.DigestAlgorithm as SkirDigestAlgorithm
import skirout.service.v1.artifact.ProducerMetadata as SkirProducerMetadata
import skirout.service.v1.artifact.SharedArtifactDescriptor as SkirSharedArtifactDescriptor
import skirout.service.v1.artifact.SharedArtifactProvenance as SkirSharedArtifactProvenance

/**
 * Registers loader owned shared artifact and blob routes at the logical Realm address.
 *
 * Storage survives replacement of the hosted Realm runtime. Wire conversions validate domain values, while the
 * enclosing router owns subscriptions and unexpected handler failure responses.
 */
class StableRealmArtifactRoutes(
    private val artifacts: SharedArtifactAccess,
) {
    fun register(
        builder: CommunicatorRoutesBuilder,
        address: RealmRouteScope,
    ) = with(builder) {
        unaryAt(address.sharedCatalogFetch, address) {
            val catalog = artifacts.catalog()
            FetchSharedArtifactCatalogResponse.createSuccess(
                revision = catalog.revision.value,
                artifacts = catalog.artifacts.map(SharedArtifactDescriptor::toSkir),
            )
        }
        unaryAt(address.sharedPublish, address) { call -> publish(call.request) }
        unaryAt(address.sharedBlobMetadata, address) { call ->
            when (val result = artifacts.metadata(call.request.digest.toApi())) {
                is BlobResult.Success -> FetchArtifactBlobMetadataResponse.SuccessWrapper(result.value.toSkir())
                BlobResult.NotFound -> FetchArtifactBlobMetadataResponse.createNotFoundError()
                is BlobResult.Invalid -> FetchArtifactBlobMetadataResponse.createInvalidError(reason = result.reason)
            }
        }
        unaryAt(address.sharedBlobFetch, address, parallelism = BLOB_ROUTE_PARALLELISM) { call -> fetch(call.request.digest.toApi()) }
        unaryAt(address.sharedBlobStore, address, parallelism = BLOB_ROUTE_PARALLELISM) { call ->
            when (val result = artifacts.store(call.request.expected.toApi(), call.request.content.toByteArray())) {
                is StoreResult.Stored -> StoreArtifactBlobResponse.SuccessWrapper(result.metadata.toSkir())
                is StoreResult.Invalid -> StoreArtifactBlobResponse.createInvalidError(reason = result.reason)
            }
        }
    }

    /** Answers a blob fetch; the stored size decides first, so a blob too large to transfer is never read or hashed. */
    private suspend fun fetch(digest: ArtifactDigest): FetchArtifactBlobResponse {
        val stored = artifacts.metadata(digest)
        if (stored is BlobResult.Success && stored.value.size > MAXIMUM_TRANSFERRED_BLOB_SIZE) {
            return FetchArtifactBlobResponse.createInvalidError(
                reason = "Blob of ${stored.value.size} bytes exceeds the $MAXIMUM_TRANSFERRED_BLOB_SIZE byte transfer ceiling.",
            )
        }
        return when (val result = artifacts.fetch(digest)) {
            is BlobResult.Success -> FetchArtifactBlobResponse.createSuccess(content = result.value.toByteString())
            BlobResult.NotFound -> FetchArtifactBlobResponse.createNotFoundError()
            is BlobResult.Invalid -> FetchArtifactBlobResponse.createInvalidError(reason = result.reason)
        }
    }

    private suspend fun publish(request: PublishSharedArtifactRequest): PublishSharedArtifactResponse {
        val provenance = request.provenance.toApi()
        val id = SharedArtifactId(request.id)
        val result =
            if (request.deleted) {
                artifacts.delete(id, SharedArtifactRevision(requireNotNull(request.expectedRevision)), provenance)
            } else {
                artifacts.publish(
                    PublishSharedArtifact(
                        id,
                        request.expectedRevision?.let(::SharedArtifactRevision),
                        request.label,
                        request.mediaType,
                        BlobMetadata(requireNotNull(request.digest).toApi(), requireNotNull(request.size)),
                        request.metadata?.toApi(),
                        provenance,
                    ),
                )
            }
        return when (result) {
            is PublishResult.Published -> PublishSharedArtifactResponse.PublishedWrapper(result.descriptor.toSkir())
            is PublishResult.Unchanged -> PublishSharedArtifactResponse.UnchangedWrapper(result.descriptor.toSkir())
            is PublishResult.Conflict -> PublishSharedArtifactResponse.ConflictErrorWrapper(result.current?.toSkir())
        }
    }
}

/**
 * Workers of each blob route. A blob in flight sits in memory several times over (file bytes, wire encoding and
 * frames), so two concurrent transfers bound a host at about 1 GiB for 128 MiB blobs; larger files stay local imports.
 */
private const val BLOB_ROUTE_PARALLELISM = 2
