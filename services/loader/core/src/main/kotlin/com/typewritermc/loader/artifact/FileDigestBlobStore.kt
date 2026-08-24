package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.artifactSpan
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import java.nio.ByteBuffer
import java.nio.channels.FileChannel
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.nio.file.StandardOpenOption
import java.security.DigestInputStream
import java.security.MessageDigest
import java.time.Clock
import java.time.Duration
import java.time.Instant
import java.util.Properties
import kotlin.io.path.createDirectories
import kotlin.io.path.exists
import kotlin.io.path.fileSize
import kotlin.io.path.inputStream
import kotlin.io.path.isRegularFile
import kotlin.io.path.name
import kotlin.io.path.outputStream

class FileDigestBlobStore(
    root: Path,
    private val clock: Clock = Clock.systemUTC(),
    private val transferLease: Duration = Duration.ofHours(24),
    private val telemetry: ServiceTelemetry? = null,
) : BlobEndpoint {
    private val blobs = root.resolve("blobs").also(Path::createDirectories)
    private val transfers = root.resolve("transfers").also(Path::createDirectories)

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> =
        withContext(Dispatchers.IO) {
            val path = blobPath(digest)
            if (!path.isRegularFile()) return@withContext BlobResult.NotFound
            BlobResult.Success(BlobMetadata(digest, path.fileSize()))
        }

    override suspend fun read(
        digest: ArtifactDigest,
        offset: Long,
        maximumBytes: Int,
    ): BlobResult<BlobChunk> =
        withContext(Dispatchers.IO) {
            if (offset < 0) return@withContext BlobResult.Invalid("Blob offset must not be negative.")
            if (maximumBytes !in 1..MAXIMUM_CHUNK_SIZE) {
                return@withContext BlobResult.Invalid("Blob chunk size is outside the accepted range.")
            }
            val path = blobPath(digest)
            if (!path.isRegularFile()) return@withContext BlobResult.NotFound
            val size = path.fileSize()
            if (offset > size) return@withContext BlobResult.Invalid("Blob offset exceeds its size.")
            val requested = minOf(maximumBytes.toLong(), size - offset).toInt()
            val bytes = ByteArray(requested)
            FileChannel.open(path, StandardOpenOption.READ).use { channel ->
                channel.position(offset)
                var position = 0
                while (position < bytes.size) {
                    val read = channel.read(ByteBuffer.wrap(bytes, position, bytes.size - position))
                    if (read < 0) break
                    position += read
                }
            }
            BlobResult.Success(BlobChunk(offset, bytes, offset + bytes.size == size))
        }

    override suspend fun beginWrite(
        transfer: TransferId,
        expected: BlobMetadata,
    ): BlobResult<BlobWriteSession> =
        withContext(Dispatchers.IO) {
            if (expected.size !in 0..MAXIMUM_BLOB_SIZE) {
                return@withContext BlobResult.Invalid("Blob exceeds the maximum accepted size.")
            }
            val final = blobPath(expected.digest)
            if (final.isRegularFile()) {
                return@withContext BlobResult.Success(BlobWriteSession(transfer, expected, expected.size))
            }
            val directory = transferPath(transfer)
            directory.createDirectories()
            val metadata = directory.resolve("metadata.properties")
            val payload = directory.resolve("payload")
            if (metadata.exists()) {
                val current = readTransfer(transfer) ?: return@withContext BlobResult.Invalid("Transfer metadata is invalid.")
                if (current.expected != expected) {
                    return@withContext BlobResult.Conflict("Transfer id already belongs to different content.")
                }
                touch(metadata)
                return@withContext BlobResult.Success(current)
            }
            writeMetadata(metadata, expected)
            FileChannel.open(payload, StandardOpenOption.CREATE_NEW, StandardOpenOption.WRITE).use { }
            BlobResult.Success(BlobWriteSession(transfer, expected, 0))
        }

    override suspend fun write(
        transfer: TransferId,
        offset: Long,
        bytes: ByteArray,
    ): BlobResult<Long> =
        withContext(Dispatchers.IO) {
            if (bytes.size > MAXIMUM_CHUNK_SIZE) {
                return@withContext BlobResult.Invalid("Blob chunk exceeds the maximum accepted size.")
            }
            val session = readTransfer(transfer) ?: return@withContext BlobResult.NotFound
            if (offset != session.offset) {
                return@withContext BlobResult.Conflict("Blob chunk offset differs from the persisted offset.")
            }
            if (offset + bytes.size > session.expected.size) {
                return@withContext BlobResult.Invalid("Blob chunk exceeds the expected size.")
            }
            val payload = transferPath(transfer).resolve("payload")
            FileChannel.open(payload, StandardOpenOption.WRITE).use { channel ->
                channel.position(offset)
                val buffer = ByteBuffer.wrap(bytes)
                while (buffer.hasRemaining()) channel.write(buffer)
                channel.force(true)
            }
            touch(transferPath(transfer).resolve("metadata.properties"))
            BlobResult.Success(offset + bytes.size)
        }

    override suspend fun complete(transfer: TransferId): BlobResult<BlobMetadata> =
        telemetry.artifactSpan(
            "artifact.blob.transfer",
            "artifact-blob-transfer-failed",
        ) { span ->
            withContext(Dispatchers.IO) {
                val session = readTransfer(transfer) ?: return@withContext BlobResult.NotFound
                span?.annotate {
                    attribute("blob.digest", session.expected.digest.value)
                    attribute("blob.bytes", session.expected.size)
                }
                if (session.offset != session.expected.size) {
                    return@withContext BlobResult.Conflict("Transfer is incomplete.")
                }
                val payload = transferPath(transfer).resolve("payload")
                val actual = digest(payload)
                if (actual != session.expected.digest) {
                    return@withContext BlobResult.Invalid("Transfer digest differs from the expected digest.")
                }
                val target = blobPath(actual)
                target.parent.createDirectories()
                if (!target.exists()) moveAtomically(payload, target)
                Files.deleteIfExists(payload)
                Files.deleteIfExists(transferPath(transfer).resolve("metadata.properties"))
                Files.deleteIfExists(transferPath(transfer))
                BlobResult.Success(session.expected)
            }
        }

    suspend fun removeExpiredTransfers(): Int =
        withContext(Dispatchers.IO) {
            val expiredBefore = clock.instant().minus(transferLease)
            var removed = 0
            Files.list(transfers).use { entries ->
                entries.filter(Files::isDirectory).forEach { directory ->
                    val metadata = directory.resolve("metadata.properties")
                    if (!metadata.exists() || Files.getLastModifiedTime(metadata).toInstant().isBefore(expiredBefore)) {
                        Files.walk(directory).sorted(Comparator.reverseOrder()).forEach(Files::deleteIfExists)
                        removed++
                    }
                }
            }
            removed
        }

    suspend fun activeTransferDigests(): Set<ArtifactDigest> =
        withContext(Dispatchers.IO) {
            Files.list(transfers).use { entries ->
                entries
                    .filter(Files::isDirectory)
                    .toList()
                    .mapNotNull { directory ->
                        runCatching {
                            readTransfer(TransferId(directory.fileName.toString()))?.expected?.digest
                        }.getOrNull()
                    }.toSet()
            }
        }

    suspend fun collectGarbage(
        protected: Set<ArtifactDigest>,
        gracePeriod: Duration = Duration.ofDays(7),
    ): Int =
        withContext(Dispatchers.IO) {
            val protectedValues = protected.mapTo(mutableSetOf()) { it.value }
            val expiredBefore = clock.instant().minus(gracePeriod)
            var removed = 0
            Files.walk(blobs).use { paths ->
                paths
                    .filter(Files::isRegularFile)
                    .filter { file -> file.parent.fileName.toString() + file.fileName.toString() !in protectedValues }
                    .filter { file -> Files.getLastModifiedTime(file).toInstant().isBefore(expiredBefore) }
                    .forEach { file ->
                        Files.deleteIfExists(file)
                        removed++
                    }
            }
            removed
        }

    fun pathFor(digest: ArtifactDigest): Path = blobPath(digest)

    private fun blobPath(digest: ArtifactDigest): Path = blobs.resolve(digest.value.take(2)).resolve(digest.value.drop(2))

    private fun transferPath(transfer: TransferId): Path {
        require(transfer.value.matches(Regex("[0-9a-fA-F]{8}(?:-[0-9a-fA-F]{4}){3}-[0-9a-fA-F]{12}"))) {
            "Transfer id must be a UUID."
        }
        return transfers.resolve(transfer.value)
    }

    private fun readTransfer(transfer: TransferId): BlobWriteSession? {
        val directory = transferPath(transfer)
        val metadata = directory.resolve("metadata.properties")
        val payload = directory.resolve("payload")
        if (!metadata.isRegularFile() || !payload.isRegularFile()) return null
        val properties = Properties().also { values -> metadata.inputStream().use(values::load) }
        val digest =
            runCatching {
                ArtifactDigest(
                    DigestAlgorithm.valueOf(properties.getProperty("algorithm")),
                    properties.getProperty("digest"),
                )
            }.getOrNull() ?: return null
        val size = properties.getProperty("size")?.toLongOrNull() ?: return null
        return BlobWriteSession(transfer, BlobMetadata(digest, size), payload.fileSize())
    }

    private fun writeMetadata(
        path: Path,
        expected: BlobMetadata,
    ) {
        val properties =
            Properties().apply {
                setProperty("algorithm", expected.digest.algorithm.name)
                setProperty("digest", expected.digest.value)
                setProperty("size", expected.size.toString())
            }
        path.outputStream(StandardOpenOption.CREATE_NEW).use { properties.store(it, null) }
    }

    private fun digest(path: Path): ArtifactDigest {
        val messageDigest = MessageDigest.getInstance("SHA-256")
        DigestInputStream(path.inputStream(), messageDigest).use { input ->
            val buffer = ByteArray(DEFAULT_CHUNK_SIZE)
            var read = input.read(buffer)
            while (read >= 0) {
                read = input.read(buffer)
            }
        }
        return ArtifactDigest(DigestAlgorithm.SHA_256, messageDigest.digest().joinToString("") { "%02x".format(it) })
    }

    private fun moveAtomically(
        source: Path,
        target: Path,
    ) {
        try {
            Files.move(source, target, StandardCopyOption.ATOMIC_MOVE)
        } catch (_: AtomicMoveNotSupportedException) {
            Files.move(source, target)
        }
    }

    private fun touch(path: Path) {
        Files.setLastModifiedTime(
            path,
            java.nio.file.attribute.FileTime
                .from(Instant.now(clock)),
        )
    }
}
