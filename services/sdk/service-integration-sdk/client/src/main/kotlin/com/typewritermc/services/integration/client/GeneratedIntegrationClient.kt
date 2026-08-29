package com.typewritermc.services.integration.client

import com.typewritermc.services.integration.GeneratedIntegrationContract
import com.typewritermc.services.integration.IntegrationContext
import com.typewritermc.services.integration.IntegrationCredential
import com.typewritermc.services.integration.IntegrationEvent
import com.typewritermc.services.integration.IntegrationGateway
import com.typewritermc.services.integration.IntegrationOperation
import com.typewritermc.services.integration.IntegrationOperationKind
import com.typewritermc.services.integration.IntegrationPermission
import com.typewritermc.services.integration.IntegrationRegistration
import com.typewritermc.services.integration.IntegrationResult
import com.typewritermc.services.libs.filetransfer.FileChunk
import com.typewritermc.services.libs.filetransfer.FileKey
import com.typewritermc.services.libs.filetransfer.FileMetadata
import com.typewritermc.services.libs.filetransfer.FileTransferEndpoint
import com.typewritermc.services.libs.filetransfer.FileTransferResult
import com.typewritermc.services.libs.filetransfer.FileWriteSession
import com.typewritermc.services.libs.filetransfer.TransferId
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow

/**
 * Provides typed generated operations for one authenticated, Realm scoped integration registration.
 *
 * The client rejects undeclared operations and missing permissions before transport. Server authorization remains
 * authoritative. Codec failures are returned as transport failures instead of escaping into integration code.
 */
class GeneratedIntegrationClient(
    private val registration: IntegrationRegistration,
    credential: IntegrationCredential,
    private val contract: GeneratedIntegrationContract,
    private val gateway: IntegrationGateway,
    fileTransfer: FileTransferEndpoint,
) {
    private val context = IntegrationContext(registration.id, registration.realmId, credential)

    val files = IntegrationFileTransferClient(registration, fileTransfer)

    suspend fun <Request : Any, Response : Any> call(
        operation: IntegrationOperation<Request, Response>,
        request: Request,
    ): IntegrationResult<Response> {
        authorize(operation.kind, operation.id, operation.permission)?.let { return it }
        val result = gateway.request(context, operation.kind, operation.id, operation.requestCodec.encode(request))
        return decode(result, operation.responseCodec::decode)
    }

    suspend fun <Event : Any> publish(
        event: IntegrationEvent<Event>,
        value: Event,
    ): IntegrationResult<Unit> {
        authorize(IntegrationOperationKind.EVENT, event.id, event.permission)?.let { return it }
        return gateway.publish(context, event.id, event.codec.encode(value))
    }

    fun <Event : Any> events(event: IntegrationEvent<Event>): Flow<IntegrationResult<Event>> =
        flow {
            authorize(IntegrationOperationKind.EVENT, event.id, event.permission)?.let {
                emit(it)
                return@flow
            }
            gateway.events(context, event.id).collect { result ->
                emit(decode(result, event.codec::decode))
            }
        }

    private fun authorize(
        kind: IntegrationOperationKind,
        id: com.typewritermc.services.integration.IntegrationOperationId,
        permission: IntegrationPermission,
    ): IntegrationResult<Nothing>? {
        if (contract.requiredPermission(kind, id) != permission) return IntegrationResult.UnknownOperation(kind, id)
        if (permission !in registration.permissions) return IntegrationResult.PermissionDenied(permission)
        return null
    }

    private fun <Value : Any> decode(
        result: IntegrationResult<ByteArray>,
        decoder: (ByteArray) -> Value,
    ): IntegrationResult<Value> =
        when (result) {
            is IntegrationResult.Success -> {
                try {
                    IntegrationResult.Success(decoder(result.value))
                } catch (failure: Exception) {
                    IntegrationResult.TransportFailure("Integration response could not be decoded", failure)
                }
            }

            is IntegrationResult.PermissionDenied -> {
                IntegrationResult.PermissionDenied(result.required)
            }

            is IntegrationResult.UnknownOperation -> {
                IntegrationResult.UnknownOperation(result.kind, result.id)
            }

            IntegrationResult.AuthenticationFailed -> {
                IntegrationResult.AuthenticationFailed
            }

            is IntegrationResult.TransportFailure -> {
                IntegrationResult.TransportFailure(result.message, result.cause)
            }
        }
}

/**
 * Exposes generic file transfer only when the registration includes file transfer permission.
 *
 * Domain transfer failures remain nested [FileTransferResult] values, distinct from integration authorization failures.
 */
class IntegrationFileTransferClient internal constructor(
    private val registration: IntegrationRegistration,
    private val endpoint: FileTransferEndpoint,
) {
    suspend fun metadata(key: FileKey): IntegrationResult<FileTransferResult<FileMetadata>> = access { endpoint.metadata(key) }

    suspend fun read(
        key: FileKey,
        offset: Long,
        maximumBytes: Int,
    ): IntegrationResult<FileTransferResult<FileChunk>> = access { endpoint.read(key, offset, maximumBytes) }

    suspend fun beginWrite(
        transferId: TransferId,
        metadata: FileMetadata,
    ): IntegrationResult<FileTransferResult<FileWriteSession>> = access { endpoint.beginWrite(transferId, metadata) }

    suspend fun write(
        transferId: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): IntegrationResult<FileTransferResult<Long>> = access { endpoint.write(transferId, offset, bytes) }

    suspend fun complete(transferId: TransferId): IntegrationResult<FileTransferResult<FileMetadata>> =
        access { endpoint.complete(transferId) }

    suspend fun cancel(transferId: TransferId): IntegrationResult<FileTransferResult<Unit>> = access { endpoint.cancel(transferId) }

    private suspend fun <Value> access(block: suspend () -> Value): IntegrationResult<Value> {
        if (IntegrationPermission.FILE_TRANSFER !in registration.permissions) {
            return IntegrationResult.PermissionDenied(IntegrationPermission.FILE_TRANSFER)
        }
        return IntegrationResult.Success(block())
    }
}
