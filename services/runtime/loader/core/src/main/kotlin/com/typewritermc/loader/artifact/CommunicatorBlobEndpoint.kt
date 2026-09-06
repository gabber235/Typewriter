package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.RealmServiceAddress
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.api.realmRequestAddress
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseClassifier
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.skir.skirUnaryContract
import com.typewritermc.services.libs.telemetry.ErrorSlug
import okio.ByteString.Companion.toByteString
import skirout.service.v1.artifact.BeginArtifactBlobWrite
import skirout.service.v1.artifact.BeginArtifactBlobWriteRequest
import skirout.service.v1.artifact.BeginArtifactBlobWriteResponse
import skirout.service.v1.artifact.CompleteArtifactBlobWrite
import skirout.service.v1.artifact.CompleteArtifactBlobWriteRequest
import skirout.service.v1.artifact.CompleteArtifactBlobWriteResponse
import skirout.service.v1.artifact.FetchArtifactBlobMetadata
import skirout.service.v1.artifact.FetchArtifactBlobMetadataRequest
import skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse
import skirout.service.v1.artifact.ReadArtifactBlob
import skirout.service.v1.artifact.ReadArtifactBlobRequest
import skirout.service.v1.artifact.ReadArtifactBlobResponse
import skirout.service.v1.artifact.WriteArtifactBlobChunk
import skirout.service.v1.artifact.WriteArtifactBlobChunkRequest
import skirout.service.v1.artifact.WriteArtifactBlobChunkResponse
import skirout.service.v1.artifact.ArtifactDigest as SkirArtifactDigest
import skirout.service.v1.artifact.BlobMetadata as SkirBlobMetadata
import skirout.service.v1.artifact.DigestAlgorithm as SkirDigestAlgorithm

typealias RealmArtifactAddress = RealmServiceAddress

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
    private val address: RealmArtifactAddress,
) : BlobEndpoint {
    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> =
        when (
            val response =
                request(
                    blobContracts.metadata,
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
                    blobContracts.read,
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
                    blobContracts.begin,
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
                    blobContracts.write,
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
                    blobContracts.complete,
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
        contract: UnaryContract<RealmArtifactAddress, Request, Response>,
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
    val metadata =
        contract(
            FetchArtifactBlobMetadata,
            "shared.blob.metadata",
            FetchArtifactBlobMetadataResponse.createUnavailable(),
        )
    val read = contract(ReadArtifactBlob, "shared.blob.read", ReadArtifactBlobResponse.createUnavailable())
    val begin =
        contract(
            BeginArtifactBlobWrite,
            "shared.blob.begin",
            BeginArtifactBlobWriteResponse.createUnavailable(),
        )
    val write =
        contract(
            WriteArtifactBlobChunk,
            "shared.blob.write",
            WriteArtifactBlobChunkResponse.createUnavailable(),
        )
    val complete =
        contract(
            CompleteArtifactBlobWrite,
            "shared.blob.complete",
            CompleteArtifactBlobWriteResponse.createUnavailable(),
        )

    private fun <Request : Any, Response : Any> contract(
        method: build.skir.service.Method<Request, Response>,
        suffix: String,
        unavailable: Response,
    ): UnaryContract<RealmArtifactAddress, Request, Response> =
        skirUnaryContract(
            method,
            OperationName.of(suffix),
            blobAddress(suffix),
            ResponsePolicy(unavailable, unavailableClassifier()),
            ErrorSlug.of(suffix.replace('.', '-')),
        )
}

internal val blobContracts = BlobContracts()

private fun blobAddress(suffix: String): AddressTemplate<RealmArtifactAddress> = realmRequestAddress(suffix)

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
