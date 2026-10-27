package com.typewritermc.loader.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.artifact.ProducerMetadata
import com.typewritermc.loader.api.artifact.PublishSharedArtifact
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.shared.FileSharedArtifactRepository
import com.typewritermc.loader.shared.SharedArtifactService
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.filetransfer.blob.BlobResult
import com.typewritermc.services.libs.filetransfer.blob.StoreResult
import com.typewritermc.services.libs.registrar.ServiceId
import io.kotest.matchers.shouldBe
import skirout.kernel.v1.record_id.RecordId
import skirout.kernel.v1.record_id.RecordIdKey
import skirout.service.v1.rollout.ActiveProjection
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.ParticipantStatus
import skirout.service.v1.rollout.ProjectionHealth
import skirout.service.v1.rollout.ProjectionReference
import skirout.service.v1.rollout.RolloutAttempt
import java.nio.file.Files
import java.nio.file.Path
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream

fun record(
    table: String,
    key: String,
): RecordId = RecordId(table = table, key = RecordIdKey.StringWrapper(key))

fun <Value> BlobResult<Value>.shouldSucceed(): Value =
    when (this) {
        is BlobResult.Success -> value
        else -> error("Expected a successful blob result but received $this.")
    }

fun writeArtifactJar(
    path: Path,
    manifest: com.typewritermc.imprint.ImprintManifest,
) {
    Files.createDirectories(path.parent)
    ZipOutputStream(Files.newOutputStream(path)).use { archive ->
        archive.putNextEntry(ZipEntry(IMPRINT_MANIFEST_PATH))
        archive.write(ImprintManifestCodec.encode(manifest))
        archive.closeEntry()
    }
}

fun status(
    attempt: RolloutAttempt,
    host: ServiceId,
    phase: ParticipantPhase,
) = ParticipantStatus(serviceId = host.value, attempt = attempt, phase = phase)

fun active(reference: ProjectionReference) =
    ParticipantPhase.createActive(current = ActiveProjection(projection = reference, health = ProjectionHealth.HEALTHY), retained = null)

fun realmManifest() =
    RealmManifest(
        id = ArtifactId("typewritermc:realm"),
        version = ArtifactVersion("1.0.0"),
        hostApi = VersionConstraint("^1"),
        runtimeEntrypointClass = "fixture.Runtime",
        contributions = emptyList(),
    )

/** A Realm shared artifact service over a fresh store that already holds the bytes of its command. */
suspend fun sharedPublication() = SharedPublicationFixture().also { it.storeContent() }

class SharedPublicationFixture {
    private val root = Files.createTempDirectory("typewriter-shared")
    private val blobs = FileDigestBlobStore(root)
    val service = SharedArtifactService("realm", blobs, FileSharedArtifactRepository(root.resolve("shared.cbor")))
    private val bytes = "road network".encodeToByteArray()
    val command =
        PublishSharedArtifact(
            SharedArtifactId("019d1f6c-1d2e-7249-9fa3-86964e89721d"),
            null,
            "Road network",
            "application/vnd.typewriter.road-network",
            BlobMetadata(ArtifactDigest.sha256(bytes), bytes.size.toLong()),
            ProducerMetadata(mapOf("world" to "main")),
            SharedArtifactProvenance.HostedRuntime("paper", "primary"),
        )

    suspend fun storeContent() {
        blobs.store(command.blob, bytes) shouldBe StoreResult.Stored(command.blob)
    }

    /** The catalog a new process reads from the same file. */
    suspend fun restartedCatalog() = FileSharedArtifactRepository(root.resolve("shared.cbor")).catalog()
}

/** A shared artifact access that delegates to [service] but fails every fetch, so a test can show that no bytes are read. */
class FetchForbiddenSharedArtifactAccess(
    service: SharedArtifactAccess,
) : SharedArtifactAccess by service {
    override suspend fun fetch(digest: ArtifactDigest): BlobResult<ByteArray> = error("An oversized blob must not be read")
}
