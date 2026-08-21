package com.typewritermc.services.libs.filetransfer

/** Stable opaque identity for a logical file across immutable revisions. */
@JvmInline
value class FileId private constructor(
    val value: String,
) {
    companion object {
        fun of(value: String): FileId {
            require(identifierPattern.matches(value)) { "Invalid file id" }
            return FileId(value)
        }
    }
}

/** Opaque immutable revision identity supplied by the file owner. */
@JvmInline
value class FileRevision private constructor(
    val value: String,
) {
    companion object {
        fun of(value: String): FileRevision {
            require(identifierPattern.matches(value)) { "Invalid file revision" }
            return FileRevision(value)
        }
    }
}

/** Identifies one resumable transfer session independently from the file being transferred. */
@JvmInline
value class TransferId private constructor(
    val value: String,
) {
    companion object {
        fun of(value: String): TransferId {
            require(identifierPattern.matches(value)) { "Invalid transfer id" }
            return TransferId(value)
        }
    }
}

/** Selects one immutable file revision without exposing provider filesystem paths. */
data class FileKey(
    val id: FileId,
    val revision: FileRevision,
)

/**
 * Carries a content digest used to verify immutable publication and transfer completion.
 *
 * The current contract accepts canonical lowercase SHA 256 values through [sha256].
 */
data class FileDigest private constructor(
    val algorithm: String,
    val value: String,
) {
    companion object {
        fun sha256(value: String): FileDigest {
            require(value.matches(Regex("[0-9a-f]{64}"))) { "Invalid SHA 256 digest" }
            return FileDigest("SHA-256", value)
        }
    }
}

/** Declares the exact size in bytes and digest expected for one immutable file revision. */
data class FileMetadata(
    val key: FileKey,
    val size: Long,
    val digest: FileDigest,
) {
    init {
        require(size >= 0) { "File size must not be negative" }
    }
}

/**
 * Carries a bounded contiguous byte range beginning at [offset].
 *
 * The caller owns [bytes] and must not mutate it after passing the chunk across an endpoint boundary.
 */
data class FileChunk(
    val offset: Long,
    val bytes: ByteArray,
) {
    init {
        require(offset >= 0) { "Chunk offset must not be negative" }
    }

    override fun equals(other: Any?): Boolean = other is FileChunk && offset == other.offset && bytes.contentEquals(other.bytes)

    override fun hashCode(): Int = 31 * offset.hashCode() + bytes.contentHashCode()
}

/** Reports where a destination can resume a transfer after validating its immutable metadata. */
data class FileWriteSession(
    val transferId: TransferId,
    val metadata: FileMetadata,
    val acceptedOffset: Long,
)

/**
 * Provides resumable immutable file reads and writes without exposing storage or transport details.
 *
 * Offsets and returned byte counts are measured in bytes. Writes must be contiguous. [complete] verifies exact size and
 * digest before publishing the revision, while [cancel] removes only temporary session state.
 */
interface FileTransferEndpoint {
    suspend fun metadata(key: FileKey): FileTransferResult<FileMetadata>

    suspend fun read(
        key: FileKey,
        offset: Long,
        maximumBytes: Int,
    ): FileTransferResult<FileChunk>

    suspend fun beginWrite(
        transferId: TransferId,
        metadata: FileMetadata,
    ): FileTransferResult<FileWriteSession>

    suspend fun write(
        transferId: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): FileTransferResult<Long>

    suspend fun complete(transferId: TransferId): FileTransferResult<FileMetadata>

    suspend fun cancel(transferId: TransferId): FileTransferResult<Unit>
}

/** Makes every expected transfer outcome explicit without using exceptions for remote or validation failures. */
sealed interface FileTransferResult<out Value> {
    data class Success<Value>(
        val value: Value,
    ) : FileTransferResult<Value>

    data class Failure(
        val error: FileTransferError,
    ) : FileTransferResult<Nothing>
}

/** Describes stable file transfer failures that adapters preserve across process boundaries. */
sealed interface FileTransferError {
    data class NotFound(
        val key: FileKey,
    ) : FileTransferError

    data class InvalidOffset(
        val expected: Long,
        val actual: Long,
    ) : FileTransferError

    data class InvalidChunk(
        val message: String,
    ) : FileTransferError

    data class DigestMismatch(
        val expected: FileDigest,
        val actual: FileDigest,
    ) : FileTransferError

    data class SizeMismatch(
        val expected: Long,
        val actual: Long,
    ) : FileTransferError

    data class ImmutableConflict(
        val key: FileKey,
    ) : FileTransferError

    data class UnknownTransfer(
        val transferId: TransferId,
    ) : FileTransferError

    data class Unavailable(
        val message: String,
    ) : FileTransferError
}

private val identifierPattern = Regex("[A-Za-z0-9][A-Za-z0-9._:-]{0,254}")
