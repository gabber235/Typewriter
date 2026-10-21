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
import com.typewritermc.protocol.transport.generated.sharedBlobBegin
import com.typewritermc.protocol.transport.generated.sharedBlobComplete
import com.typewritermc.protocol.transport.generated.sharedBlobMetadata
import com.typewritermc.protocol.transport.generated.sharedBlobRead
import com.typewritermc.protocol.transport.generated.sharedBlobWrite
import com.typewritermc.protocol.transport.generated.sharedCatalogFetch
import com.typewritermc.protocol.transport.generated.sharedPublish
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutesBuilder
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import com.typewritermc.services.libs.filetransfer.blob.TransferId
import okio.ByteString.Companion.toByteString
import skirout.service.v1.artifact.BeginArtifactBlobWriteResponse
import skirout.service.v1.artifact.CompleteArtifactBlobWriteResponse
import skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse
import skirout.service.v1.artifact.FetchSharedArtifactCatalogResponse
import skirout.service.v1.artifact.ProducerMetadataEntry
import skirout.service.v1.artifact.PublishSharedArtifactRequest
import skirout.service.v1.artifact.PublishSharedArtifactResponse
import skirout.service.v1.artifact.ReadArtifactBlobResponse
import skirout.service.v1.artifact.WriteArtifactBlobChunkResponse
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
                is BlobResult.Conflict -> FetchArtifactBlobMetadataResponse.createInvalidError(reason = result.reason)
            }
        }
        unaryAt(address.sharedBlobRead, address) { call ->
            when (val result = artifacts.read(call.request.digest.toApi(), call.request.offset, call.request.maximumBytes)) {
                is BlobResult.Success -> {
                    ReadArtifactBlobResponse.createSuccess(
                        offset = result.value.offset,
                        bytes = result.value.bytes.toByteString(),
                        complete = result.value.complete,
                    )
                }

                BlobResult.NotFound -> {
                    ReadArtifactBlobResponse.createNotFoundError()
                }

                is BlobResult.Invalid -> {
                    ReadArtifactBlobResponse.createInvalidError(reason = result.reason)
                }

                is BlobResult.Conflict -> {
                    ReadArtifactBlobResponse.createInvalidError(reason = result.reason)
                }
            }
        }
        unaryAt(address.sharedBlobBegin, address) { call ->
            when (val result = artifacts.beginWrite(TransferId(call.request.transferId), call.request.expected.toApi())) {
                is BlobResult.Success -> BeginArtifactBlobWriteResponse.createAccepted(offset = result.value.offset)
                BlobResult.NotFound -> BeginArtifactBlobWriteResponse.createInvalidError(reason = "Transfer was not found.")
                is BlobResult.Invalid -> BeginArtifactBlobWriteResponse.createInvalidError(reason = result.reason)
                is BlobResult.Conflict -> BeginArtifactBlobWriteResponse.createConflictError(reason = result.reason)
            }
        }
        unaryAt(address.sharedBlobWrite, address) { call ->
            when (
                val result =
                    artifacts.write(
                        TransferId(call.request.transferId),
                        call.request.offset,
                        call.request.bytes.toByteArray(),
                    )
            ) {
                is BlobResult.Success -> WriteArtifactBlobChunkResponse.createAccepted(offset = result.value)
                BlobResult.NotFound -> WriteArtifactBlobChunkResponse.createNotFoundError()
                is BlobResult.Invalid -> WriteArtifactBlobChunkResponse.createInvalidError(reason = result.reason)
                is BlobResult.Conflict -> WriteArtifactBlobChunkResponse.createConflictError(reason = result.reason)
            }
        }
        unaryAt(address.sharedBlobComplete, address) { call ->
            when (val result = artifacts.complete(TransferId(call.request.transferId))) {
                is BlobResult.Success -> CompleteArtifactBlobWriteResponse.SuccessWrapper(result.value.toSkir())
                BlobResult.NotFound -> CompleteArtifactBlobWriteResponse.createNotFoundError()
                is BlobResult.Invalid -> CompleteArtifactBlobWriteResponse.createInvalidError(reason = result.reason)
                is BlobResult.Conflict -> CompleteArtifactBlobWriteResponse.createConflictError(reason = result.reason)
            }
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

private fun ArtifactDigest.toSkir() = SkirArtifactDigest(algorithm = SkirDigestAlgorithm.SHA256, value = value)

private fun SkirArtifactDigest.toApi(): ArtifactDigest {
    require(algorithm == SkirDigestAlgorithm.SHA256) { "Unsupported artifact digest algorithm." }
    return ArtifactDigest(DigestAlgorithm.SHA_256, value)
}

private fun BlobMetadata.toSkir() = SkirBlobMetadata(digest = digest.toSkir(), size = size)

private fun SkirBlobMetadata.toApi() = BlobMetadata(digest.toApi(), size)

private fun ProducerMetadata.toSkir() =
    SkirProducerMetadata(entries = values.entries.sortedBy { it.key }.map { ProducerMetadataEntry(key = it.key, value = it.value) })

private fun SkirProducerMetadata.toApi() = ProducerMetadata(entries.associate { it.key to it.value })

private fun SharedArtifactDescriptor.toSkir() =
    SkirSharedArtifactDescriptor(
        id = id.value,
        revision = revision.value,
        label = label,
        mediaType = mediaType,
        digest = digest?.toSkir(),
        size = size,
        metadata = metadata?.toSkir(),
        provenance = provenance.toSkir(),
        deleted = deleted,
    )

private fun SharedArtifactProvenance.toSkir(): SkirSharedArtifactProvenance =
    when (this) {
        is SharedArtifactProvenance.LocalInbox -> {
            SkirSharedArtifactProvenance.createLocalInbox(relativePath = relativePath)
        }

        is SharedArtifactProvenance.PanelUpload -> {
            SkirSharedArtifactProvenance.createPanel(userId = userId)
        }

        is SharedArtifactProvenance.HostedRuntime -> {
            SkirSharedArtifactProvenance.createService(serviceId = serviceId, runtimeId = runtimeId)
        }
    }

private fun SkirSharedArtifactProvenance.toApi(): SharedArtifactProvenance =
    when (this) {
        is SkirSharedArtifactProvenance.LocalInboxWrapper -> SharedArtifactProvenance.LocalInbox(value.relativePath)
        is SkirSharedArtifactProvenance.PanelWrapper -> SharedArtifactProvenance.PanelUpload(value.userId)
        is SkirSharedArtifactProvenance.ServiceWrapper -> SharedArtifactProvenance.HostedRuntime(value.serviceId, value.runtimeId)
        else -> error("Unknown shared artifact provenance.")
    }
