package com.typewritermc.loader.rollout.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.artifact.toApi
import com.typewritermc.loader.deployment.DeploymentContent
import com.typewritermc.loader.deployment.DeploymentContentCodec
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.loader.deployment.RealmDeploymentSelection
import com.typewritermc.loader.deployment.ResolutionResult
import com.typewritermc.loader.rollout.BlobProjectionRepository
import com.typewritermc.loader.rollout.DeploymentContents
import com.typewritermc.loader.rollout.FileRolloutStateRepository
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.loader.rollout.RealmMembership
import com.typewritermc.loader.rollout.RealmRollout
import com.typewritermc.loader.rollout.RolloutMessenger
import com.typewritermc.loader.rollout.RolloutTimings
import com.typewritermc.loader.rollout.commandKind
import com.typewritermc.loader.rollout.projectionOf
import com.typewritermc.loader.rollout.serviceIds
import com.typewritermc.loader.rollout.toSkir
import com.typewritermc.loader.testing.FIXTURE_VERSION
import com.typewritermc.loader.testing.deploymentArtifact
import com.typewritermc.loader.testing.engineManifest
import com.typewritermc.services.libs.filetransfer.blob.InMemoryBlobEndpoint
import com.typewritermc.services.libs.registrar.ServiceId
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import skirout.service.v1.rollout.ActiveParticipant
import skirout.service.v1.rollout.ActiveProjection
import skirout.service.v1.rollout.ApplyRolloutCommandRequest
import skirout.service.v1.rollout.ApplyRolloutCommandResponse
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.ParticipantStatus
import skirout.service.v1.rollout.ProjectionHealth
import skirout.service.v1.rollout.ProjectionReference
import skirout.service.v1.rollout.QueryParticipantStatusRequest
import skirout.service.v1.rollout.RealmHostPresence
import skirout.service.v1.rollout.RollbackTarget
import skirout.service.v1.rollout.RolloutAttempt
import skirout.service.v1.rollout.RolloutCommand
import skirout.service.v1.rollout.RolloutCommandKind
import java.nio.file.Files
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/**
 * One host of a Realm as the rollout reaches it through messaging. It keeps one staged, one active and one retained
 * projection the way a rollout participant does: stage keeps the active projection as the baseline, commit activates
 * the staged one and retains the one it replaced, abort drops the staged one, and roll back restores exactly the
 * retained projection or nothing.
 */
class FakeRolloutHost(
    val id: ServiceId,
    val roles: Set<RuntimePlacement> = RuntimePlacement.entries.toSet(),
) {
    /** Every command the host received, in order. */
    val commands = mutableListOf<ApplyRolloutCommandRequest>()

    /** Every projection the host switched to running, in order; null when it went back to running nothing. */
    val switches = mutableListOf<ProjectionReference?>()

    /** Whether the host answers; a host that stopped (left the Realm, crashed, lost its connection) answers nothing. */
    var responding = true

    /** Commands the host refuses in its current state, as a host whose staging or activation fails does. */
    var refuses: Set<RolloutCommandKind> = emptySet()

    /** How long applying one command takes. */
    var commandDuration: Duration = Duration.ZERO

    /** The health the host reports for the projection it runs. */
    var health: ProjectionHealth = ProjectionHealth.HEALTHY

    /** Decides per status query whether the host's reply arrives; a missing reply is an incomplete snapshot. */
    var answersStatus: (ParticipantStatus) -> Boolean = { true }

    private var staged: ProjectionReference? = null
    private var active: ProjectionReference? = null
    private var retained: ProjectionReference? = null
    private var attempt = RolloutAttempt(ordinal = 1, generation = 1)

    /** The projection the host runs and its health, which it reports with its presence. */
    val activeProjection: ActiveProjection?
        get() = active?.let { ActiveProjection(projection = it, health = health) }

    val commandKinds: List<RolloutCommandKind> get() = commands.map { it.command.commandKind }

    /** The deployment generation of the projection the host runs, or null while it runs nothing. */
    val generation: Long? get() = active?.generation

    /** Forgets every projection, as a host that restarted does. */
    fun restart() {
        staged = null
        active = null
        retained = null
    }

    internal fun presence(): RealmHostPresence? = if (responding) presence(id, roles, activeProjection) else null

    internal fun status(): ParticipantStatus? {
        if (!responding) return null
        val current = ParticipantStatus(serviceId = id.value, attempt = attempt, phase = phase())
        return current.takeIf(answersStatus)
    }

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
        attempt = request.attempt
        val command = request.command
        val reference = request.projectionFor(id)
        if (command.commandKind in refuses) {
            if (command is RolloutCommand.CommitWrapper) staged = null
            return ApplyRolloutCommandResponse.createCommandRejectedError(serviceId = id.value, reason = "refused")
        }
        val accepted =
            when (command) {
                is RolloutCommand.StageWrapper -> {
                    staged = reference
                    true
                }

                is RolloutCommand.CommitWrapper -> {
                    if (staged == reference) {
                        retained = active
                        switchTo(reference)
                        staged = null
                        true
                    } else {
                        active == reference
                    }
                }

                is RolloutCommand.AbortWrapper -> {
                    if (staged == reference) staged = null
                    true
                }

                is RolloutCommand.RollBackWrapper -> {
                    rollBack(reference, requireNotNull(command.value.participants.findByKey(id.value)).target)
                }

                else -> {
                    false
                }
            }
        return if (accepted) {
            ApplyRolloutCommandResponse.createAccepted(serviceId = id.value)
        } else {
            ApplyRolloutCommandResponse.createCommandRejectedError(serviceId = id.value, reason = "not applicable")
        }
    }

    private fun rollBack(
        failed: ProjectionReference,
        target: RollbackTarget,
    ): Boolean {
        val restore = (target as? RollbackTarget.ProjectionWrapper)?.value
        return when {
            staged == failed -> {
                staged = null
                true
            }

            active == restore -> {
                true
            }

            active == failed && retained == restore -> {
                retained = null
                switchTo(restore)
                true
            }

            else -> {
                false
            }
        }
    }

    private fun switchTo(reference: ProjectionReference?) {
        active = reference
        switches += reference
    }

    private fun phase(): ParticipantPhase {
        val running = activeProjection
        return when {
            staged != null -> ParticipantPhase.createStaged(candidate = requireNotNull(staged), baseline = running)
            running != null -> ParticipantPhase.ActiveWrapper(ActiveParticipant(current = running, retained = retained))
            else -> ParticipantPhase.IDLE
        }
    }
}

/**
 * The hosts of one Realm behind its membership and messenger, as the rollout reaches them: every responding host
 * answers presence and status, and a command reaches only the hosts it lists.
 */
class FakeRealmHosts(
    private val hosts: List<FakeRolloutHost>,
) : RealmMembership,
    RolloutMessenger {
    override suspend fun members(): List<RealmHostPresence> = hosts.mapNotNull(FakeRolloutHost::presence)

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
    ): Map<ServiceId, ParticipantStatus> = hosts.mapNotNull { host -> host.status()?.let { host.id to it } }.toMap()
}

/** Accepted candidates that always resolve to [content], whatever hosts the Realm has. */
class FixtureDeploymentContents(
    var content: DeploymentContent = deploymentContent(),
) : DeploymentContents {
    override suspend fun newest(selection: RealmDeploymentSelection) = ResolutionResult.Resolved(content, deploymentManifests())

    override suspend fun manifests(content: DeploymentContent) = deploymentManifests()
}

/**
 * The rollout of Realm `realm` over [hosts] on the test's virtual clock, with production timings unless [timings]
 * says otherwise. [start] runs it until the test ends.
 */
class RealmRolloutFixture(
    private val test: TestScope,
    val hosts: List<FakeRolloutHost>,
    timings: RolloutTimings = RolloutTimings(),
) {
    private val root = Files.createTempDirectory("typewriter-rollout")
    private val clockStart = test.testScheduler.timeSource.markNow()
    val state = FileRolloutStateRepository(RealmId("realm"), root)
    val projections = BlobProjectionRepository(InMemoryBlobEndpoint())
    val contents = FixtureDeploymentContents()
    val realm = FakeRealmHosts(hosts)
    val rollout =
        RealmRollout(
            RealmId("realm"),
            realm,
            realm,
            contents,
            projections,
            state,
            timings,
            timeSource = test.testScheduler.timeSource,
        )

    /** How long the test has run on the virtual clock. */
    val elapsed: Duration get() = clockStart.elapsedNow()

    fun start(): Job = test.backgroundScope.launch { rollout.run() }

    /** The generation the Realm committed last, or null before its first commit. */
    suspend fun committedGeneration(): Long? =
        state
            .committed()
            ?.snapshot
            ?.generation
            ?.value

    /** Whether [host] runs the projection the committed deployment recorded for it. */
    suspend fun runsCommitted(host: FakeRolloutHost): Boolean {
        val recorded = state.committed()?.projections?.get(host.id) ?: return false
        return host.activeProjection
            ?.projection
            ?.blob
            ?.toApi() == recorded
    }

    /**
     * Advances the virtual clock until [condition] holds and returns [elapsed] at that moment, or null when it did not
     * hold within [limit].
     */
    suspend fun until(
        limit: Duration,
        condition: suspend () -> Boolean,
    ): Duration? {
        val deadline = test.testScheduler.timeSource.markNow() + limit
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
    activeProjection: ActiveProjection? = null,
) = RealmHostPresence(
    serviceId = host.value,
    hostApi = FIXTURE_VERSION.value,
    assignedRoles = roles.map { it.toSkir() },
    activeProjection = activeProjection,
)

fun ApplyRolloutCommandRequest.projectionFor(host: ServiceId): ProjectionReference = requireNotNull(command.projectionOf(host.value))
