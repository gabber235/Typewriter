package com.typewritermc.loader

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.artifact.ArtifactInboxReconciler
import com.typewritermc.loader.artifact.FileCandidateRepository
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.rollout.ArtifactHost
import com.typewritermc.loader.rollout.ArtifactHostAssignmentSource
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.registrar.RegistrarStopResult
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.test.runTest
import java.nio.file.Files
import java.nio.file.Path
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlin.time.Duration

val ArtifactHostStartupTest by testSuite {
    test("first assignment observes every valid inbox replacement at startup") {
        runTest {
            val workDirectory = Files.createTempDirectory("typewriter-host-startup")
            val artifactsRoot = workDirectory.resolve("artifacts")
            val manifests =
                listOf(
                    RealmManifest(
                        id = ArtifactId("typewritermc:realm"),
                        version = ArtifactVersion("1.0.0"),
                        hostApi = VersionConstraint("^1"),
                        runtimeEntrypointClass = "fixture.Runtime",
                        contributions = emptyList(),
                    ),
                    startupEngineManifest("typewritermc:paper"),
                    startupEngineManifest("typewritermc:panel"),
                )
            val jars = manifests.associateWith { artifactsRoot.resolve("inbox/manual/${it.id.value.substringAfter(':')}.jar") }
            var host: ArtifactHost? = null
            try {
                jars.forEach { (manifest, path) -> writeStartupJar(path, manifest, "older content") }
                val candidates = FileCandidateRepository(artifactsRoot)
                ArtifactInboxReconciler(
                    artifactsRoot,
                    FileDigestBlobStore(artifactsRoot),
                    candidates,
                    Duration.ZERO,
                ).reconcile()
                val olderDigests = candidates.candidates().associate { it.manifest.id to it.artifact.digest }

                jars.forEach { (manifest, path) -> writeStartupJar(path, manifest, "replacement content") }
                val replacementDigests = jars.mapKeys { it.key.id }.mapValues { ArtifactDigest.sha256(Files.readAllBytes(it.value)) }
                replacementDigests.forEach { (id, digest) -> digest shouldNotBe olderDigests.getValue(id) }

                val firstAssignmentDigests = CompletableDeferred<Map<ArtifactId, ArtifactDigest>>()
                host =
                    ArtifactHost(
                        ServiceId("host"),
                        workDirectory,
                        StartupLoaderService(),
                        ArtifactHostAssignmentSource {
                            flow {
                                firstAssignmentDigests.complete(
                                    FileCandidateRepository(artifactsRoot).candidates().associate { it.manifest.id to it.artifact.digest },
                                )
                            }
                        },
                        backgroundScope,
                    )

                host.start()

                firstAssignmentDigests.await() shouldBe replacementDigests
            } finally {
                host?.stop()
                workDirectory.toFile().deleteRecursively()
            }
        }
    }
}

private fun startupEngineManifest(id: String): EngineManifest =
    EngineManifest(
        id = ArtifactId(id),
        version = ArtifactVersion("1.0.0"),
        hostApi = VersionConstraint("^1"),
        runtimeEntrypointClass = "fixture.Runtime",
        directCapabilities = emptyList(),
        resolvedCapabilities = emptyList(),
        bundledComponents = emptyList(),
        contributions = emptyList(),
    )

private fun writeStartupJar(
    path: Path,
    manifest: ImprintManifest,
    content: String,
) {
    Files.createDirectories(path.parent)
    ZipOutputStream(Files.newOutputStream(path)).use { archive ->
        archive.putNextEntry(ZipEntry(IMPRINT_MANIFEST_PATH))
        archive.write(ImprintManifestCodec.encode(manifest))
        archive.closeEntry()
        archive.putNextEntry(ZipEntry("fixture.txt"))
        archive.write(content.encodeToByteArray())
        archive.closeEntry()
    }
}

private class StartupLoaderService : LoaderService {
    override val states = MutableStateFlow(RegistrarSnapshot(0, 0, RegistrarState.Idle))
    override val openTelemetry = OpenTelemetry.noop()
    override val telemetry = openTelemetry.serviceTelemetry("host-startup-test")

    override suspend fun start(): Nothing = error("The bootstrap owns service startup.")

    override suspend fun communicatorFor(connectionGeneration: Long): Nothing = error("No messaging session is needed.")

    override suspend fun rotateAuthorization(): Nothing = error("No assignment is applied.")

    override suspend fun releaseAuthorizationRotation(connectionGeneration: Long): Nothing = error("No authorization was rotated.")

    override fun sharedArtifacts(realmId: String): Nothing = error("No runtime is assigned.")

    override suspend fun stop(): RegistrarStopResult = RegistrarStopResult.Success
}
