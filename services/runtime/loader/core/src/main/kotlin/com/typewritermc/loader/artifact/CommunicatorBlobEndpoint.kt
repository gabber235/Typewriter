package com.typewritermc.loader.artifact

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.sharedBlobFetch
import com.typewritermc.protocol.transport.generated.sharedBlobMetadata
import com.typewritermc.protocol.transport.generated.sharedBlobStore
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.result.CommunicationError
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.transfer.TransferBusy
import com.typewritermc.services.libs.communicator.transfer.TransferFailure
import com.typewritermc.services.libs.communicator.transfer.TransferInterrupted
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

/** How reconnecting access answers one failed Realm artifact request. */
internal enum class ArtifactRecovery {
    /** The messaging session is gone: wait for a replacement session and repeat the call there. */
    NEW_SESSION,

    /** The Realm host cannot answer right now: repeat the call a bounded number of times after a growing pause. */
    BACK_OFF,

    /** Repeating the same call cannot succeed, so it fails at once. */
    NONE,
}

/**
 * Identifies a failed Realm artifact request attempt and how reconnecting access recovers from it.
 *
 * Ordinary storage outcomes such as not found, invalid content and publication conflicts remain result values.
 */
internal class RealmArtifactCommunicationException(
    message: String,
    val recovery: ArtifactRecovery,
    cause: Throwable? = null,
) : IllegalStateException(message, cause)

/**
 * The recovery a communication failure allows.
 *
 * Only an unavailable connection, or a transport failure that is not a framing outcome, means the session is gone.
 * A busy receiver, a sender that stopped part way and a Realm host without a subscribed route are transient, so they
 * back off. A payload above its ceiling or a frame the receiver rejected fails the same way every time, as do codec
 * failures. A timeout fails at once: a disconnected session reports unavailable instead, and repeating a call that
 * already ran out of time only doubles the wait of a caller that bounds the operation itself.
 */
internal fun CommunicationError.artifactRecovery(): ArtifactRecovery =
    when (this) {
        is CommunicationError.Unavailable -> {
            ArtifactRecovery.NEW_SESSION
        }

        is CommunicationError.NoResponders -> {
            ArtifactRecovery.BACK_OFF
        }

        is CommunicationError.Transport -> {
            when (cause) {
                is TransferBusy, is TransferInterrupted -> ArtifactRecovery.BACK_OFF
                is TransferFailure -> ArtifactRecovery.NONE
                else -> ArtifactRecovery.NEW_SESSION
            }
        }

        is CommunicationError.Timeout, is CommunicationError.Encode, is CommunicationError.Decode -> {
            ArtifactRecovery.NONE
        }
    }

/** Sends one Realm artifact request, throwing a [RealmArtifactCommunicationException] that names its recovery on failure. */
internal suspend fun <Request : Any, Response : Any> Communicator.artifactRequest(
    contract: UnaryContract<RealmRouteScope, Request, Response>,
    address: RealmRouteScope,
    request: Request,
): Response =
    when (val result = request(contract, address, request)) {
        is CommunicationResult.Success -> {
            result.value
        }

        is CommunicationResult.Failure -> {
            throw RealmArtifactCommunicationException(
                "Realm artifact request ${contract.name.value} failed: ${result.error}",
                result.error.artifactRecovery(),
                result.error.cause,
            )
        }
    }

/** The failure of a Realm host that answered with its internal error; it may recover, so the call backs off. */
internal fun realmArtifactUnavailable(message: String) = RealmArtifactCommunicationException(message, ArtifactRecovery.BACK_OFF)

/**
 * Adapts blob operations to stable logical Realm request routes.
 *
 * Expected storage outcomes remain result values. Communication failures and internal error responses throw a Realm
 * artifact communication exception that names how reconnecting callers recover.
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
            else -> throw realmArtifactUnavailable("Realm artifact metadata is unavailable.")
        }

    override suspend fun fetch(digest: ArtifactDigest): BlobResult<ByteArray> =
        when (val response = request(address.sharedBlobFetch, FetchArtifactBlobRequest(digest = digest.toSkir()))) {
            is FetchArtifactBlobResponse.SuccessWrapper -> BlobResult.Success(response.value.content.toByteArray())
            is FetchArtifactBlobResponse.NotFoundErrorWrapper -> BlobResult.NotFound
            is FetchArtifactBlobResponse.InvalidErrorWrapper -> BlobResult.Invalid(response.value.reason)
            else -> throw realmArtifactUnavailable("Realm artifact fetch is unavailable.")
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
            else -> throw realmArtifactUnavailable("Realm artifact store is unavailable.")
        }

    private suspend fun <Request : Any, Response : Any> request(
        contract: UnaryContract<RealmRouteScope, Request, Response>,
        request: Request,
    ): Response = communicator.artifactRequest(contract, address, request)
}
