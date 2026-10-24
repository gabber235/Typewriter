package com.typewritermc.loader.artifact

import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.CapabilityManifest
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.archive.ImprintArchive
import com.typewritermc.loader.artifactSpan
import com.typewritermc.loader.deployment.ArtifactCandidate
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.DigestAlgorithm
import com.typewritermc.services.libs.filetransfer.blob.requireStored
import com.typewritermc.services.libs.telemetry.EventProjection
import com.typewritermc.services.libs.telemetry.LogSeverity
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import java.nio.file.Files
import java.nio.file.Path
import java.nio.file.StandardWatchEventKinds
import java.security.DigestInputStream
import java.security.MessageDigest
import java.util.concurrent.TimeUnit
import kotlin.io.path.createDirectories
import kotlin.io.path.fileSize
import kotlin.io.path.getLastModifiedTime
import kotlin.io.path.inputStream
import kotlin.io.path.isRegularFile
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

@kotlinx.serialization.Serializable
data class InboxDiagnostic(
    val relativePath: String,
    val reason: String,
)

/**
 * Captures filesystem metadata used to detect whether an inbox JAR remained stable between scans.
 *
 * Equal observations are a readiness heuristic. Import additionally hashes content and rechecks the observation
 * before accepting it.
 */
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

/**
 * Persists inbox acceptance, diagnostics, and import ordering independently of blob storage.
 *
 * Reserving an import revision and accepting a candidate are separate operations, so unused revisions are valid.
 * Presence tracking lets implementations defer removal of briefly missing files.
 */
interface CandidateRepository {
    suspend fun accepted(relativePath: String): AcceptedInboxCandidate?

    suspend fun reserveImportRevision(): Long

    suspend fun accept(candidate: AcceptedInboxCandidate)

    suspend fun updateObservation(observation: InboxObservation)

    suspend fun quarantine(diagnostic: InboxDiagnostic)

    suspend fun observePresence(relativePaths: Set<String>)
}

/**
 * Imports stable JARs from the manual inbox into immutable blob storage and the candidate index.
 *
 * Two observations separated by [stableDuration] must agree before import. Invalid imports become quarantine
 * diagnostics; accepted files are not moved. Capability JARs are rejected because only engines distribute
 * capabilities. Kinds that remote hosts fetch are rejected above [TRANSFERRED_BLOB_MAX_BYTES], so an oversized
 * artifact fails at import instead of at rollout; Realm JARs run on the host that imports them. [run] owns a watch service and also rescans periodically.
 */
class ArtifactInboxReconciler(
    artifactsRoot: Path,
    private val blobs: FileDigestBlobStore,
    private val candidates: CandidateRepository,
    private val stableDuration: Duration = 2.seconds,
    private val scanInterval: Duration = 30.seconds,
    private val telemetry: ServiceTelemetry? = null,
) {
    private val inbox = artifactsRoot.resolve("inbox").also(Path::createDirectories)
    private val manualInbox = inbox.resolve("manual").also(Path::createDirectories)

    /**
     * Performs one stability check and import pass, then reports observed presence to the repository.
     *
     * A failed replacement can leave a previously accepted candidate available. Cancellation propagates instead of
     * being recorded as a quarantine failure.
     */
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
            val outcomes = stable.mapValues { (path, observation) -> import(path, observation) }
            val imported = outcomes.filterValues { it == ImportOutcome.ACCEPTED }.keys.map(::relative)
            candidates.observePresence(after.keys.map { relative(it) }.toSet())
            span?.annotate {
                attribute("inbox.changed_count", imported.size.toLong())
                attribute("inbox.unstable_count", (after.size - stable.size).toLong())
                attribute("inbox.quarantined_count", outcomes.values.count { it == ImportOutcome.QUARANTINED }.toLong())
            }
            if (imported.isNotEmpty()) {
                span?.event(
                    "artifact.inbox.imported",
                    EventProjection.log(
                        LogSeverity.INFO,
                        "Imported ${imported.size} artifact(s) from the inbox: ${imported.joinToString()}",
                    ),
                ) {
                    attribute("inbox.changed_count", imported.size)
                    attribute("inbox.imported_paths", imported.joinToString())
                }
            }
        }

    suspend fun run() =
        withContext(Dispatchers.IO) {
            inbox.fileSystem.newWatchService().use { watchService ->
                listOf(inbox, manualInbox).forEach { directory ->
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
                    watchService.poll(scanInterval.inWholeMilliseconds, TimeUnit.MILLISECONDS)?.reset()
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
            require(kind == ArtifactKind.REALM || observation.size <= TRANSFERRED_BLOB_MAX_BYTES) {
                "${kind.name.lowercase()} artifacts are fetched by remote hosts and may not exceed $TRANSFERRED_BLOB_MAX_BYTES bytes."
            }
            ensureBlob(path, BlobMetadata(digest, observation.size))
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
            currentCoroutineContext().ensureActive()
            candidates.quarantine(InboxDiagnostic(relative, failure.message ?: failure::class.simpleName.orEmpty()))
            ImportOutcome.QUARANTINED
        }
    }

    /** Streams the file into the local store; existing content with this digest is not read again. */
    private suspend fun ensureBlob(
        source: Path,
        expected: BlobMetadata,
    ) {
        if (blobs.metadata(expected.digest) is BlobResult.Success) return
        blobs.import(source, expected).requireStored()
    }

    private fun scan(): Map<Path, InboxObservation> {
        if (!Files.isDirectory(manualInbox)) return emptyMap()
        return Files.walk(manualInbox).use { paths ->
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
            val buffer = ByteArray(DIGEST_BUFFER_SIZE)
            var read = input.read(buffer)
            while (read >= 0) read = input.read(buffer)
        }
        return ArtifactDigest(DigestAlgorithm.SHA_256, digest.digest().toHexString())
    }

    private fun readManifest(path: Path): ImprintManifest = ImprintArchive.require(path)
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

private const val DIGEST_BUFFER_SIZE = 256 * 1024
