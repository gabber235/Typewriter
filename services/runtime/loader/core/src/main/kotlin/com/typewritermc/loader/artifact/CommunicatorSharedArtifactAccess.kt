package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.artifact.ArtifactDigest
import com.typewritermc.loader.api.artifact.BlobChunk
import com.typewritermc.loader.api.artifact.BlobMetadata
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.artifact.BlobWriteSession
import com.typewritermc.loader.api.artifact.DigestAlgorithm
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
import com.typewritermc.loader.api.artifact.TransferId
import com.typewritermc.loader.api.realmRequestAddress
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.skir.skirUnaryContract
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.filterNotNull
import kotlinx.coroutines.flow.first
import skirout.service.v1.artifact.FetchSharedArtifactCatalog
import skirout.service.v1.artifact.FetchSharedArtifactCatalogRequest
import skirout.service.v1.artifact.FetchSharedArtifactCatalogResponse
import skirout.service.v1.artifact.ProducerMetadataEntry
import skirout.service.v1.artifact.PublishSharedArtifactRequest
import skirout.service.v1.artifact.PublishSharedArtifactResponse
import java.util.concurrent.ConcurrentHashMap
import skirout.service.v1.artifact.ArtifactDigest as SkirArtifactDigest
import skirout.service.v1.artifact.DigestAlgorithm as SkirDigestAlgorithm
import skirout.service.v1.artifact.ProducerMetadata as SkirProducerMetadata
import skirout.service.v1.artifact.PublishSharedArtifact as PublishSharedArtifactMethod
import skirout.service.v1.artifact.SharedArtifactDescriptor as SkirSharedArtifactDescriptor
import skirout.service.v1.artifact.SharedArtifactProvenance as SkirSharedArtifactProvenance

class ReconnectingSharedArtifactAccess(
    private val realmId: String,
    private val sessions: StateFlow<HostedMessagingSession?>,
) : SharedArtifactAccess {
    private val transfers = ConcurrentHashMap<TransferId, BlobMetadata>()

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> = withSessionRetry { endpoint(it).metadata(digest) }

    override suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk> = withSessionRetry { endpoint(it).read(digest, offset, maximumBytes) }

    override suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession> =
        withSessionRetry { session ->
            endpoint(session).beginWrite(transfer, expected).also { result ->
                if (result is BlobResult.Success) transfers[transfer] = expected
            }
        }

    override suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long> =
        withSessionRetry { session ->
            val expected = transfers[transfer]
            if (expected != null) {
                when (val resumed = endpoint(session).beginWrite(transfer, expected)) {
                    is BlobResult.Success -> {
                        if (resumed.value.offset >= offset + bytes.size) {
                            return@withSessionRetry BlobResult.Success(resumed.value.offset)
                        }
                        if (resumed.value.offset !=
                            offset
                        ) {
                            return@withSessionRetry BlobResult.Conflict("Transfer offset changed unexpectedly.")
                        }
                    }

                    else -> {
                        return@withSessionRetry resumed.cast()
                    }
                }
            }
            endpoint(session).write(transfer, offset, bytes)
        }

    override suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata> =
        withSessionRetry { session ->
            val result = endpoint(session).complete(transfer)
            val expected = transfers[transfer]
            when {
                result is BlobResult.Success -> {
                    result.also { transfers.remove(transfer) }
                }

                result == BlobResult.NotFound && expected != null && endpoint(session).metadata(expected.digest) is BlobResult.Success -> {
                    BlobResult.Success(expected).also { transfers.remove(transfer) }
                }

                else -> {
                    result
                }
            }
        }

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
            RealmArtifactAddress(realmId = realmId, organizationId = session.organizationId),
        )

    private fun metadataClient(session: HostedMessagingSession): CommunicatorSharedMetadataClient =
        CommunicatorSharedMetadataClient(
            session.communicator,
            RealmArtifactAddress(realmId = realmId, organizationId = session.organizationId),
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

@Suppress("UNCHECKED_CAST")
private fun <Value> BlobResult<*>.cast(): BlobResult<Value> = this as BlobResult<Value>

private class CommunicatorSharedMetadataClient(
    private val communicator: Communicator,
    private val address: RealmArtifactAddress,
) {
    suspend fun catalog(): SharedArtifactCatalog =
        when (val response = request(sharedContracts.catalog, FetchSharedArtifactCatalogRequest(afterRevision = null))) {
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
        when (val response = request(sharedContracts.publish, request)) {
            is PublishSharedArtifactResponse.PublishedWrapper -> {
                PublishResult.Published(response.value.toApi(), catalog().revision)
            }

            is PublishSharedArtifactResponse.UnchangedWrapper -> {
                PublishResult.Unchanged(response.value.toApi())
            }

            is PublishSharedArtifactResponse.ConflictWrapper -> {
                PublishResult.Conflict(response.value?.toApi())
            }

            else -> {
                throw RealmArtifactCommunicationException("Realm shared artifact publication is unavailable.")
            }
        }

    private suspend fun <Request : Any, Response : Any> request(
        contract: UnaryContract<RealmArtifactAddress, Request, Response>,
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

internal class SharedContracts {
    val catalog = contract(FetchSharedArtifactCatalog, "shared.catalog.fetch", FetchSharedArtifactCatalogResponse.createUnavailable())
    val publish = contract(PublishSharedArtifactMethod, "shared.publish", PublishSharedArtifactResponse.createUnavailable())

    private fun <Request : Any, Response : Any> contract(
        method: build.skir.service.Method<Request, Response>,
        suffix: String,
        unavailable: Response,
    ): UnaryContract<RealmArtifactAddress, Request, Response> =
        skirUnaryContract(
            method,
            OperationName.of(suffix),
            sharedAddress(suffix),
            ResponsePolicy(unavailable) { response ->
                val failed = response::class.simpleName == "UnavailableWrapper"
                ResponseClassification(
                    if (failed) ResponseOutcome.INTERNAL_ERROR else ResponseOutcome.SUCCESS,
                    ResponseVariant.of(if (failed) "unavailable" else "success"),
                )
            },
            ErrorSlug.of(suffix.replace('.', '-')),
        )
}

internal val sharedContracts = SharedContracts()

private fun sharedAddress(suffix: String): AddressTemplate<RealmArtifactAddress> = realmRequestAddress(suffix)

private fun ArtifactDigest.toSkir() = SkirArtifactDigest(algorithm = SkirDigestAlgorithm.SHA256, value = value)

private fun SkirArtifactDigest.toApi(): ArtifactDigest {
    require(algorithm == SkirDigestAlgorithm.SHA256) { "Unsupported artifact digest algorithm." }
    return ArtifactDigest(DigestAlgorithm.SHA_256, value)
}

private fun ProducerMetadata.toSkir() =
    SkirProducerMetadata(
        entries = values.entries.sortedBy { it.key }.map { ProducerMetadataEntry(key = it.key, value = it.value) },
    )

private fun SkirProducerMetadata.toApi() = ProducerMetadata(entries.associate { it.key to it.value })

private fun SharedArtifactProvenance.toSkir(): SkirSharedArtifactProvenance =
    when (this) {
        is SharedArtifactProvenance.LocalInbox -> {
            SkirSharedArtifactProvenance.createLocalInbox(relativePath = relativePath)
        }

        is SharedArtifactProvenance.PanelUpload -> {
            SkirSharedArtifactProvenance.createPanel(userId = userId)
        }

        is SharedArtifactProvenance.HostedRuntime -> {
            SkirSharedArtifactProvenance.createService(hostId = hostId, runtimeId = runtimeId)
        }
    }

private fun SkirSharedArtifactProvenance.toApi(): SharedArtifactProvenance =
    when (this) {
        is SkirSharedArtifactProvenance.LocalInboxWrapper -> SharedArtifactProvenance.LocalInbox(value.relativePath)
        is SkirSharedArtifactProvenance.PanelWrapper -> SharedArtifactProvenance.PanelUpload(value.userId)
        is SkirSharedArtifactProvenance.ServiceWrapper -> SharedArtifactProvenance.HostedRuntime(value.hostId, value.runtimeId)
        else -> error("Unknown shared artifact provenance.")
    }

private fun SkirSharedArtifactDescriptor.toApi() =
    SharedArtifactDescriptor(
        SharedArtifactId(id),
        SharedArtifactRevision(revision),
        label,
        mediaType,
        digest?.toApi(),
        size,
        metadata?.toApi(),
        provenance.toApi(),
        deleted,
    )
