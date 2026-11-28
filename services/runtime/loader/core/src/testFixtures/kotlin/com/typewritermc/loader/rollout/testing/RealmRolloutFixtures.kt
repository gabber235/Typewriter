package com.typewritermc.loader.rollout.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.IMPRINT_MANIFEST_PATH
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.ImprintManifestCodec
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.api.StagedHostedRuntime
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.deployment.DeploymentContent
import com.typewritermc.loader.deployment.DeploymentContentCodec
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.loader.deployment.RealmDeploymentSelection
import com.typewritermc.loader.deployment.ResolutionResult
import com.typewritermc.loader.rollout.BlobProjectionRepository
import com.typewritermc.loader.rollout.DeploymentContents
import com.typewritermc.loader.rollout.FileRolloutStateRepository
import com.typewritermc.loader.rollout.HostRolloutParticipant
import com.typewritermc.loader.rollout.PresenceProbe
import com.typewritermc.loader.rollout.ProbedRealmMembership
import com.typewritermc.loader.rollout.ProjectionSource
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.loader.rollout.RealmRollout
import com.typewritermc.loader.rollout.RolloutMessenger
import com.typewritermc.loader.rollout.RolloutTimings
import com.typewritermc.loader.rollout.VerifiedArtifactSource
import com.typewritermc.loader.rollout.commandKind
import com.typewritermc.loader.rollout.projectionOf
import com.typewritermc.loader.rollout.serviceIds
import com.typewritermc.loader.rollout.toSkir
import com.typewritermc.loader.runtime.HostedRuntimeStager
import com.typewritermc.loader.runtime.LoadedHostedRuntime
import com.typewritermc.loader.shared.FileSharedArtifactRepository
import com.typewritermc.loader.shared.SharedArtifactService
import com.typewritermc.loader.testing.FIXTURE_VERSION
import com.typewritermc.loader.testing.deploymentArtifact
import com.typewritermc.loader.testing.engineManifest
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.InMemoryBlobEndpoint
import com.typewritermc.services.libs.registrar.ServiceId
import io.opentelemetry.api.OpenTelemetry
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import skirout.service.v1.rollout.ApplyRolloutCommandRequest
import skirout.service.v1.rollout.ApplyRolloutCommandResponse
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.ParticipantStatus
import skirout.service.v1.rollout.ProjectionReference
import skirout.service.v1.rollout.QueryParticipantStatusRequest
import skirout.service.v1.rollout.RealmHostPresence
import skirout.service.v1.rollout.RolloutAttempt
import skirout.service.v1.rollout.RolloutCommandKind
import java.net.URL
import java.net.URLClassLoader
import java.nio.file.Files
import java.nio.file.Path
import java.util.zip.ZipEntry
import java.util.zip.ZipOutputStream
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

private val REALM = RealmId("realm")

/**
 * One host of a Realm: a real [HostRolloutParticipant] that the rollout reaches through messaging. The participant
 * stages fixture runtimes whose health and failures the test sets; [restart] replaces it with an empty one, as a new
 * process of the host does.
 */
class RealmHost internal constructor(
    val id: ServiceId,
    val roles: Set<RuntimePlacement>,
    private val scope: CoroutineScope,
    private val projections: ProjectionSource,
    private val artifacts: VerifiedArtifactSource,
) {
    /** Every command that reached the host, in order. */
    val commands = mutableListOf<ApplyRolloutCommandRequest>()

    /** Every projection the host switched to running, in order; null when it went back to running nothing. */
    val switches = mutableListOf<ProjectionReference?>()

    /** Whether the host answers at all; a host that left the Realm or lost its connection answers nothing. */
    var responding = true

    /** Decides per presence probe whether the host's answer arrives. */
    var answersProbe: () -> Boolean = { true }

    /** Decides per status query whether the host's reply arrives. */
    var answersStatus: (ParticipantStatus) -> Boolean = { true }

    /** How long a command takes to reach the participant. */
    var commandDuration: Duration = Duration.ZERO

    /** Whether staging a runtime fails, as a host that cannot load the candidate does. */
    var failsStaging = false

    /** Whether activating a staged runtime fails, as a host whose new projection does not start does. */
    var failsActivation = false

    /** The health every running runtime of the host reports. */
    var health: RuntimeHealth = RuntimeHealth.Healthy
        set(value) {
            field = value
            runtimes.forEach(FixtureRuntime::refresh)
        }

    private val root = Files.createTempDirectory("typewriter-host")
    private val hosted =
        object : HostedRuntimeHost {
            override val messaging: StateFlow<HostedMessagingSession?> = MutableStateFlow(null)
            override val openTelemetry: OpenTelemetry = OpenTelemetry.noop()
            override val sharedArtifacts =
                SharedArtifactService(
                    REALM.value,
                    FileDigestBlobStore(root.resolve("blobs")),
                    FileSharedArtifactRepository(root.resolve("shared.cbor")),
                )
        }
    private var runtimes = mutableListOf<FixtureRuntime>()
    private var process = 0
    private var running: ProjectionReference? = null
    private var participant = start()

    val commandKinds: List<RolloutCommandKind> get() = commands.map { it.command.commandKind }

    /** The projection the host runs, or null while it runs nothing. */
    val runningProjection: ProjectionReference? get() = running

    /** The deployment generation of the projection the host runs, or null while it runs nothing. */
    val generation: Long? get() = running?.generation

    /** Whether the participant holds a staged projection, whether or not the host answers. */
    suspend fun isStaged(): Boolean = participant.status(ANY_ATTEMPT).phase is ParticipantPhase.StagedWrapper

    /** Starts a new process of the host: its participant holds nothing and its runtimes are gone. */
    fun restart() {
        participant = start()
    }

    internal fun presence(): RealmHostPresence? = if (responding && answersProbe()) presence(id, roles) else null

    internal suspend fun status(attempt: RolloutAttempt): ParticipantStatus? =
        if (responding) participant.status(attempt).takeIf(answersStatus) else null

    internal suspend fun apply(
        request: ApplyRolloutCommandRequest,
        timeout: Duration,
    ): ApplyRolloutCommandResponse? {
        if (!responding) {
            delay(timeout)
            return null
        }
        commands += request
        delay(commandDuration)
        if (!responding) return null
        return participant.apply(request)
    }

    private fun start(): HostRolloutParticipant {
        val current = ++process
        running = null
        runtimes = mutableListOf()
        return HostRolloutParticipant(
            REALM,
            { placement -> if (placement == RuntimePlacement.PRIMARY_ENGINE) id.value else null },
            id,
            root.resolve("process-$current"),
            hosted,
            projections,
            artifacts,
            { status -> if (current == process) observed(status) },
            scope,
            HostedRuntimeStager {
                check(!failsStaging) { "Staging failed." }
                val runtime = FixtureRuntime()
                runtimes += runtime
                LoadedHostedRuntime(runtime, URLClassLoader(emptyArray<URL>()))
            },
        )
    }

    private fun observed(status: ParticipantStatus) {
        val now =
            when (val phase = status.phase) {
                is ParticipantPhase.ActiveWrapper -> phase.value.current.projection
                ParticipantPhase.IDLE -> null
                else -> return
            }
        if (now == running) return
        running = now
        switches += now
    }

    private inner class FixtureRuntime : StagedHostedRuntime {
        private val state = MutableStateFlow<RuntimeHealth>(RuntimeHealth.Staged)
        override val health: StateFlow<RuntimeHealth> = state
        private var live = false

        override suspend fun activate() {
            check(!failsActivation) { "Activation failed." }
            run()
        }

        override suspend fun quiesce() {
            live = false
        }

        override suspend fun resume() = run()

        override suspend fun close() {
            live = false
        }

        fun refresh() {
            if (live) state.value = this@RealmHost.health
        }

        private fun run() {
            live = true
            state.value = this@RealmHost.health
        }
    }

    private companion object {
        val ANY_ATTEMPT = RolloutAttempt(ordinal = 1, generation = 1)
    }
}

/**
 * The hosts of one Realm behind its presence probe and messenger, as the rollout reaches them: every responding host
 * answers presence and status, and a command reaches only the hosts it lists.
 */
private class FixtureRealm(
    private val hosts: List<RealmHost>,
) : PresenceProbe,
    RolloutMessenger {
    override suspend fun answering(): List<RealmHostPresence> = hosts.mapNotNull(RealmHost::presence)

    override suspend fun command(
        request: ApplyRolloutCommandRequest,
        timeout: Duration,
    ): List<ApplyRolloutCommandResponse> {
        val listed = hosts.filter { it.id.value in request.command.serviceIds }
        return coroutineScope { listed.map { async { it.apply(request, timeout) } }.awaitAll().filterNotNull() }
    }

    override suspend fun statuses(
        request: QueryParticipantStatusRequest,
        expected: Set<ServiceId>,
        timeout: Duration,
    ): Map<ServiceId, ParticipantStatus> = hosts.mapNotNull { host -> host.status(request.attempt)?.let { host.id to it } }.toMap()
}

/**
 * Accepted candidates that resolve to [content], whatever hosts the Realm has, until their artifacts are withdrawn:
 * a withdrawn content no longer resolves and has no manifests, as when a newer import of the same release replaced
 * one of its artifacts.
 */
class FixtureDeploymentContents(
    content: DeploymentContent = deploymentContent(),
) : DeploymentContents {
    /** Every content this resolved to, so the artifact store can serve all of their artifacts. */
    internal val served = mutableListOf(content)
    private val withdrawn = mutableSetOf<DeploymentContent>()

    var content: DeploymentContent = content
        set(value) {
            field = value
            served += value
        }

    /** Stops accepting an artifact of [content]. */
    fun withdraw(content: DeploymentContent) {
        withdrawn += content
    }

    override suspend fun newest(selection: RealmDeploymentSelection) =
        content.takeUnless { it in withdrawn }?.let { ResolutionResult.Resolved(it, deploymentManifests()) }

    override suspend fun manifests(content: DeploymentContent) = deploymentManifests().takeUnless { content in withdrawn }
}

/** Serves an archive holding the manifest of every artifact [contents] resolved to. */
private class FixtureArtifacts(
    private val root: Path,
    private val contents: FixtureDeploymentContents,
) : VerifiedArtifactSource {
    override suspend fun fetch(digest: ArtifactDigest): Path {
        val path = root.resolve(digest.value)
        if (Files.exists(path)) return path
        val artifact =
            contents.served
                .flatMap { listOf(it.realm, it.primaryEngine, it.panelEngine) + it.extensions }
                .first { it.digest == digest }
        Files.createDirectories(root)
        ZipOutputStream(Files.newOutputStream(path)).use { archive ->
            archive.putNextEntry(ZipEntry(IMPRINT_MANIFEST_PATH))
            archive.write(ImprintManifestCodec.encode(deploymentManifests().getValue(artifact.coordinate.id)))
            archive.closeEntry()
        }
        return path
    }
}

/**
 * The rollout of Realm `realm` over the hosts added with [host], on the test's virtual clock, with production timings
 * and presence grace unless told otherwise. [start] runs it until the test ends.
 */
class RealmRolloutFixture(
    private val test: TestScope,
    private val timings: RolloutTimings = RolloutTimings(),
    private val presenceGrace: Duration = ProbedRealmMembership.DEFAULT_GRACE,
) {
    private val root = Files.createTempDirectory("typewriter-rollout")
    private val clock = test.testScheduler.timeSource
    private val clockStart = clock.markNow()
    private val hosts = mutableListOf<RealmHost>()
    private val realm = FixtureRealm(hosts)
    private var running: Job? = null
    val state = FileRolloutStateRepository(REALM, root)
    val projections = BlobProjectionRepository(InMemoryBlobEndpoint())
    val contents = FixtureDeploymentContents()
    private val artifacts = FixtureArtifacts(root.resolve("artifacts"), contents)

    /** How long the test has run on the virtual clock. */
    val elapsed: Duration get() = clockStart.elapsedNow()

    /** Adds a host with [roles] to the Realm. */
    fun host(
        id: String,
        roles: Set<RuntimePlacement> = RuntimePlacement.entries.toSet(),
    ): RealmHost = RealmHost(ServiceId(id), roles, test.backgroundScope, projections, artifacts).also(hosts::add)

    fun start() {
        val rollout =
            RealmRollout(
                REALM,
                ProbedRealmMembership(realm, presenceGrace, clock),
                realm,
                contents,
                projections,
                state,
                timings,
                timeSource = clock,
            )
        running = test.backgroundScope.launch { rollout.run() }
    }

    /**
     * Restarts the process of [realmHost], which runs the rollout: the rollout starts over from the state it persisted
     * and the host's participant starts empty.
     */
    fun restartRealm(realmHost: RealmHost) {
        running?.cancel()
        realmHost.restart()
        start()
    }

    /** The generation the Realm committed last, or null before its first commit. */
    suspend fun committedGeneration(): Long? =
        state
            .committed()
            ?.snapshot
            ?.generation
            ?.value

    /** Whether [host] runs the projection the committed deployment recorded for it. */
    suspend fun runsCommitted(host: RealmHost): Boolean {
        val recorded = state.committed()?.projections?.get(host.id) ?: return false
        return host.runningProjection == recorded
    }

    /**
     * Advances the virtual clock until [condition] holds and returns [elapsed] at that moment, or null when it did not
     * hold within [limit].
     */
    suspend fun until(
        limit: Duration,
        condition: suspend () -> Boolean,
    ): Duration? {
        val deadline = clock.markNow() + limit
        while (true) {
            test.runCurrent()
            if (condition()) return elapsed
            if (deadline.hasPassedNow()) return null
            test.advanceTimeBy(100.milliseconds)
        }
    }

    /** Advances the virtual clock by [duration]. */
    fun wait(duration: Duration) {
        test.advanceTimeBy(duration)
        test.runCurrent()
    }
}

private val realmArtifact = deploymentArtifact("typewritermc:realm", ArtifactKind.REALM, "realm")
private val panelArtifact = deploymentArtifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")

/** Deployment content with a Realm, a panel engine and a primary engine built from [primary], and no extensions. */
fun deploymentContent(primary: String = "paper"): DeploymentContent =
    DeploymentContent(
        realm = realmArtifact,
        primaryEngine = deploymentArtifact("typewritermc:paper", ArtifactKind.ENGINE, primary),
        panelEngine = panelArtifact,
        extensions = emptyList(),
    )

/** Generation one of [deploymentContent]. */
fun deploymentSnapshot(): DeploymentSnapshot {
    val content = deploymentContent()
    return DeploymentSnapshot(DeploymentGeneration(1), DeploymentContentCodec.digest(content), content)
}

/** The manifests of every [deploymentContent]: its artifacts share identities and versions. */
fun deploymentManifests(): Map<ArtifactId, ImprintManifest> {
    val primary = deploymentContent().primaryEngine
    return mapOf(
        realmArtifact.coordinate.id to
            RealmManifest(
                id = realmArtifact.coordinate.id,
                version = realmArtifact.coordinate.version,
                hostApi = VersionConstraint("^1"),
                runtimeEntrypointClass = "fixture.Runtime",
                contributions = emptyList(),
            ),
        panelArtifact.coordinate.id to engineManifest(panelArtifact),
        primary.coordinate.id to engineManifest(primary),
    )
}

fun presence(
    host: ServiceId,
    roles: Set<RuntimePlacement>,
) = RealmHostPresence(
    serviceId = host.value,
    hostApi = FIXTURE_VERSION.value,
    assignedRoles = roles.map { it.toSkir() },
)

fun ApplyRolloutCommandRequest.projectionFor(host: ServiceId): ProjectionReference = requireNotNull(command.projectionOf(host.value))
