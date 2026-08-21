package com.typewritermc.realm.deployment

import com.typewritermc.engine.EngineId
import com.typewritermc.engine.SemanticVersion
import com.typewritermc.loader.ChildKind
import com.typewritermc.loader.DeploymentContext
import com.typewritermc.loader.DesiredChild
import com.typewritermc.loader.UnavailableLoaderServiceConnection
import com.typewritermc.services.libs.filetransfer.FileChunk
import com.typewritermc.services.libs.filetransfer.FileKey
import com.typewritermc.services.libs.filetransfer.FileMetadata
import com.typewritermc.services.libs.filetransfer.FileTransferCoordinator
import com.typewritermc.services.libs.filetransfer.FileTransferEndpoint
import com.typewritermc.services.libs.filetransfer.FileTransferError
import com.typewritermc.services.libs.filetransfer.FileTransferResult
import com.typewritermc.services.libs.filetransfer.messaging.FileTransferMessageChannel
import com.typewritermc.services.libs.filetransfer.messaging.FileTransferMessageHandler
import com.typewritermc.services.libs.filetransfer.messaging.MessagingFileTransferEndpoint
import com.typewritermc.services.libs.filetransfer.storage.FileSystemFileTransferEndpoint
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.booleans.shouldBeFalse
import io.kotest.matchers.booleans.shouldBeTrue
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.test.runTest
import java.nio.file.Files
import java.time.Instant
import kotlin.time.Duration.Companion.milliseconds

val DeploymentManifestTest by testSuite {
    test("imports immutable artifacts and rejects replacement") {
        runTest {
            val repository = repository()
            val first = repository.import("typewritermc:realm", version, ArtifactKind.REALM, "first".encodeToByteArray())
            val replacement = repository.import("typewritermc:realm", version, ArtifactKind.REALM, "second".encodeToByteArray())

            first.shouldBeInstanceOf<ArtifactImportResult.Success>().reference.signature shouldBe "signed"
            replacement.shouldBeInstanceOf<ArtifactImportResult.Failure>()
        }
    }

    test("same host resolution verifies the mounted store without transfer") {
        runTest {
            val repository = repository()
            val reference = repository.importSuccess("typewritermc:paper", ArtifactKind.EXECUTION_ENGINE, "paper")
            val remote = CountingEndpoint(repository.endpoint)
            val cache = FileSystemFileTransferEndpoint(Files.createTempDirectory("realm-local-cache"))
            val resolver =
                ArtifactResolver(
                    providerHostId = "host",
                    consumerHostId = "host",
                    hostStore = repository.endpoint,
                    remoteSource = remote,
                    consumerCache = cache,
                    coordinator = FileTransferCoordinator(2),
                )

            val result = resolver.resolve(reference).shouldBeInstanceOf<ArtifactResolutionResult.Success>()

            result.artifact.local.shouldBeTrue()
            result.artifact.endpoint shouldBe repository.endpoint
            remote.calls shouldBe 0
        }
    }

    test("different hosts transfer into the verified consumer cache") {
        runTest {
            val repository = repository()
            val reference = repository.importSuccess("typewritermc:paper", ArtifactKind.EXECUTION_ENGINE, "remote-paper")
            val handler = FileTransferMessageHandler(repository.endpoint)
            var exchanges = 0
            val remote =
                MessagingFileTransferEndpoint(
                    FileTransferMessageChannel { payload ->
                        exchanges += 1
                        handler.handle(payload)
                    },
                )
            val cache = FileSystemFileTransferEndpoint(Files.createTempDirectory("realm-remote-cache"))
            val resolver =
                ArtifactResolver(
                    providerHostId = "realm-host",
                    consumerHostId = "paper-host",
                    hostStore = repository.endpoint,
                    remoteSource = remote,
                    consumerCache = cache,
                    coordinator = FileTransferCoordinator(3),
                )

            val result = resolver.resolve(reference).shouldBeInstanceOf<ArtifactResolutionResult.Success>()

            result.artifact.local.shouldBeFalse()
            (exchanges > 0).shouldBeTrue()
            cache.metadata(reference.key).shouldBeInstanceOf<FileTransferResult.Success<*>>()
        }
    }

    test("same host resolution hashes mounted bytes independently") {
        runTest {
            val repository = repository()
            val reference = repository.importSuccess("typewritermc:paper", ArtifactKind.EXECUTION_ENGINE, "paper")
            val resolver =
                ArtifactResolver(
                    providerHostId = "host",
                    consumerHostId = "host",
                    hostStore = CorruptReadEndpoint(repository.endpoint),
                    remoteSource = repository.endpoint,
                    consumerCache = repository.endpoint,
                    coordinator = FileTransferCoordinator(2),
                )

            resolver
                .resolve(reference)
                .shouldBeInstanceOf<ArtifactResolutionResult.Failure>()
                .error
                .shouldBeInstanceOf<FileTransferError.DigestMismatch>()
        }
    }

    test("production policy requires and verifies signatures") {
        runTest {
            val signed = repository().importSuccess("typewritermc:realm", ArtifactKind.REALM, "realm")
            val unsigned = signed.copy(signature = null)
            val valid = ManifestPolicy(false, ArtifactSignatureVerifier { true })
            val invalid = ManifestPolicy(false, ArtifactSignatureVerifier { false })

            valid.validate(unsigned).shouldBeInstanceOf<ManifestValidationResult.MissingSignature>()
            invalid.validate(signed).shouldBeInstanceOf<ManifestValidationResult.InvalidSignature>()
            valid.validate(signed) shouldBe ManifestValidationResult.Valid
        }
    }

    test("publishes Realm and execution manifests as one revision") {
        runTest {
            val repository = repository()
            val target = EngineId.of("paper")
            val publisher = ManifestPublisher()
            val manifests =
                publisher.publish(
                    RealmManifestDraft(
                        target,
                        1,
                        repository.importSuccess("typewritermc:realm", ArtifactKind.REALM, "realm"),
                        repository.importSuccess("typewritermc:panel", ArtifactKind.PANEL_ENGINE, "panel"),
                        emptyList(),
                        emptyList(),
                    ),
                    ExecutionManifestDraft(
                        target,
                        repository.importSuccess("typewritermc:paper", ArtifactKind.EXECUTION_ENGINE, "paper"),
                        emptyList(),
                        emptyList(),
                        emptyList(),
                    ),
                )

            manifests.realm.revision shouldBe 1
            manifests.execution.revision shouldBe 1
        }
    }

    test("development importer publishes only changed jar revisions") {
        runTest {
            val directory = Files.createTempDirectory("realm-import")
            val artifact = directory.resolve("typewritermc:paper__1.0.0__execution_engine.jar")
            Files.writeString(artifact, "first")
            val importer = DevelopmentArtifactImporter(directory, repository(), 10.milliseconds)

            importer.scan().map { it.artifact.key.id.value } shouldContainExactly listOf("typewritermc:paper")
            importer.scan() shouldBe emptyList()
        }
    }

    test("Realm deployment prepares its compatible checkpoint before stopping") {
        runTest {
            val events = mutableListOf<String>()
            val entrypoint =
                RealmDeploymentEntrypoint {
                    object : ManagedRealmRuntime {
                        override suspend fun prepareUpgradeCheckpoint(): RealmUpgradeCheckpoint {
                            events += "checkpoint"
                            return CompatibleNoOperationCheckpoint
                        }

                        override suspend fun stop() {
                            events += "stop"
                        }
                    }
                }
            val child = DesiredChild(ChildKind.REALM, "realm", "realm", 1)
            val runtime =
                entrypoint.start(
                    DeploymentContext(
                        "host",
                        Files.createTempDirectory("realm-runtime"),
                        child,
                        UnavailableLoaderServiceConnection,
                    ),
                )

            runtime.quiesce(Instant.now())
            runtime.stop()

            events shouldContainExactly listOf("checkpoint", "stop")
        }
    }
}

private class CountingEndpoint(
    private val delegate: FileTransferEndpoint,
) : FileTransferEndpoint by delegate {
    var calls = 0

    override suspend fun metadata(key: FileKey): FileTransferResult<FileMetadata> {
        calls += 1
        return delegate.metadata(key)
    }
}

private class CorruptReadEndpoint(
    private val delegate: FileTransferEndpoint,
) : FileTransferEndpoint by delegate {
    override suspend fun read(
        key: FileKey,
        offset: Long,
        maximumBytes: Int,
    ): FileTransferResult<FileChunk> =
        when (val result = delegate.read(key, offset, maximumBytes)) {
            is FileTransferResult.Failure -> {
                result
            }

            is FileTransferResult.Success -> {
                val bytes = result.value.bytes.copyOf()
                if (bytes.isNotEmpty()) bytes[0] = (bytes[0].toInt() xor 1).toByte()
                FileTransferResult.Success(FileChunk(result.value.offset, bytes))
            }
        }
}

private fun repository() =
    ImmutableArtifactRepository(
        FileSystemFileTransferEndpoint(Files.createTempDirectory("realm-artifacts")),
        ArtifactSigner { _, _ -> "signed" },
    )

private suspend fun ImmutableArtifactRepository.importSuccess(
    id: String,
    kind: ArtifactKind,
    contents: String,
): ArtifactReference =
    import(id, version, kind, contents.encodeToByteArray())
        .shouldBeInstanceOf<ArtifactImportResult.Success>()
        .reference

private val version = SemanticVersion.parse("1.0.0")
