@file:OptIn(kotlinx.serialization.ExperimentalSerializationApi::class)

package com.typewritermc.services.libs.filetransfer.messaging

import com.typewritermc.services.libs.filetransfer.FileChunk
import com.typewritermc.services.libs.filetransfer.FileDigest
import com.typewritermc.services.libs.filetransfer.FileId
import com.typewritermc.services.libs.filetransfer.FileKey
import com.typewritermc.services.libs.filetransfer.FileMetadata
import com.typewritermc.services.libs.filetransfer.FileRevision
import com.typewritermc.services.libs.filetransfer.FileTransferEndpoint
import com.typewritermc.services.libs.filetransfer.FileTransferError
import com.typewritermc.services.libs.filetransfer.FileTransferResult
import com.typewritermc.services.libs.filetransfer.FileWriteSession
import com.typewritermc.services.libs.filetransfer.TransferId
import kotlinx.coroutines.CancellationException
import kotlinx.serialization.Serializable
import kotlinx.serialization.cbor.Cbor

fun interface FileTransferMessageChannel {
    suspend fun exchange(payload: ByteArray): MessageChannelResult
}

sealed interface MessageChannelResult {
    data class Success(
        val payload: ByteArray,
    ) : MessageChannelResult

    data class Failure(
        val message: String,
    ) : MessageChannelResult
}

class MessagingFileTransferEndpoint(
    private val channel: FileTransferMessageChannel,
) : FileTransferEndpoint {
    override suspend fun metadata(key: FileKey): FileTransferResult<FileMetadata> =
        call(WireRequest.Metadata(key.toWire())).expect<WireResponse.Metadata, FileMetadata> {
            it.metadata.toDomain()
        }

    override suspend fun read(
        key: FileKey,
        offset: Long,
        maximumBytes: Int,
    ): FileTransferResult<FileChunk> =
        call(WireRequest.Read(key.toWire(), offset, maximumBytes)).expect<WireResponse.Chunk, FileChunk> {
            FileChunk(it.offset, it.bytes.copyOf())
        }

    override suspend fun beginWrite(
        transferId: TransferId,
        metadata: FileMetadata,
    ): FileTransferResult<FileWriteSession> =
        call(WireRequest.BeginWrite(transferId.value, metadata.toWire())).expect<WireResponse.Session, FileWriteSession> {
            FileWriteSession(TransferId.of(it.transferId), it.metadata.toDomain(), it.acceptedOffset)
        }

    override suspend fun write(
        transferId: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): FileTransferResult<Long> =
        call(WireRequest.Write(transferId.value, offset, bytes.copyOf())).expect<WireResponse.Offset, Long> {
            it.offset
        }

    override suspend fun complete(transferId: TransferId): FileTransferResult<FileMetadata> =
        call(WireRequest.Complete(transferId.value)).expect<WireResponse.Metadata, FileMetadata> {
            it.metadata.toDomain()
        }

    override suspend fun cancel(transferId: TransferId): FileTransferResult<Unit> =
        call(WireRequest.Cancel(transferId.value)).expect<WireResponse.Empty, Unit> {}

    private suspend fun call(request: WireRequest): FileTransferResult<WireResponse> =
        try {
            when (val result = channel.exchange(codec.encodeToByteArray(WireRequest.serializer(), request))) {
                is MessageChannelResult.Failure -> {
                    FileTransferResult.Failure(FileTransferError.Unavailable(result.message))
                }

                is MessageChannelResult.Success -> {
                    when (val response = codec.decodeFromByteArray(WireResponse.serializer(), result.payload)) {
                        is WireResponse.Failure -> FileTransferResult.Failure(response.error.toDomain())
                        else -> FileTransferResult.Success(response)
                    }
                }
            }
        } catch (failure: Throwable) {
            if (failure is CancellationException) throw failure
            FileTransferResult.Failure(FileTransferError.Unavailable(failure.message ?: "Invalid messaging response"))
        }

    private inline fun <reified Response : WireResponse, Value> FileTransferResult<WireResponse>.expect(
        transform: (Response) -> Value,
    ): FileTransferResult<Value> =
        when (this) {
            is FileTransferResult.Failure -> {
                this
            }

            is FileTransferResult.Success -> {
                val response = value
                if (response is Response) {
                    FileTransferResult.Success(transform(response))
                } else {
                    FileTransferResult.Failure(FileTransferError.Unavailable("Unexpected messaging response"))
                }
            }
        }
}

class FileTransferMessageHandler(
    private val endpoint: FileTransferEndpoint,
) {
    suspend fun handle(payload: ByteArray): MessageChannelResult =
        try {
            val request = codec.decodeFromByteArray(WireRequest.serializer(), payload)
            val response = request.execute(endpoint)
            MessageChannelResult.Success(codec.encodeToByteArray(WireResponse.serializer(), response))
        } catch (failure: Throwable) {
            if (failure is CancellationException) throw failure
            MessageChannelResult.Failure(failure.message ?: "Invalid file transfer message")
        }
}

private suspend fun WireRequest.execute(endpoint: FileTransferEndpoint): WireResponse =
    when (this) {
        is WireRequest.Metadata -> {
            endpoint.metadata(key.toDomain()).map { WireResponse.Metadata(it.toWire()) }
        }

        is WireRequest.Read -> {
            endpoint.read(key.toDomain(), offset, maximumBytes).map { WireResponse.Chunk(it.offset, it.bytes) }
        }

        is WireRequest.BeginWrite -> {
            endpoint.beginWrite(TransferId.of(transferId), metadata.toDomain()).map {
                WireResponse.Session(it.transferId.value, it.metadata.toWire(), it.acceptedOffset)
            }
        }

        is WireRequest.Write -> {
            endpoint.write(TransferId.of(transferId), offset, bytes).map(WireResponse::Offset)
        }

        is WireRequest.Complete -> {
            endpoint.complete(TransferId.of(transferId)).map { WireResponse.Metadata(it.toWire()) }
        }

        is WireRequest.Cancel -> {
            endpoint.cancel(TransferId.of(transferId)).map { WireResponse.Empty }
        }
    }

private inline fun <Value> FileTransferResult<Value>.map(transform: (Value) -> WireResponse): WireResponse =
    when (this) {
        is FileTransferResult.Failure -> WireResponse.Failure(error.toWire())
        is FileTransferResult.Success -> transform(value)
    }

@Serializable
private sealed interface WireRequest {
    @Serializable
    data class Metadata(
        val key: WireFileKey,
    ) : WireRequest

    @Serializable
    data class Read(
        val key: WireFileKey,
        val offset: Long,
        val maximumBytes: Int,
    ) : WireRequest

    @Serializable
    data class BeginWrite(
        val transferId: String,
        val metadata: WireFileMetadata,
    ) : WireRequest

    @Serializable
    data class Write(
        val transferId: String,
        val offset: Long,
        val bytes: ByteArray,
    ) : WireRequest

    @Serializable
    data class Complete(
        val transferId: String,
    ) : WireRequest

    @Serializable
    data class Cancel(
        val transferId: String,
    ) : WireRequest
}

@Serializable
private sealed interface WireResponse {
    @Serializable
    data class Metadata(
        val metadata: WireFileMetadata,
    ) : WireResponse

    @Serializable
    data class Chunk(
        val offset: Long,
        val bytes: ByteArray,
    ) : WireResponse

    @Serializable
    data class Session(
        val transferId: String,
        val metadata: WireFileMetadata,
        val acceptedOffset: Long,
    ) : WireResponse

    @Serializable
    data class Offset(
        val offset: Long,
    ) : WireResponse

    @Serializable
    data object Empty : WireResponse

    @Serializable
    data class Failure(
        val error: WireError,
    ) : WireResponse
}

@Serializable
private data class WireFileKey(
    val id: String,
    val revision: String,
)

@Serializable
private data class WireFileMetadata(
    val key: WireFileKey,
    val size: Long,
    val digest: String,
)

@Serializable
private data class WireError(
    val type: String,
    val first: String? = null,
    val second: String? = null,
    val key: WireFileKey? = null,
)

private fun FileKey.toWire() = WireFileKey(id.value, revision.value)

private fun WireFileKey.toDomain() = FileKey(FileId.of(id), FileRevision.of(revision))

private fun FileMetadata.toWire() = WireFileMetadata(key.toWire(), size, digest.value)

private fun WireFileMetadata.toDomain() = FileMetadata(key.toDomain(), size, FileDigest.sha256(digest))

private fun FileTransferError.toWire(): WireError =
    when (this) {
        is FileTransferError.NotFound -> WireError("not_found", key = key.toWire())
        is FileTransferError.InvalidOffset -> WireError("invalid_offset", expected.toString(), actual.toString())
        is FileTransferError.InvalidChunk -> WireError("invalid_chunk", message)
        is FileTransferError.DigestMismatch -> WireError("digest_mismatch", expected.value, actual.value)
        is FileTransferError.SizeMismatch -> WireError("size_mismatch", expected.toString(), actual.toString())
        is FileTransferError.ImmutableConflict -> WireError("immutable_conflict", key = key.toWire())
        is FileTransferError.UnknownTransfer -> WireError("unknown_transfer", transferId.value)
        is FileTransferError.Unavailable -> WireError("unavailable", message)
    }

private fun WireError.toDomain(): FileTransferError =
    when (type) {
        "not_found" -> {
            FileTransferError.NotFound(requireNotNull(key).toDomain())
        }

        "invalid_offset" -> {
            FileTransferError.InvalidOffset(requireNotNull(first).toLong(), requireNotNull(second).toLong())
        }

        "invalid_chunk" -> {
            FileTransferError.InvalidChunk(requireNotNull(first))
        }

        "digest_mismatch" -> {
            FileTransferError.DigestMismatch(FileDigest.sha256(requireNotNull(first)), FileDigest.sha256(requireNotNull(second)))
        }

        "size_mismatch" -> {
            FileTransferError.SizeMismatch(requireNotNull(first).toLong(), requireNotNull(second).toLong())
        }

        "immutable_conflict" -> {
            FileTransferError.ImmutableConflict(requireNotNull(key).toDomain())
        }

        "unknown_transfer" -> {
            FileTransferError.UnknownTransfer(TransferId.of(requireNotNull(first)))
        }

        "unavailable" -> {
            FileTransferError.Unavailable(requireNotNull(first))
        }

        else -> {
            FileTransferError.Unavailable("Unknown messaging error")
        }
    }

private val codec =
    Cbor {
        encodeDefaults = true
        ignoreUnknownKeys = false
    }
