package com.typewritermc.loader.artifact

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.sharedBlobFetch
import com.typewritermc.protocol.transport.generated.sharedBlobMetadata
import com.typewritermc.protocol.transport.generated.sharedBlobStore
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.StoreResult
import okio.ByteString.Companion.toByteString
import skirout.service.v1.artifact.FetchArtifactBlobMetadataRequest
import skirout.service.v1.artifact.FetchArtifactBlobMetadataResponse
import skirout.service.v1.artifact.FetchArtifactBlobRequest
import skirout.service.v1.artifact.FetchArtifactBlobResponse
import skirout.service.v1.artifact.StoreArtifactBlobRequest
import skirout.service.v1.artifact.StoreArtifactBlobResponse

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
                    address.sharedBlobMetadata,
                    FetchArtifactBlobMetadataRequest(digest = digest.toSkir()),
                )
        ) {
            is FetchArtifactBlobMetadataResponse.SuccessWrapper -> BlobResult.Success(response.value.toApi())
            is FetchArtifactBlobMetadataResponse.NotFoundErrorWrapper -> BlobResult.NotFound
            is FetchArtifactBlobMetadataResponse.InvalidErrorWrapper -> BlobResult.Invalid(response.value.reason)
            else -> throw RealmArtifactCommunicationException("Realm artifact metadata is unavailable.")
        }

    override suspend fun fetch(digest: ArtifactDigest): BlobResult<ByteArray> =
        when (val response = request(address.sharedBlobFetch, FetchArtifactBlobRequest(digest = digest.toSkir()))) {
            is FetchArtifactBlobResponse.SuccessWrapper -> BlobResult.Success(response.value.content.toByteArray())
            is FetchArtifactBlobResponse.NotFoundErrorWrapper -> BlobResult.NotFound
            is FetchArtifactBlobResponse.InvalidErrorWrapper -> BlobResult.Invalid(response.value.reason)
            else -> throw RealmArtifactCommunicationException("Realm artifact fetch is unavailable.")
        }

    override suspend fun store(
        expected: BlobMetadata,
        content: ByteArray,
    ): StoreResult =
        when (
            val response =
                request(
                    address.sharedBlobStore,
                    StoreArtifactBlobRequest(expected = expected.toSkir(), content = content.toByteString()),
                )
        ) {
            is StoreArtifactBlobResponse.SuccessWrapper -> StoreResult.Stored(response.value.toApi())
            is StoreArtifactBlobResponse.InvalidErrorWrapper -> StoreResult.Invalid(response.value.reason)
            else -> throw RealmArtifactCommunicationException("Realm artifact store is unavailable.")
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
