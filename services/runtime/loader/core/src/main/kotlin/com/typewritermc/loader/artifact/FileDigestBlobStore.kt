package com.typewritermc.loader.artifact

import com.typewritermc.loader.api.artifact.PublicationBlobRetention
import com.typewritermc.loader.api.artifact.PublicationBlobRoots
import com.typewritermc.loader.artifactSpan
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobEndpoint
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.MAXIMUM_BLOB_SIZE
import com.typewritermc.services.libs.filetransfer.blob.StoreResult
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import java.io.OutputStream
import java.nio.file.AtomicMoveNotSupportedException
import java.nio.file.FileAlreadyExistsException
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardCopyOption
import java.security.DigestOutputStream
import java.security.MessageDigest
import java.time.Clock
import java.time.Duration
import java.util.concurrent.ConcurrentHashMap
import kotlin.io.path.createDirectories
import kotlin.io.path.fileSize
import kotlin.io.path.isRegularFile

/**
 * Stores immutable digest addressed blobs on disk.
 *
 * A store writes a temporary file beside the blobs, verifies size and SHA256, and only then moves it into place,
 * so a blob path never holds unverified content. Existing final files are trusted by metadata lookup rather than
 * rehashed; [fetch] rehashes what it reads, so corruption on disk surfaces as invalid instead of being served.
 * Callers coordinate collection with producers; IO dispatching does not provide mutual exclusion.
 */
class FileDigestBlobStore(
    root: Path,
    private val clock: Clock = Clock.systemUTC(),
    private val telemetry: ServiceTelemetry? = null,
) : BlobEndpoint {
    private val blobs = root.resolve("blobs").also(Path::createDirectories)
    private val incoming = root.resolve("incoming").also(Path::createDirectories)

    private val publicationGate = Mutex()
    private val requiredRealms = ConcurrentHashMap.newKeySet<String>()
    private val pins = FilePublicationPins(root.resolve("publication-pins.cbor"))

    fun publicationRetention(realmId: String): PublicationBlobRetention {
        requiredRealms.add(realmId)
        return object : PublicationBlobRetention {
            override suspend fun protect(
                publication: String,
                digests: Set<ArtifactDigest>,
            ) {
                publicationGate.withLock {
                    val all = pins.read()
                    val realm = checkNotNull(all[realmId]) { "Publication roots are not reconciled" }
                    val prior = realm.publications[publication]
                    check(prior == null || prior == digests) { "Publication bytes changed" }
                    pins.write(
                        all + (
                            realmId to
                                realm.copy(
                                    publications = realm.publications + (publication to digests),
                                )
                        ),
                    )
                }
            }

            override suspend fun selected(publication: String) {
                publicationGate.withLock {
                    val all = pins.read()
                    val realm = checkNotNull(all[realmId])
                    check(publication in realm.publications)
                    val retired = realm.selected?.takeIf { it != publication }
                    pins.write(
                        all + (
                            realmId to
                                RealmPublicationPins(
                                    selected = publication,
                                    publications = realm.publications.filterKeys { it != retired },
                                )
                        ),
                    )
                }
            }

            override suspend fun reconcile(selected: PublicationBlobRoots?) {
                publicationGate.withLock {
                    val all = pins.read()
                    val retained = selected?.let { mapOf(it.publication to it.digests) }.orEmpty()
                    pins.write(all + (realmId to RealmPublicationPins(selected?.publication, retained)))
                }
            }
        }
    }

    override suspend fun metadata(digest: ArtifactDigest): BlobResult<BlobMetadata> =
        withContext(Dispatchers.IO) {
            val path = blobPath(digest)
            if (!path.isRegularFile()) return@withContext BlobResult.NotFound
            BlobResult.Success(BlobMetadata(digest, path.fileSize()))
        }

    override suspend fun fetch(digest: ArtifactDigest): BlobResult<ByteArray> =
        withContext(Dispatchers.IO) {
            val path = blobPath(digest)
            if (!path.isRegularFile()) return@withContext BlobResult.NotFound
            val content = Files.readAllBytes(path)
            if (ArtifactDigest.sha256(content) != digest) return@withContext BlobResult.Invalid("Stored blob digest does not match.")
            BlobResult.Success(content)
        }

    override suspend fun store(
        expected: BlobMetadata,
        content: ByteArray,
    ): StoreResult = import(expected) { output -> output.write(content) }

    /** Imports a local file without loading it into memory; used for inbox artifacts above the transfer limit. */
    suspend fun import(
        path: Path,
        expected: BlobMetadata,
    ): StoreResult = import(expected) { output -> Files.newInputStream(path).use { it.copyTo(output) } }

    private suspend fun import(
        expected: BlobMetadata,
        write: (OutputStream) -> Unit,
    ): StoreResult =
        telemetry.artifactSpan("artifact.blob.store", "artifact-blob-store-failed") { span ->
            span?.annotate {
                attribute("blob.digest", expected.digest.value)
                attribute("blob.bytes", expected.size)
            }
            withContext(Dispatchers.IO) {
                if (expected.size !in 0..MAXIMUM_BLOB_SIZE) {
                    return@withContext StoreResult.Invalid("Blob exceeds the maximum accepted size.")
                }
                val target = blobPath(expected.digest)
                if (target.isRegularFile()) return@withContext verifiedExisting(target, expected)
                val temporary = Files.createTempFile(incoming, "blob", null)
                try {
                    val digest = MessageDigest.getInstance("SHA-256")
                    DigestOutputStream(Files.newOutputStream(temporary), digest).use(write)
                    val size = Files.size(temporary)
                    if (size != expected.size) {
                        return@withContext StoreResult.Invalid("Blob has $size bytes, expected ${expected.size}.")
                    }
                    if (digest.digest().toHexString() != expected.digest.value) {
                        return@withContext StoreResult.Invalid("Blob digest does not match.")
                    }
                    target.parent.createDirectories()
                    moveAtomically(temporary, target)
                    StoreResult.Stored(expected)
                } catch (_: FileAlreadyExistsException) {
                    verifiedExisting(target, expected)
                } finally {
                    Files.deleteIfExists(temporary)
                }
            }
        }

    /** A concurrent or earlier store already placed this digest; its size must agree with the expectation. */
    private fun verifiedExisting(
        target: Path,
        expected: BlobMetadata,
    ): StoreResult {
        val size = target.fileSize()
        return if (size == expected.size) {
            StoreResult.Stored(expected)
        } else {
            StoreResult.Invalid("Stored blob has $size bytes, expected ${expected.size}.")
        }
    }

    /**
     * Deletes old final blobs outside the supplied protection set, using modification time and [gracePeriod].
     *
     * This method does not discover deployment references. Supply all retention roots through
     * [DigestProtectionState] and coordinate concurrent publication.
     */
    suspend fun collectGarbage(
        protected: Set<ArtifactDigest>,
        gracePeriod: Duration = Duration.ofDays(7),
    ): Int =
        publicationGate.withLock {
            val retained = pins.read()
            if (!retained.keys.containsAll(requiredRealms)) return@withLock 0
            collectUnprotected(protected + retained.values.flatMap { it.digests }.toSet(), gracePeriod)
        }

    private suspend fun collectUnprotected(
        protected: Set<ArtifactDigest>,
        gracePeriod: Duration = Duration.ofDays(7),
    ): Int =
        withContext(Dispatchers.IO) {
            val protectedValues = protected.mapTo(mutableSetOf()) { it.value }
            val expiredBefore = clock.instant().minus(gracePeriod)
            // A store deletes its temporary file itself; only a process that died mid store leaves one behind.
            Files.list(incoming).use { files ->
                files
                    .filter { file -> Files.getLastModifiedTime(file).toInstant().isBefore(expiredBefore) }
                    .forEach(Files::deleteIfExists)
            }
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

    /**
     * Returns the digest storage path without checking existence or integrity.
     *
     * Establish blob availability before opening this path.
     */
    fun pathFor(digest: ArtifactDigest): Path = blobPath(digest)

    private fun blobPath(digest: ArtifactDigest): Path = blobs.resolve(digest.value.take(2)).resolve(digest.value.drop(2))

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
}
