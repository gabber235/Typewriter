package com.typewritermc.loader.artifact

import com.typewritermc.protocol.transport.generated.RealmRouteScope
import com.typewritermc.protocol.transport.generated.sharedBlobBegin
import com.typewritermc.protocol.transport.generated.sharedBlobComplete
import com.typewritermc.protocol.transport.generated.sharedBlobMetadata
import com.typewritermc.protocol.transport.generated.sharedBlobRead
import com.typewritermc.protocol.transport.generated.sharedBlobWrite
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobChunk
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.BlobWriteSession
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import com.typewritermc.services.libs.filetransfer.blob.TransferId
import okio.ByteString.Companion.toByteString
import skirout.service.v1.artifact.BeginArtifactBlobWriteRequest
import skirout.service.v1.artifact.BeginArtifactBlobWriteResponse
import skirout.service.v1.artifact.CompleteArtifactBlobWriteRequest
import skirout.service.v1.artifact.CompleteArtifactBlobWriteResponse
import skirout.service.v1.artifact.FetchArtifactBlobMetadataRequest
import skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse
import skirout.service.v1.artifact.ReadArtifactBlobRequest
import skirout.service.v1.artifact.ReadArtifactBlobResponse
import skirout.service.v1.artifact.WriteArtifactBlobChunkRequest
import skirout.service.v1.artifact.WriteArtifactBlobChunkResponse
import skirout.service.v1.artifact.ArtifactDigest as SkirArtifactDigest
import skirout.service.v1.artifact.BlobMetadata as SkirBlobMetadata
import skirout.service.v1.artifact.DigestAlgorithm as SkirDigestAlgorithm

/**
 * Identifies an unavailable Realm artifact request attempt.
 *
 * Reconnecting access waits for a new messaging generation after this failure; ordinary storage conflicts remain
 * result values.
 */
internal class RealmArtifactCommunicationException(
    message: String,
    cause: Throwable? = null,
) : IllegalStateException(message, cause)

/**
 * Adapts blob operations to stable logical Realm request routes.
 *
 * Expected storage outcomes remain result values. Communication failures and unavailable responses throw a Realm
 * artifact communication exception so reconnecting callers can replace the session.
 */
class CommunicatorBlobEndpoint(
    private val communicator: Communicator,
    private val address: RealmRouteScope,
) : BlobEndpoint {
    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> =
        when (
            val response =
                request(
                    blobContracts.metadata(address),
                    FetchArtifactBlobMetadataRequest(digest = digest.toSkir()),
                )
        ) {
            is FetchArtifactBlobMetadataResponse.SuccessWrapper -> BlobResult.Success(response.value.toApi())
            is FetchArtifactBlobMetadataResponse.NotFoundWrapper -> BlobResult.NotFound
            is FetchArtifactBlobMetadataResponse.InvalidWrapper -> BlobResult.Invalid(response.value.reason)
            else -> throw RealmArtifactCommunicationException("Realm artifact metadata is unavailable.")
        }

    override suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk> =
        when (
            val response =
                request(
                    blobContracts.read(address),
                    ReadArtifactBlobRequest(
                        digest = digest.toSkir(),
                        offset = offset,
                        maximumBytes = maximumBytes,
                    ),
                )
        ) {
            is ReadArtifactBlobResponse.SuccessWrapper -> {
                BlobResult.Success(
                    BlobChunk(
                        response.value.offset,
                        response.value.bytes.toByteArray(),
                        response.value.complete,
                    ),
                )
            }

            is ReadArtifactBlobResponse.NotFoundWrapper -> {
                BlobResult.NotFound
            }

            is ReadArtifactBlobResponse.InvalidWrapper -> {
                BlobResult.Invalid(response.value.reason)
            }

            else -> {
                throw RealmArtifactCommunicationException("Realm artifact read is unavailable.")
            }
        }

    override suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession> =
        when (
            val response =
                request(
                    blobContracts.begin(address),
                    BeginArtifactBlobWriteRequest(
                        transferId = transfer.value,
                        expected = expected.toSkir(),
                    ),
                )
        ) {
            is BeginArtifactBlobWriteResponse.AcceptedWrapper -> {
                BlobResult.Success(BlobWriteSession(transfer, expected, response.value.offset))
            }

            is BeginArtifactBlobWriteResponse.InvalidWrapper -> {
                BlobResult.Invalid(response.value.reason)
            }

            is BeginArtifactBlobWriteResponse.ConflictWrapper -> {
                BlobResult.Conflict(response.value.reason)
            }

            else -> {
                throw RealmArtifactCommunicationException("Realm artifact write is unavailable.")
            }
        }

    override suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long> =
        when (
            val response =
                request(
                    blobContracts.write(address),
                    WriteArtifactBlobChunkRequest(
                        transferId = transfer.value,
                        offset = offset,
                        bytes = bytes.toByteString(),
                    ),
                )
        ) {
            is WriteArtifactBlobChunkResponse.AcceptedWrapper -> BlobResult.Success(response.value.offset)
            is WriteArtifactBlobChunkResponse.NotFoundWrapper -> BlobResult.NotFound
            is WriteArtifactBlobChunkResponse.InvalidWrapper -> BlobResult.Invalid(response.value.reason)
            is WriteArtifactBlobChunkResponse.ConflictWrapper -> BlobResult.Conflict(response.value.reason)
            else -> throw RealmArtifactCommunicationException("Realm artifact write is unavailable.")
        }

    override suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata> =
        when (
            val response =
                request(
                    blobContracts.complete(address),
                    CompleteArtifactBlobWriteRequest(transferId = transfer.value),
                )
        ) {
            is CompleteArtifactBlobWriteResponse.SuccessWrapper -> BlobResult.Success(response.value.toApi())
            is CompleteArtifactBlobWriteResponse.NotFoundWrapper -> BlobResult.NotFound
            is CompleteArtifactBlobWriteResponse.InvalidWrapper -> BlobResult.Invalid(response.value.reason)
            is CompleteArtifactBlobWriteResponse.ConflictWrapper -> BlobResult.Conflict(response.value.reason)
            else -> throw RealmArtifactCommunicationException("Realm artifact completion is unavailable.")
        }

    private suspend fun <Request : Any, Response : Any> request(
        contract: UnaryContract<RealmRouteScope, Request, Response>,
        request: Request,
    ): Response =
        when (val result = communicator.request(contract, address, request)) {
            is CommunicationResult.Success -> {
                result.value
            }

            is CommunicationResult.Failure -> {
                throw RealmArtifactCommunicationException(
                    "Realm artifact request failed: ${result.error}",
                    result.error.cause,
                )
            }
        }
}

internal class BlobContracts {
    fun metadata(scope: RealmRouteScope) =
        scope.sharedBlobMetadata(ResponsePolicy(FetchArtifactBlobMetadataResponse.createUnavailable(), unavailableClassifier()))

    fun read(scope: RealmRouteScope) =
        scope.sharedBlobRead(ResponsePolicy(ReadArtifactBlobResponse.createUnavailable(), unavailableClassifier()))

    fun begin(scope: RealmRouteScope) =
        scope.sharedBlobBegin(ResponsePolicy(BeginArtifactBlobWriteResponse.createUnavailable(), unavailableClassifier()))

    fun write(scope: RealmRouteScope) =
        scope.sharedBlobWrite(ResponsePolicy(WriteArtifactBlobChunkResponse.createUnavailable(), unavailableClassifier()))

    fun complete(scope: RealmRouteScope) =
        scope.sharedBlobComplete(ResponsePolicy(CompleteArtifactBlobWriteResponse.createUnavailable(), unavailableClassifier()))
}

internal val blobContracts = BlobContracts()

private fun <Response : Any> unavailableClassifier(): ResponseClassifier<Response> =
    ResponseClassifier { response ->
        val unavailable = response::class.simpleName == "UnavailableWrapper"
        ResponseClassification(
            if (unavailable) ResponseOutcome.INTERNAL_ERROR else ResponseOutcome.SUCCESS,
            ResponseVariant.of(if (unavailable) "unavailable" else "success"),
        )
    }

private fun ArtifactDigest.toSkir(): SkirArtifactDigest =
    SkirArtifactDigest(
        algorithm = SkirDigestAlgorithm.SHA256,
        value = value,
    )

private fun BlobMetadata.toSkir(): SkirBlobMetadata = SkirBlobMetadata(digest = digest.toSkir(), size = size)

private fun SkirBlobMetadata.toApi(): BlobMetadata {
    require(digest.algorithm == SkirDigestAlgorithm.SHA256) { "Unsupported artifact digest algorithm." }
    return BlobMetadata(ArtifactDigest(DigestAlgorithm.SHA_256, digest.value), size)
}
