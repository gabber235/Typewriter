package com.typewritermc.services.libs.filetransfer.storage

import com.typewritermc.services.libs.filetransfer.FileChunk
import com.typewritermc.services.libs.filetransfer.FileDigest
import com.typewritermc.services.libs.filetransfer.FileId
import com.typewritermc.services.libs.filetransfer.FileKey
import com.typewritermc.services.libs.filetransfer.FileMetadata
import com.typewritermc.services.libs.filetransfer.FileRevision
import com.typewritermc.services.libs.filetransfer.FileTransferCoordinator
import com.typewritermc.services.libs.filetransfer.FileTransferEndpoint
import com.typewritermc.services.libs.filetransfer.FileTransferError
import com.typewritermc.services.libs.filetransfer.FileTransferResult
import com.typewritermc.services.libs.filetransfer.FileWriteSession
import com.typewritermc.services.libs.filetransfer.TransferId
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.StandardOpenOption
import java.security.MessageDigest
import java.util.Base64

class FileSystemFileTransferEndpoint(
    private val root: Path,
    private val maximumChunkSize: Int = FileTransferCoordinator.MAXIMUM_CHUNK_SIZE,
    private val dispatcher: CoroutineDispatcher = Dispatchers.IO,
) : FileTransferEndpoint {
    private val mutex = Mutex()
    private val objects = root.resolve("objects")
    private val metadata = root.resolve("metadata")
    private val temporary = root.resolve("temporary")
    private val completedTransfers = mutableMapOf<TransferId, FileMetadata>()

    init {
        require(maximumChunkSize in 1..FileTransferCoordinator.MAXIMUM_CHUNK_SIZE)
    }

    override suspend fun metadata(key: FileKey): FileTransferResult<FileMetadata> =
        access {
            val path = metadataPath(key)
            if (!Files.isRegularFile(path)) return@access FileTransferResult.Failure(FileTransferError.NotFound(key))
            loadMetadata(path)
                ?.takeIf { it.key == key }
                ?.let(FileTransferResult<FileMetadata>::Success)
                ?: FileTransferResult.Failure(FileTransferError.Unavailable("Stored metadata is invalid"))
        }

    override suspend fun read(
        key: FileKey,
        offset: Long,
        maximumBytes: Int,
    ): FileTransferResult<FileChunk> =
        access {
            if (maximumBytes !in 1..maximumChunkSize) {
                return@access FileTransferResult.Failure(FileTransferError.InvalidChunk("Requested chunk size is invalid"))
            }
            val storedMetadata = loadMetadata(metadataPath(key))
            if (storedMetadata?.key != key) {
                return@access FileTransferResult.Failure(FileTransferError.NotFound(key))
            }
            val path = objectPath(key)
            if (!Files.isRegularFile(path)) return@access FileTransferResult.Failure(FileTransferError.NotFound(key))
            val size = storedMetadata.size
            if (Files.size(path) != size) {
                return@access FileTransferResult.Failure(FileTransferError.Unavailable("Stored file size is invalid"))
            }
            if (offset !in 0..size) {
                return@access FileTransferResult.Failure(FileTransferError.InvalidOffset(size, offset))
            }
            val requested = minOf(maximumBytes.toLong(), size - offset).toInt()
            if (requested == 0) return@access FileTransferResult.Success(FileChunk(offset, byteArrayOf()))
            val buffer = ByteBuffer.allocate(requested)
            FileChannel.open(path, StandardOpenOption.READ).use { channel ->
                channel.position(offset)
                while (buffer.hasRemaining()) {
                    if (channel.read(buffer) <= 0) break
                }
            }
            FileTransferResult.Success(FileChunk(offset, buffer.array().copyOf(buffer.position())))
        }

    override suspend fun beginWrite(
        transferId: TransferId,
        metadata: FileMetadata,
    ): FileTransferResult<FileWriteSession> =
        access {
            Files.createDirectories(objects)
            Files.createDirectories(this.metadata)
            Files.createDirectories(temporary)
            val existing = loadMetadata(metadataPath(metadata.key))
            if (existing != null) {
                if (existing == metadata && Files.isRegularFile(objectPath(metadata.key))) {
                    completedTransfers[transferId] = metadata
                    return@access FileTransferResult.Success(FileWriteSession(transferId, metadata, metadata.size))
                }
                return@access FileTransferResult.Failure(FileTransferError.ImmutableConflict(metadata.key))
            }

            val state = statePath(transferId)
            val partial = partialPath(transferId)
            val resumedMetadata = loadMetadata(state)
            if (resumedMetadata != metadata || !Files.isRegularFile(partial) || Files.size(partial) > metadata.size) {
                Files.deleteIfExists(partial)
                Files.deleteIfExists(state)
                Files.createFile(partial)
                writeMetadata(state, metadata)
            }
            FileTransferResult.Success(FileWriteSession(transferId, metadata, Files.size(partial)))
        }

    override suspend fun write(
        transferId: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): FileTransferResult<Long> =
        access {
            if (bytes.isEmpty() || bytes.size > maximumChunkSize) {
                return@access FileTransferResult.Failure(FileTransferError.InvalidChunk("Written chunk size is invalid"))
            }
            val state =
                loadMetadata(statePath(transferId))
                    ?: return@access FileTransferResult.Failure(FileTransferError.UnknownTransfer(transferId))
            val partial = partialPath(transferId)
            val expected = Files.size(partial)
            if (offset != expected) {
                return@access FileTransferResult.Failure(FileTransferError.InvalidOffset(expected, offset))
            }
            val nextOffset = offset + bytes.size
            if (nextOffset > state.size) {
                return@access FileTransferResult.Failure(FileTransferError.SizeMismatch(state.size, nextOffset))
            }
            FileChannel.open(partial, StandardOpenOption.WRITE, StandardOpenOption.APPEND).use { channel ->
                val buffer = ByteBuffer.wrap(bytes)
                while (buffer.hasRemaining()) channel.write(buffer)
                channel.force(false)
            }
            FileTransferResult.Success(nextOffset)
        }

    override suspend fun complete(transferId: TransferId): FileTransferResult<FileMetadata> =
        access {
            completedTransfers.remove(transferId)?.let { return@access FileTransferResult.Success(it) }
            val statePath = statePath(transferId)
            val expected =
                loadMetadata(statePath)
                    ?: return@access FileTransferResult.Failure(FileTransferError.UnknownTransfer(transferId))
            val partial = partialPath(transferId)
            val actualSize = Files.size(partial)
            if (actualSize != expected.size) {
                return@access FileTransferResult.Failure(FileTransferError.SizeMismatch(expected.size, actualSize))
            }
            val actualDigest = digest(partial)
            if (actualDigest != expected.digest) {
                Files.deleteIfExists(partial)
                Files.deleteIfExists(statePath)
                return@access FileTransferResult.Failure(FileTransferError.DigestMismatch(expected.digest, actualDigest))
            }
            val destination = objectPath(expected.key)
            if (Files.isRegularFile(destination)) {
                val destinationSize = Files.size(destination)
                val destinationDigest = digest(destination)
                if (destinationSize != expected.size || destinationDigest != expected.digest) {
                    return@access FileTransferResult.Failure(FileTransferError.ImmutableConflict(expected.key))
                }
                Files.deleteIfExists(partial)
            } else {
                moveAtomically(partial, destination)
            }
            writeMetadata(metadataPath(expected.key), expected)
            Files.deleteIfExists(statePath)
            FileTransferResult.Success(expected)
        }

    override suspend fun cancel(transferId: TransferId): FileTransferResult<Unit> =
        access {
            completedTransfers.remove(transferId)
            Files.deleteIfExists(partialPath(transferId))
            Files.deleteIfExists(statePath(transferId))
            FileTransferResult.Success(Unit)
        }

    suspend fun import(
        key: FileKey,
        bytes: ByteArray,
    ): FileTransferResult<FileMetadata> {
        val metadata = FileMetadata(key, bytes.size.toLong(), digest(bytes))
        val transferId = TransferId.of("import.${storageName(key)}")
        val session = beginWrite(transferId, metadata)
        if (session is FileTransferResult.Failure) return session
        var offset = (session as FileTransferResult.Success).value.acceptedOffset
        while (offset < bytes.size) {
            val end = minOf(bytes.size, offset.toInt() + maximumChunkSize)
            val written = write(transferId, offset, bytes.copyOfRange(offset.toInt(), end))
            if (written is FileTransferResult.Failure) return written
            offset = (written as FileTransferResult.Success).value
        }
        return complete(transferId)
    }

    suspend fun readAll(key: FileKey): FileTransferResult<ByteArray> {
        val metadata = metadata(key)
        if (metadata is FileTransferResult.Failure) return metadata
        val expected = (metadata as FileTransferResult.Success).value
        if (expected.size > Int.MAX_VALUE) {
            return FileTransferResult.Failure(FileTransferError.Unavailable("File is too large to read into memory"))
        }
        val output = ByteArray(expected.size.toInt())
        var offset = 0L
        while (offset < expected.size) {
            val chunk = read(key, offset, minOf(maximumChunkSize.toLong(), expected.size - offset).toInt())
            if (chunk is FileTransferResult.Failure) return chunk
            val value = (chunk as FileTransferResult.Success).value
            value.bytes.copyInto(output, offset.toInt())
            offset += value.bytes.size
        }
        return FileTransferResult.Success(output)
    }

    private suspend fun <Value> access(block: () -> FileTransferResult<Value>): FileTransferResult<Value> =
        withContext(dispatcher) {
            mutex.withLock {
                try {
                    block()
                } catch (failure: Throwable) {
                    if (failure is CancellationException) throw failure
                    FileTransferResult.Failure(FileTransferError.Unavailable(failure.message ?: "File storage failed"))
                }
            }
        }

    private fun objectPath(key: FileKey): Path = objects.resolve("${storageName(key)}.bin")

    private fun metadataPath(key: FileKey): Path = metadata.resolve("${storageName(key)}.meta")

    private fun partialPath(transferId: TransferId): Path = temporary.resolve("${storageName(transferId.value)}.part")

    private fun statePath(transferId: TransferId): Path = temporary.resolve("${storageName(transferId.value)}.state")
}

private fun writeMetadata(
    path: Path,
    metadata: FileMetadata,
) {
    Files.createDirectories(path.parent)
    val bytes =
        listOf(
            "1",
            encode(metadata.key.id.value),
            encode(metadata.key.revision.value),
            metadata.size.toString(),
            metadata.digest.value,
        ).joinToString("\n", postfix = "\n").encodeToByteArray()
    val temporary = Files.createTempFile(path.parent, ".${path.fileName}.", ".tmp")
    try {
        Files.write(temporary, bytes, StandardOpenOption.WRITE, StandardOpenOption.TRUNCATE_EXISTING)
        moveAtomically(temporary, path)
    } finally {
        Files.deleteIfExists(temporary)
    }
}

private fun loadMetadata(path: Path): FileMetadata? {
    if (!Files.isRegularFile(path)) return null
    val lines = Files.readAllLines(path)
    if (lines.size != 5 || lines[0] != "1") return null
    return runCatching {
        FileMetadata(
            FileKey(FileId.of(decode(lines[1])), FileRevision.of(decode(lines[2]))),
            lines[3].toLong(),
            FileDigest.sha256(lines[4]),
        )
    }.getOrNull()
}

private fun moveAtomically(
    source: Path,
    destination: Path,
) {
    try {
        Files.move(source, destination, StandardCopyOption.ATOMIC_MOVE)
    } catch (_: AtomicMoveNotSupportedException) {
        Files.move(source, destination)
    }
}

private fun digest(path: Path): FileDigest {
    val digest = MessageDigest.getInstance("SHA-256")
    Files.newInputStream(path).use { input ->
        val buffer = ByteArray(DEFAULT_BUFFER_SIZE)
        while (true) {
            val count = input.read(buffer)
            if (count < 0) break
            digest.update(buffer, 0, count)
        }
    }
    return FileDigest.sha256(digest.digest().toHex())
}

private fun digest(bytes: ByteArray): FileDigest = FileDigest.sha256(MessageDigest.getInstance("SHA-256").digest(bytes).toHex())

private fun storageName(key: FileKey): String = storageName("${key.id.value}\u0000${key.revision.value}")

private fun storageName(value: String): String = MessageDigest.getInstance("SHA-256").digest(value.encodeToByteArray()).toHex()

private fun ByteArray.toHex(): String = joinToString("") { "%02x".format(it) }

private fun encode(value: String): String = Base64.getUrlEncoder().withoutPadding().encodeToString(value.encodeToByteArray())

private fun decode(value: String): String = Base64.getUrlDecoder().decode(value).decodeToString()
