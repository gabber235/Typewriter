package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.artifact.ProducerMetadata
import com.typewritermc.loader.api.artifact.PublishResult
import com.typewritermc.loader.api.artifact.PublishSharedArtifact
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.api.artifact.SharedArtifactCatalog
import com.typewritermc.loader.api.artifact.SharedArtifactDescriptor
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.api.artifact.SharedArtifactRevision
import com.typewritermc.loader.api.artifact.SharedCatalogRevision
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.sharedCatalogFetch
import com.typewritermc.protocol.transport.generated.sharedPublish
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import com.typewritermc.services.libs.filetransfer.blob.StoreResult
import com.typewritermc.services.libs.utils.rethrowExceptional
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import skirout.service.v1.artifact.FetchSharedArtifactCatalog
import skirout.service.v1.artifact.FetchSharedArtifactCatalogRequest
import skirout.service.v1.artifact.FetchSharedArtifactCatalogResponse
import skirout.service.v1.artifact.ProducerMetadataEntry
import skirout.service.v1.artifact.PublishSharedArtifactRequest
import skirout.service.v1.artifact.PublishSharedArtifactResponse
import skirout.service.v1.artifact.ArtifactDigest as SkirArtifactDigest
import skirout.service.v1.artifact.DigestAlgorithm as SkirDigestAlgorithm
import skirout.service.v1.artifact.ProducerMetadata as SkirProducerMetadata
import skirout.service.v1.artifact.PublishSharedArtifact as PublishSharedArtifactMethod
import skirout.service.v1.artifact.SharedArtifactDescriptor as SkirSharedArtifactDescriptor
import skirout.service.v1.artifact.SharedArtifactProvenance as SkirSharedArtifactProvenance

/**
 * Maintains shared artifact access across messaging session replacement.
 *
 * Requests wait for a nonnull session. Communication failure waits for a different session id before retrying,
 * without a local timeout. Blob calls move whole content, so a retry repeats the call: fetch is a pure read and
 * store is idempotent by digest. Bound operations with caller cancellation or a suitable timeout.
 */
class ReconnectingSharedArtifactAccess(
    private val realmId: String,
    private val sessions: StateFlow<HostedMessagingSession?>,
) : SharedArtifactAccess {
    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> = withSessionRetry { endpoint(it).metadata(digest) }

    override suspend fun fetch(digest: ArtifactDigest): BlobResult<ByteArray> = withSessionRetry { endpoint(it).fetch(digest) }

    override suspend fun store(
        expected: BlobMetadata,
        content: ByteArray,
    ): StoreResult = withSessionRetry { endpoint(it).store(expected, content) }

    override suspend fun publish(command: PublishSharedArtifact): PublishResult = withSessionRetry { metadataClient(it).publish(command) }

    override suspend fun delete(
        id: SharedArtifactId,
        expectedRevision: SharedArtifactRevision,
        provenance: SharedArtifactProvenance,
    ): PublishResult = withSessionRetry { metadataClient(it).delete(id, expectedRevision, provenance) }

    override suspend fun catalog(): SharedArtifactCatalog = withSessionRetry { metadataClient(it).catalog() }

    private fun endpoint(session: HostedMessagingSession): CommunicatorBlobEndpoint =
        CommunicatorBlobEndpoint(
            session.communicator,
            RealmRouteScope(realmId = realmId, organizationId = session.organizationId),
        )

    private fun metadataClient(session: HostedMessagingSession): CommunicatorSharedMetadataClient =
        CommunicatorSharedMetadataClient(
            session.communicator,
            RealmRouteScope(realmId = realmId, organizationId = session.organizationId),
        )

    private suspend fun <Value> withSessionRetry(block: suspend (HostedMessagingSession) -> Value): Value {
        var session = sessions.filterNotNull().first()
        while (true) {
            try {
                return block(session)
            } catch (failure: RealmArtifactCommunicationException) {
                val failedId = session.id
                session = sessions.filterNotNull().first { it.id != failedId }
            }
        }
    }
}

/** Encodes shared artifact catalog and mutation operations for one Realm session. */
private class CommunicatorSharedMetadataClient(
    private val communicator: Communicator,
    private val address: RealmRouteScope,
) {
    suspend fun catalog(): SharedArtifactCatalog =
        when (val response = request(address.sharedCatalogFetch, FetchSharedArtifactCatalogRequest(afterRevision = null))) {
            is FetchSharedArtifactCatalogResponse.SuccessWrapper -> {
                SharedArtifactCatalog(
                    SharedCatalogRevision(response.value.revision),
                    response.value.artifacts.map(SkirSharedArtifactDescriptor::toApi),
                )
            }

            else -> {
                throw RealmArtifactCommunicationException("Realm shared artifact catalog is unavailable.")
            }
        }

    suspend fun publish(command: PublishSharedArtifact): PublishResult =
        publish(
            PublishSharedArtifactRequest(
                id = command.id.value,
                expectedRevision = command.expectedRevision?.value,
                label = command.label,
                mediaType = command.mediaType,
                digest = command.blob.digest.toSkir(),
                size = command.blob.size,
                metadata = command.metadata?.toSkir(),
                provenance = command.provenance.toSkir(),
                deleted = false,
            ),
        )

    suspend fun delete(
        id: SharedArtifactId,
        expectedRevision: SharedArtifactRevision,
        provenance: SharedArtifactProvenance,
    ): PublishResult =
        publish(
            PublishSharedArtifactRequest(
                id = id.value,
                expectedRevision = expectedRevision.value,
                label = "deleted",
                mediaType = "application/octet-stream",
                digest = null,
                size = null,
                metadata = null,
                provenance = provenance.toSkir(),
                deleted = true,
            ),
        )

    private suspend fun publish(request: PublishSharedArtifactRequest): PublishResult =
        when (val response = request(address.sharedPublish, request)) {
            is PublishSharedArtifactResponse.PublishedWrapper -> {
                PublishResult.Published(response.value.toApi(), catalog().revision)
            }

            is PublishSharedArtifactResponse.UnchangedWrapper -> {
                PublishResult.Unchanged(response.value.toApi())
            }

            is PublishSharedArtifactResponse.ConflictErrorWrapper -> {
                PublishResult.Conflict(response.value?.toApi())
            }

            else -> {
                throw RealmArtifactCommunicationException("Realm shared artifact publication is unavailable.")
            }
        }

    private suspend fun <Request : Any, Response : Any> request(
        contract: UnaryContract<RealmRouteScope, Request, Response>,
        value: Request,
    ): Response =
        when (val result = communicator.request(contract, address, value)) {
            is CommunicationResult.Success -> {
                result.value
            }

            is CommunicationResult.Failure -> {
                throw RealmArtifactCommunicationException(
                    "Realm shared artifact request failed: ${result.error}",
                    result.error.cause,
                )
            }
        }
}
