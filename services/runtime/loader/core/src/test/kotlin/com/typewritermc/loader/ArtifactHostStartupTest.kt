package com.typewritermc.loader

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.artifact.ArtifactInboxReconciler
import com.typewritermc.loader.artifact.FileCandidateRepository
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.rollout.ArtifactHost
import com.typewritermc.loader.rollout.ArtifactHostAssignmentSource
import com.typewritermc.loader.testing.StartupLoaderService
import com.typewritermc.loader.testing.startupEngineManifest
import com.typewritermc.loader.testing.writeStartupJar
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.registrar.ServiceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.test.runTest
import java.nio.file.Files
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
                        StartupLoaderService(artifactsRoot),
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
