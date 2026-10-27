package com.typewritermc.loader.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.imprint.CommonExtensionSourcePart
import com.typewritermc.imprint.EngineManifest
import com.typewritermc.imprint.ExtensionManifest
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.EngineImplementationArtifact
import com.typewritermc.loader.api.EngineImplementationTarget
import com.typewritermc.loader.api.HostedArtifact
import com.typewritermc.loader.api.HostedArtifactPackage
import com.typewritermc.loader.api.HostedDeploymentContext
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeEntrypoint
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.SourcePartDisposition
import com.typewritermc.loader.api.StagedHostedRuntime
import com.typewritermc.loader.artifact.ArtifactCoordinate
import com.typewritermc.loader.artifact.DeploymentArtifact
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.artifact.toSkir
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.ProjectedExtension
import com.typewritermc.loader.deployment.ProjectedRuntime
import com.typewritermc.loader.deployment.ProjectedSourcePart
import com.typewritermc.loader.rollout.HostRolloutParticipant
import com.typewritermc.loader.rollout.ProjectionSource
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.loader.rollout.VerifiedArtifactSource
import com.typewritermc.loader.rollout.toSkir
import com.typewritermc.loader.runtime.HostedRuntimeStager
import com.typewritermc.loader.runtime.LoadedHostedRuntime
import com.typewritermc.loader.shared.FileSharedArtifactRepository
import com.typewritermc.loader.shared.SharedArtifactService
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.registrar.ServiceId
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.test.TestScope
import skirout.service.v1.rollout.ApplyRolloutCommandRequest
import skirout.service.v1.rollout.ApplyRolloutCommandResponse
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.ParticipantProjection
import skirout.service.v1.rollout.ParticipantRollback
import skirout.service.v1.rollout.ParticipantStatus
import skirout.service.v1.rollout.ProjectionReference
import skirout.service.v1.rollout.RollbackTarget
import skirout.service.v1.rollout.RolloutAttempt
import skirout.service.v1.rollout.RolloutCommand
import java.net.URLClassLoader
import java.nio.file.FileSystems
import java.nio.file.Files
import java.nio.file.Path
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlin.time.Duration.Companion.seconds

class ParticipantFixture(
    val serviceId: ServiceId,
    val realmId: RealmId,
    val host: HostedRuntimeHost,
    val participant: HostRolloutParticipant,
    val projections: MutableMap<ProjectionReference, HostDeploymentProjection>,
    val stagedContexts: MutableList<HostedDeploymentContext>,
    val runtimes: MutableList<RecordingRuntime>,
    val events: MutableList<ParticipantStatus>,
    val root: Path,
) {
    val accepted = ApplyRolloutCommandResponse.createAccepted(serviceId = serviceId.value)

    fun failed(reason: String) = ApplyRolloutCommandResponse.createCommandFailedError(serviceId = serviceId.value, reason = reason)

    fun idle(attempt: RolloutAttempt) = ParticipantStatus(serviceId = serviceId.value, attempt = attempt, phase = ParticipantPhase.IDLE)

    fun reference(name: String) =
        ProjectionReference.partial(
            realmId = realmId.value,
            generation = name.length.toLong(),
            serviceId = serviceId.value,
            blob = ArtifactDigest.sha256(name.encodeToByteArray()).toSkir(),
        )

    fun stage(
        attempt: RolloutAttempt,
        reference: ProjectionReference,
    ) = request(attempt, RolloutCommand.createStage(participants = projections(reference)))

    fun commit(
        attempt: RolloutAttempt,
        reference: ProjectionReference,
    ) = request(attempt, RolloutCommand.createCommit(participants = projections(reference)))

    fun abort(
        attempt: RolloutAttempt,
        reference: ProjectionReference,
    ) = request(attempt, RolloutCommand.createAbort(participants = projections(reference)))

    fun rollback(
        attempt: RolloutAttempt,
        reference: ProjectionReference,
        target: RollbackTarget,
    ) = request(
        attempt,
        RolloutCommand.createRollBack(
            participants = listOf(ParticipantRollback(serviceId = serviceId.value, projection = reference, target = target)),
        ),
    )

    private fun projections(reference: ProjectionReference) =
        listOf(ParticipantProjection(serviceId = serviceId.value, projection = reference))

    private fun request(
        attempt: RolloutAttempt,
        command: RolloutCommand,
    ) = ApplyRolloutCommandRequest(attempt = attempt, command = command)

    fun engineManifest(entrypointClass: String) =
        EngineManifest(
            id = ArtifactId("typewritermc:paper"),
            version = ArtifactVersion("1.0.0"),
            hostApi = VersionConstraint("^1"),
            runtimeEntrypointClass = entrypointClass,
            directCapabilities = emptyList(),
            resolvedCapabilities = emptyList(),
            bundledComponents = emptyList(),
            contributions = emptyList(),
        )

    fun context(
        artifact: Path,
        manifest: EngineManifest,
    ) = HostedDeploymentContext(
        identity =
            com.typewritermc.loader.api.HostedRuntimeIdentity(
                serviceId.value,
                realmId.value,
                RuntimePlacement.PRIMARY_ENGINE,
            ),
        directories =
            com.typewritermc.loader.api.HostedRuntimeDirectories(
                root.resolve("state"),
                root.resolve("deployment"),
            ),
        artifacts = HostedArtifactPackage(HostedArtifact(artifact, manifest), emptyList(), emptyList()),
        publicationTarget = implementationTarget(manifest.id, manifest.version, ArtifactDigest.sha256("runtime".encodeToByteArray())),
        engineImplementation = implementationTarget(manifest.id, manifest.version, ArtifactDigest.sha256("runtime".encodeToByteArray())),
        facts = emptyMap(),
        host = host,
    )

    fun projection(
        reference: ProjectionReference,
        includeExtension: Boolean = false,
    ): HostDeploymentProjection {
        val runtime = artifact("typewritermc:paper", ArtifactKind.ENGINE, "runtime")
        val extensions =
            if (includeExtension) {
                listOf(
                    ProjectedExtension(
                        artifact("typewritermc:extension", ArtifactKind.EXTENSION, "extension"),
                        listOf(
                            ProjectedSourcePart(
                                "paper",
                                SourcePartDisposition.Eligible(setOf(RuntimePlacement.PRIMARY_ENGINE)),
                            ),
                            ProjectedSourcePart(
                                "panel",
                                SourcePartDisposition.Eligible(setOf(RuntimePlacement.PANEL_ENGINE)),
                            ),
                        ),
                    ),
                )
            } else {
                emptyList()
            }
        val implementation = implementationTarget(runtime.coordinate.id, runtime.coordinate.version, runtime.digest)
        return HostDeploymentProjection(
            realmId.value,
            DeploymentGeneration(reference.generation),
            serviceId,
            listOf(ProjectedRuntime.primaryEngine(runtime).copy(implementation = implementation)),
            extensions,
            implementation,
            emptyMap(),
        )
    }

    private fun artifact(
        id: String,
        kind: ArtifactKind,
        content: String,
    ): DeploymentArtifact {
        val bytes = content.encodeToByteArray()
        return DeploymentArtifact(
            ArtifactCoordinate(ArtifactId(id), ArtifactVersion("1.0.0")),
            kind,
            ArtifactDigest.sha256(bytes),
            bytes.size.toLong(),
        )
    }
}

fun implementationTarget(
    id: ArtifactId,
    version: ArtifactVersion,
    digest: ArtifactDigest,
) = EngineImplementationTarget(
    placement = RuntimePlacement.PRIMARY_ENGINE,
    engine =
        EngineImplementationArtifact(
            id,
            version,
            digest,
            emptyList(),
        ),
    extensions = emptyList(),
)

fun participantFixture(scope: TestScope): ParticipantFixture {
    val root = Files.createTempDirectory("participant")
    val serviceId = ServiceId("service")
    val realmId = RealmId("realm")
    val projections = mutableMapOf<ProjectionReference, HostDeploymentProjection>()
    val contexts = mutableListOf<HostedDeploymentContext>()
    val runtimes = mutableListOf<RecordingRuntime>()
    val events = mutableListOf<ParticipantStatus>()
    val blobs = FileDigestBlobStore(root)
    val shared = SharedArtifactService(realmId.value, blobs, FileSharedArtifactRepository(root.resolve("shared.cbor")))
    val host =
        object : HostedRuntimeHost {
            override val messaging: StateFlow<HostedMessagingSession?> = MutableStateFlow(null)
            override val openTelemetry: OpenTelemetry = OpenTelemetry.noop()
            override val sharedArtifacts = shared
        }
    val stager =
        HostedRuntimeStager { context ->
            contexts += context
            val runtime = RecordingRuntime()
            runtimes += runtime
            LoadedHostedRuntime(runtime, URLClassLoader(emptyArray<java.net.URL>()))
        }
    val participant =
        HostRolloutParticipant(
            realmId,
            serviceId,
            root,
            host,
            object : ProjectionSource {
                override suspend fun fetch(reference: ProjectionReference) = projections.getValue(reference)
            },
            object : VerifiedArtifactSource {
                override suspend fun fetch(digest: ArtifactDigest): Path =
                    root.resolve(digest.value).also { path ->
                        if (Files.notExists(path)) {
                            val manifest =
                                if (digest == ArtifactDigest.sha256("extension".encodeToByteArray())) {
                                    ExtensionManifest(
                                        id = ArtifactId("typewritermc:extension"),
                                        version = ArtifactVersion("1.0.0"),
                                        sourceParts = listOf(CommonExtensionSourcePart),
                                        buildProvenance = emptyList(),
                                        contributions = emptyList(),
                                    )
                                } else {
                                    EngineManifest(
                                        id = ArtifactId("typewritermc:paper"),
                                        version = ArtifactVersion("1.0.0"),
                                        hostApi = VersionConstraint("^1"),
                                        runtimeEntrypointClass = "fixture.Runtime",
                                        directCapabilities = emptyList(),
                                        resolvedCapabilities = emptyList(),
                                        bundledComponents = emptyList(),
                                        contributions = emptyList(),
                                    )
                                }
                            Files.createDirectories(path.parent)
                            ZipOutputStream(Files.newOutputStream(path)).use { archive ->
                                archive.putNextEntry(ZipEntry(IMPRINT_MANIFEST_PATH))
                                archive.write(ImprintManifestCodec.encode(manifest))
                                archive.closeEntry()
                            }
                        }
                    }
            },
            { status -> events += status },
            scope,
            stager,
            1.seconds,
        )
    return ParticipantFixture(serviceId, realmId, host, participant, projections, contexts, runtimes, events, root)
}

fun attempt(
    ordinal: Long,
    generation: Long,
) = RolloutAttempt(ordinal = ordinal, generation = generation)

val ParticipantStatus.activeProjection: ProjectionReference?
    get() = (phase as? ParticipantPhase.ActiveWrapper)?.value?.current?.projection

class TestHostedRuntimeEntrypoint : HostedRuntimeEntrypoint {
    override suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime = RecordingRuntime().also { stagedRuntime = it }

    companion object {
        var stagedRuntime: StagedHostedRuntime? = null
    }
}

class NoZeroArgumentHostedRuntimeEntrypoint(
    private val marker: String,
) : HostedRuntimeEntrypoint {
    override suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime = error(marker)
}

class ThrowingHostedRuntimeEntrypoint : HostedRuntimeEntrypoint {
    override suspend fun stage(context: HostedDeploymentContext): StagedHostedRuntime {
        StagingLoaders.last = javaClass.classLoader
        error("fixture stage failure")
    }
}

/** The class loader that defined the entrypoint that staged last; the parent loader shares it with runtime JARs. */
object StagingLoaders {
    @Volatile
    var last: ClassLoader? = null
}

const val RUNTIME_MARKER = "fixture/runtime-marker.txt"

/**
 * Writes a runtime JAR holding the compiled classes of [entrypoint] and a marker resource. The classes are read
 * where the class loader found them, a class directory or a fixtures JAR.
 */
fun writeRuntimeJar(
    artifact: Path,
    entrypoint: Class<*>,
) {
    val location = entrypoint.getResource("${entrypoint.simpleName}.class")!!.toURI()
    val packagePath = entrypoint.packageName.replace('.', '/')
    (if (location.scheme == "jar") FileSystems.newFileSystem(location, emptyMap<String, Any>()) else null).use {
        val compiled = Path.of(location).parent
        ZipOutputStream(Files.newOutputStream(artifact)).use { archive ->
            Files.list(compiled).use { files ->
                files.filter { it.fileName.toString().startsWith(entrypoint.simpleName) }.forEach { file ->
                    archive.putNextEntry(ZipEntry("$packagePath/${file.fileName}"))
                    archive.write(Files.readAllBytes(file))
                    archive.closeEntry()
                }
            }
            archive.putNextEntry(ZipEntry(RUNTIME_MARKER))
            archive.write("runtime".encodeToByteArray())
            archive.closeEntry()
        }
    }
}

/** A parent that cannot see [hidden], so the runtime JAR's own loader defines it. */
class ParentHiding(
    private val hidden: Class<*>,
) : ClassLoader(hidden.classLoader) {
    override fun loadClass(
        name: String,
        resolve: Boolean,
    ): Class<*> {
        if (name.startsWith(hidden.name)) throw ClassNotFoundException(name)
        return super.loadClass(name, resolve)
    }
}

class RecordingRuntime : StagedHostedRuntime {
    val healthState = MutableStateFlow<RuntimeHealth>(RuntimeHealth.Staged)
    override val health: StateFlow<RuntimeHealth> = healthState
    val operations = mutableListOf<String>()
    val failOn = mutableSetOf<String>()
    val suspendOn = mutableSetOf<String>()

    override suspend fun activate() {
        operations += "activate"
        failIfRequested("activate")
        healthState.value = RuntimeHealth.Healthy
    }

    override suspend fun quiesce() {
        operations += "quiesce"
        failIfRequested("quiesce")
    }

    override suspend fun resume() {
        operations += "resume"
        failIfRequested("resume")
        healthState.value = RuntimeHealth.Healthy
    }

    override suspend fun close() {
        operations += "close"
        failIfRequested("close")
    }

    private suspend fun failIfRequested(operation: String) {
        if (operation in suspendOn) awaitCancellation()
        if (operation in failOn) error("Fixture $operation failure")
    }
}
