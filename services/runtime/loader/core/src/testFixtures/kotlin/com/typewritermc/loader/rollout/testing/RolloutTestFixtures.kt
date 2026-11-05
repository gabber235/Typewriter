package com.typewritermc.loader.rollout.testing

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ArtifactKind
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.imprint.RealmManifest
import com.typewritermc.imprint.VersionConstraint
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.artifact.FileDigestBlobStore
import com.typewritermc.loader.deployment.DeploymentContent
import com.typewritermc.loader.deployment.DeploymentContentCodec
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.loader.deployment.RealmDeploymentSelection
import com.typewritermc.loader.rollout.BlobProjectionRepository
import com.typewritermc.loader.rollout.CoordinatedRollout
import com.typewritermc.loader.rollout.FileRolloutStateRepository
import com.typewritermc.loader.rollout.RealmId
import com.typewritermc.loader.rollout.RolloutMessenger
import com.typewritermc.loader.rollout.commandKind
import com.typewritermc.loader.rollout.projectionOf
import com.typewritermc.loader.rollout.toSkir
import com.typewritermc.loader.testing.FIXTURE_VERSION
import com.typewritermc.loader.testing.deploymentArtifact
import com.typewritermc.loader.testing.engineManifest
import com.typewritermc.services.libs.registrar.ServiceId
import kotlinx.coroutines.delay
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
import skirout.service.v1.rollout.RolloutCommand
import skirout.service.v1.rollout.RolloutCommandKind
import java.nio.file.Files
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeSource

/**
 * One rollout participant host as the coordinator sees it through messaging: it reports its presence, applies stage,
 * commit, abort and roll back commands to its own phase, and answers status queries with that phase.
 */
class FakeRolloutHost(
    val id: ServiceId,
    private val roles: Set<RuntimePlacement> = RuntimePlacement.entries.toSet(),
) : RolloutMessenger {
    /** Every command the coordinator sent, in order. */
    val commands = mutableListOf<ApplyRolloutCommandRequest>()

    /** The phase the host reports, or null before it received any command. */
    var status: ParticipantStatus? = null
        private set

    /** The projection the host runs, which it reports with its presence. */
    var activeProjection: ActiveProjection? = null

    /** Whether the host answers discovery; a host that stopped answers nothing. */
    var responding = true

    /** Whether the host rejects commits after applying them, as a host whose activation failed does. */
    var rejectCommits = false

    /** How long applying one command takes. */
    var commandDuration: Duration = Duration.ZERO

    /** Decides per status query whether the host's reply arrives; a missing reply is an incomplete snapshot. */
    var answersStatus: (ParticipantStatus) -> Boolean = { true }

    val commandKinds: List<RolloutCommandKind> get() = commands.map { it.command.commandKind }

    override suspend fun discover(
        expected: Set<ServiceId>,
        timeout: Duration,
    ): List<RealmHostPresence> = if (responding) listOf(presence(id, roles, activeProjection)) else emptyList()

    override suspend fun command(
        request: ApplyRolloutCommandRequest,
        timeout: Duration,
    ): List<ApplyRolloutCommandResponse> {
        commands += request
        delay(commandDuration)
        val phase =
            when (val command = request.command) {
                is RolloutCommand.StageWrapper -> {
                    staged(request.projectionFor(id), activeProjection)
                }

                is RolloutCommand.CommitWrapper -> {
                    active(request.projectionFor(id)).also { activeProjection = it.value.current }
                }

                is RolloutCommand.RollBackWrapper -> {
                    when (
                        val target =
                            command.value.participants
                                .findByKey(id.value)
                                ?.target
                    ) {
                        is RollbackTarget.ProjectionWrapper -> active(target.value).also { activeProjection = it.value.current }
                        else -> ParticipantPhase.IDLE.also { activeProjection = null }
                    }
                }

                else -> {
                    ParticipantPhase.IDLE
                }
            }
        status = ParticipantStatus(serviceId = id.value, attempt = request.attempt, phase = phase)
        val rejected = rejectCommits && request.command is RolloutCommand.CommitWrapper
        return listOf(
            if (rejected) {
                ApplyRolloutCommandResponse.createCommandRejectedError(serviceId = id.value, reason = "rejected")
            } else {
                ApplyRolloutCommandResponse.createAccepted(serviceId = id.value)
            },
        )
    }

    override suspend fun statuses(
        request: QueryParticipantStatusRequest,
        expected: Set<ServiceId>,
        timeout: Duration,
    ): Map<ServiceId, ParticipantStatus> {
        val current = status ?: return emptyMap()
        return if (answersStatus(current)) mapOf(id to current) else emptyMap()
    }
}

/** A coordinated rollout of [snapshot] for Realm `realm` whose only reachable participant is [host]. */
class RolloutFixture(
    val host: FakeRolloutHost,
    selection: RealmDeploymentSelection = RealmDeploymentSelection(host.id, setOf(host.id), mapOf(host.id to FIXTURE_VERSION)),
    participantDeadline: Duration = 1.seconds,
    healthyDuration: Duration = Duration.ZERO,
    timeSource: TimeSource = TimeSource.Monotonic,
) {
    private val root = Files.createTempDirectory("typewriter-rollout")
    val state = FileRolloutStateRepository(RealmId("realm"), root)
    val projections = BlobProjectionRepository(FileDigestBlobStore(root))
    val snapshot = deploymentSnapshot()
    val rollout =
        CoordinatedRollout(
            RealmId("realm"),
            selection,
            deploymentManifests(),
            host,
            projections,
            state,
            requestTimeout = 1.seconds,
            participantDeadline = participantDeadline,
            healthyDuration = healthyDuration,
            timeSource = timeSource,
        )
}

private val realmArtifact = deploymentArtifact("typewritermc:realm", ArtifactKind.REALM, "realm")
private val panelArtifact = deploymentArtifact("typewritermc:panel", ArtifactKind.ENGINE, "panel")
private val primaryArtifact = deploymentArtifact("typewritermc:paper", ArtifactKind.ENGINE, "paper")

/** Generation one of a deployment with a Realm, a panel engine and a primary engine and no extensions. */
fun deploymentSnapshot(): DeploymentSnapshot {
    val content =
        DeploymentContent(realm = realmArtifact, primaryEngine = primaryArtifact, panelEngine = panelArtifact, extensions = emptyList())
    return DeploymentSnapshot(DeploymentGeneration(1), DeploymentContentCodec.digest(content), content)
}

fun deploymentManifests(): Map<ArtifactId, ImprintManifest> =
    mapOf(
        realmArtifact.coordinate.id to
            RealmManifest(
                id = realmArtifact.coordinate.id,
                version = realmArtifact.coordinate.version,
                hostApi = VersionConstraint("^1"),
                runtimeEntrypointClass = "fixture.Runtime",
                contributions = emptyList(),
            ),
        panelArtifact.coordinate.id to engineManifest(panelArtifact),
        primaryArtifact.coordinate.id to engineManifest(primaryArtifact),
    )

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

private fun staged(
    reference: ProjectionReference,
    baseline: ActiveProjection?,
) = ParticipantPhase.createStaged(candidate = reference, baseline = baseline)

private fun active(reference: ProjectionReference) =
    ParticipantPhase.createActive(current = ActiveProjection(projection = reference, health = ProjectionHealth.HEALTHY), retained = null)
