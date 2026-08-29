package com.typewritermc.loader.artifact

import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.CapabilityManifest
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.loader.api.artifact.BlobResult
import com.typewritermc.loader.artifactSpan
import com.typewritermc.loader.deployment.ArtifactCandidate
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardWatchEventKinds
import java.security.DigestInputStream
import java.security.MessageDigest
import java.time.Duration
import java.util.concurrent.TimeUnit
import java.util.zip.ZipFile
import kotlin.coroutines.coroutineContext
import kotlin.io.path.createDirectories
import kotlin.io.path.fileSize
import kotlin.io.path.getLastModifiedTime
import kotlin.io.path.inputStream
import kotlin.io.path.isRegularFile

@kotlinx.serialization.Serializable
data class InboxDiagnostic(
    val relativePath: String,
    val reason: String,
)

@kotlinx.serialization.Serializable
data class InboxObservation(
    val relativePath: String,
    val size: Long,
    val modifiedAtMillis: Long,
    val fileKey: String?,
)

@kotlinx.serialization.Serializable
data class AcceptedInboxCandidate(
    val observation: InboxObservation,
    val candidate: ArtifactCandidate,
)

interface CandidateRepository {
    suspend fun accepted(relativePath: String): AcceptedInboxCandidate?

    suspend fun reserveImportRevision(): Long

    suspend fun accept(candidate: AcceptedInboxCandidate)

    suspend fun updateObservation(observation: InboxObservation)

    suspend fun quarantine(diagnostic: InboxDiagnostic)

    suspend fun observePresence(relativePaths: Set<String>)
}

class ArtifactInboxReconciler(
    artifactsRoot: Path,
    private val blobs: BlobEndpoint,
    private val candidates: CandidateRepository,
    private val stableDuration: kotlin.time.Duration = kotlin.time.Duration.parse("2s"),
    private val scanInterval: Duration = Duration.ofSeconds(30),
    private val telemetry: ServiceTelemetry? = null,
) {
    private val inbox = artifactsRoot.resolve("inbox").also(Path::createDirectories)
    private val manualInbox = inbox.resolve("manual").also(Path::createDirectories)
    private val developmentInbox = inbox.resolve("development").also(Path::createDirectories)

    suspend fun reconcile() =
        telemetry.artifactSpan(
            "artifact.inbox.reconcile",
            "artifact-inbox-reconcile-failed",
        ) { span ->
            val initial = scan()
            if (initial.isNotEmpty()) delay(stableDuration)
            val after = scan()
            val stable =
                after.filter { (path, observation) ->
                    initial[path] == observation
                }
            val outcomes = stable.map { (path, observation) -> import(path, observation) }
            candidates.observePresence(after.keys.map { relative(it) }.toSet())
            span?.annotate {
                attribute("inbox.changed_count", outcomes.count { it == ImportOutcome.ACCEPTED }.toLong())
                attribute("inbox.unstable_count", (after.size - stable.size).toLong())
                attribute("inbox.quarantined_count", outcomes.count { it == ImportOutcome.QUARANTINED }.toLong())
            }
        }

    suspend fun run() =
        withContext(Dispatchers.IO) {
            inbox.fileSystem.newWatchService().use { watchService ->
                listOf(inbox, manualInbox, developmentInbox).forEach { directory ->
                    directory.register(
                        watchService,
                        StandardWatchEventKinds.ENTRY_CREATE,
                        StandardWatchEventKinds.ENTRY_MODIFY,
                        StandardWatchEventKinds.ENTRY_DELETE,
                        StandardWatchEventKinds.OVERFLOW,
                    )
                }
                reconcile()
                while (true) {
                    coroutineContext.ensureActive()
                    watchService.poll(scanInterval.toMillis(), TimeUnit.MILLISECONDS)?.reset()
                    reconcile()
                }
            }
        }

    private suspend fun import(
        path: Path,
        observation: InboxObservation,
    ): ImportOutcome {
        val relative = relative(path)
        val accepted = candidates.accepted(relative)
        if (accepted?.observation == observation) return ImportOutcome.UNCHANGED
        return try {
            val digest = digest(path)
            require(observation == observe(path)) { "Inbox artifact changed while it was being validated." }
            if (accepted?.candidate?.artifact?.digest == digest) {
                candidates.updateObservation(observation)
                return ImportOutcome.OBSERVATION_UPDATED
            }
            val manifest = readManifest(path)
            val kind = manifest.kind()
            require(kind != ArtifactKind.CAPABILITY) { "Capability JARs are accepted only as bundled engine content." }
            val metadata = BlobMetadata(digest, observation.size)
            ensureBlob(path, metadata)
            val revision = candidates.reserveImportRevision()
            candidates.accept(
                AcceptedInboxCandidate(
                    observation,
                    ArtifactCandidate(
                        artifact =
                            DeploymentArtifact(
                                ArtifactCoordinate(manifest.id, manifest.version),
                                kind,
                                digest,
                                observation.size,
                            ),
                        manifest = manifest,
                        provenance = ArtifactProvenance.LocalInbox(relative, revision),
                        importRevision = revision,
                    ),
                ),
            )
            ImportOutcome.ACCEPTED
        } catch (failure: Throwable) {
            coroutineContext.ensureActive()
            candidates.quarantine(InboxDiagnostic(relative, failure.message ?: failure::class.simpleName.orEmpty()))
            ImportOutcome.QUARANTINED
        }
    }

    private suspend fun ensureBlob(
        source: Path,
        expected: BlobMetadata,
    ) {
        if (blobs.metadata(expected.digest) is BlobResult.Success) return
        val transfer = TransferId.create()
        val session = blobs.beginWrite(transfer, expected).success()
        var offset = session.offset
        if (offset == expected.size && blobs.metadata(expected.digest) is BlobResult.Success) return
        source.inputStream().use { input ->
            input.skipNBytes(offset)
            val buffer = ByteArray(DEFAULT_CHUNK_SIZE)
            while (offset < expected.size) {
                val read = input.read(buffer)
                check(read >= 0) { "Inbox artifact ended before its declared size." }
                offset = blobs.write(transfer, offset, buffer.copyOf(read)).success()
            }
        }
        blobs.complete(transfer).success()
    }

    private fun scan(): Map<Path, InboxObservation> {
        if (!Files.isDirectory(inbox)) return emptyMap()
        return Files.walk(inbox).use { paths ->
            paths
                .filter { it.isRegularFile() && it.fileName.toString().endsWith(".jar") }
                .sorted()
                .toList()
                .associateWith(::observe)
        }
    }

    private fun observe(path: Path): InboxObservation =
        InboxObservation(
            relative(path),
            path.fileSize(),
            path.getLastModifiedTime().toMillis(),
            Files.readAttributes(path, java.nio.file.attribute.BasicFileAttributes::class.java).fileKey()?.toString(),
        )

    private fun relative(path: Path): String =
        inbox
            .relativize(path)
            .normalize()
            .toString()
            .replace('\\', '/')

    private fun digest(path: Path): ArtifactDigest {
        val digest = MessageDigest.getInstance("SHA-256")
        DigestInputStream(path.inputStream(), digest).use { input ->
            val buffer = ByteArray(DEFAULT_CHUNK_SIZE)
            var read = input.read(buffer)
            while (read >= 0) read = input.read(buffer)
        }
        return ArtifactDigest(DigestAlgorithm.SHA_256, digest.digest().joinToString("") { "%02x".format(it) })
    }

    private fun readManifest(path: Path): ImprintManifest =
        ZipFile(path.toFile()).use { archive ->
            val entry =
                requireNotNull(archive.getEntry(IMPRINT_MANIFEST_PATH)) {
                    "Inbox artifact does not contain $IMPRINT_MANIFEST_PATH."
                }
            ImprintManifestCodec.decode(archive.getInputStream(entry).readBytes())
        }
}

private enum class ImportOutcome {
    UNCHANGED,
    OBSERVATION_UPDATED,
    ACCEPTED,
    QUARANTINED,
}

private fun ImprintManifest.kind(): ArtifactKind =
    when (this) {
        is RealmManifest -> ArtifactKind.REALM
        is EngineManifest -> ArtifactKind.ENGINE
        is CapabilityManifest -> ArtifactKind.CAPABILITY
        is ExtensionManifest -> ArtifactKind.EXTENSION
    }

private fun <Value> BlobResult<Value>.success(): Value =
    when (this) {
        is BlobResult.Success -> value
        BlobResult.NotFound -> error("Blob operation could not find its target.")
        is BlobResult.Invalid -> error(reason)
        is BlobResult.Conflict -> error(reason)
    }
