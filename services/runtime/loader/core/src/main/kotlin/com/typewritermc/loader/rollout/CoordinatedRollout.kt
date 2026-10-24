package com.typewritermc.loader.rollout

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.loader.artifact.toApi
import com.typewritermc.loader.artifactSpan
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.RealmDeploymentSelection
import com.typewritermc.loader.deployment.projectFor
import com.typewritermc.protocol.transport.generated.TRANSPORT_LIMITS
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.SpanPresentation
import kotlinx.coroutines.delay
import skirout.service.v1.rollout.ApplyRolloutCommandRequest
import skirout.service.v1.rollout.ApplyRolloutCommandResponse
import skirout.service.v1.rollout.ParticipantPhase
import skirout.service.v1.rollout.ParticipantProjection
import skirout.service.v1.rollout.ParticipantRollback
import skirout.service.v1.rollout.ParticipantStatus
import skirout.service.v1.rollout.ProjectionHealth
import skirout.service.v1.rollout.ProjectionReference
import skirout.service.v1.rollout.QueryParticipantStatusRequest
import skirout.service.v1.rollout.RealmHostPresence
import skirout.service.v1.rollout.RollbackTarget
import skirout.service.v1.rollout.RolloutAttempt
import skirout.service.v1.rollout.RolloutCommand
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * Exchanges bounded presence, command, and status requests with the hosts of one Realm.
 *
 * Timeouts can produce incomplete replies. The coordinator validates expected hosts and exact attempt and
 * projection state.
 */
interface RolloutMessenger {
    suspend fun discover(
        expected: Set<ServiceId>,
        timeout: Duration,
    ): List<RealmHostPresence>

    suspend fun command(
        request: ApplyRolloutCommandRequest,
        timeout: Duration,
    ): List<ApplyRolloutCommandResponse>

    suspend fun statuses(
        request: QueryParticipantStatusRequest,
        expected: Set<ServiceId>,
        timeout: Duration,
    ): Map<ServiceId, ParticipantStatus>
}

/**
 * Publishes immutable canonical host projections and returns exact references for participant retrieval.
 */
interface ProjectionRepository {
    suspend fun publish(projection: HostDeploymentProjection): ProjectionReference
}

/**
 * Persists attempt ordering and committed deployments.
 *
 * Attempt ordinals must survive restart to distinguish stale commands.
 */
interface RolloutStateRepository {
    suspend fun nextAttempt(generation: DeploymentGeneration): RolloutAttempt

    suspend fun committed(): CommittedDeployment?

    suspend fun commit(deployment: CommittedDeployment)
}

/**
 * Stages and activates projections across responding selected hosts, then proves a healthy stability interval.
 *
 * The Realm host must answer discovery; absent engine hosts can reconcile later. Selection must remain unchanged
 * before commit. Failure triggers abort before committing or rollback afterward; compensation itself may fail and
 * is not an atomic distributed transaction. A command waits at most the transport reply time to live by default,
 * the longest a host is permitted to reply.
 */
class CoordinatedRollout(
    private val realmId: RealmId,
    private val selection: RealmDeploymentSelection,
    private val manifests: Map<ArtifactId, ImprintManifest>,
    private val messenger: RolloutMessenger,
    private val projections: ProjectionRepository,
    private val state: RolloutStateRepository,
    private val currentSelection: suspend () -> RealmDeploymentSelection = { selection },
    private val requestTimeout: Duration = 5.seconds,
    private val commandTimeout: Duration = TRANSPORT_LIMITS.replyTtl,
    private val participantDeadline: Duration = 5.minutes,
    private val healthyDuration: Duration = 30.seconds,
    private val telemetry: ServiceTelemetry? = null,
    private val timeSource: TimeSource = TimeSource.Monotonic,
) {
    /** Starts a new attempt for [snapshot] and commits only after every participating host is stable and healthy. */
    suspend fun rollOut(snapshot: DeploymentSnapshot) =
        telemetry.artifactSpan(
            "artifact.rollout.coordinate",
            "artifact-rollout-coordinate-failed",
            presentation = SpanPresentation("Artifact deployment ${snapshot.generation.value} for Realm ${realmId.value}"),
        ) { span ->
            span?.annotate {
                attribute("realm.id", realmId.value)
                attribute("deployment.generation", snapshot.generation.value)
            }
            rollOutContents(snapshot)
        }

    private suspend fun rollOutContents(snapshot: DeploymentSnapshot) {
        val attempt = state.nextAttempt(snapshot.generation)
        val participants = discoverParticipants()
        val references = publishProjections(snapshot, participants.hosts.keys)
        deploy(
            RolloutProgress(attempt, references, participants.hosts.baselines()),
            CommittedDeployment(snapshot, references.blobs()),
            "Realm selection changed while the deployment was staged.",
        )
    }

    /**
     * Repairs stale or unhealthy responding hosts to the current committed snapshot.
     *
     * Only stale participants receive commands. Selection and stability checks still apply, and no newer content is
     * selected.
     */
    suspend fun reconcileCommitted(deployment: CommittedDeployment) {
        require(state.committed()?.snapshot == deployment.snapshot) { "Only the committed deployment can be reconciled." }
        val participants = discoverParticipants()
        val expected = publishProjections(deployment.snapshot, participants.hosts.keys)
        val stale =
            participants.hosts
                .filter { (host, presence) ->
                    val active = presence.activeProjection
                    active?.projection != expected.getValue(host) || active.health != ProjectionHealth.HEALTHY
                }.keys
        if (stale.isEmpty()) return

        val attempt = state.nextAttempt(deployment.snapshot.generation)
        deploy(
            RolloutProgress(
                attempt,
                expected.filterKeys { it in stale },
                participants.hosts.filterKeys { it in stale }.baselines(),
            ),
            CommittedDeployment(deployment.snapshot, expected.blobs()),
            "Realm selection changed while participants reconciled.",
        )
    }

    /**
     * Stages and commits [progress] on its participants, proves stability and then records [deployment]. Any failure
     * drives abort or exact baseline rollback before it propagates.
     */
    private suspend fun deploy(
        progress: RolloutProgress,
        deployment: CommittedDeployment,
        selectionChanged: String,
    ) {
        val (attempt, references) = progress
        try {
            val stage = progress.request(RolloutCommand.createStage(participants = references.participants()))
            requireAccepted(messenger.command(stage, commandTimeout), references.keys)
            awaitStatuses(attempt, references.keys) { host, status -> status.stagedCandidate() == references.getValue(host) }
            require(currentSelection() == selection) { selectionChanged }

            progress.committing = true
            val commit = progress.request(RolloutCommand.createCommit(participants = references.participants()))
            requireAccepted(messenger.command(commit, commandTimeout), references.keys)
            awaitStableHealthy(attempt, references)
            state.commit(deployment)
        } catch (failure: Throwable) {
            compensate(progress)
            throw failure
        }
    }

    /**
     * Drives abort or exact baseline rollback before the caller rethrows its failure.
     * Compensation errors propagate and may prevent that original failure from reaching the caller.
     */
    private suspend fun compensate(progress: RolloutProgress) {
        val (attempt, references, baselines) = progress
        val command =
            if (!progress.committing) {
                RolloutCommand.createAbort(participants = references.participants())
            } else {
                RolloutCommand.createRollBack(
                    participants =
                        references.map { (host, reference) ->
                            ParticipantRollback(
                                serviceId = host.value,
                                projection = reference,
                                target = baselines[host]?.let(RollbackTarget::ProjectionWrapper) ?: RollbackTarget.EMPTY,
                            )
                        },
                )
            }
        messenger.command(progress.request(command), commandTimeout)
        awaitStatuses(attempt, references.keys) { host, status ->
            val target = baselines[host]
            if (target == null) status.phase == ParticipantPhase.IDLE else status.runsHealthy(target)
        }
    }

    /** Uses a fresh probe to define the responding participant set for this attempt. */
    private suspend fun discoverParticipants(): RolloutParticipants {
        val selected = selection.selectedServices()
        val responding =
            messenger
                .discover(selected, requestTimeout)
                .associateBy { ServiceId(it.serviceId) }
                .filterKeys { it in selected }
        require(selection.realmService in responding) { "The Realm service did not answer its rollout presence probe." }
        return RolloutParticipants(responding)
    }

    private suspend fun publishProjections(
        snapshot: DeploymentSnapshot,
        participants: Set<ServiceId>,
    ): Map<ServiceId, ProjectionReference> =
        participants.associateWith { host ->
            projections.publish(snapshot.projectFor(realmId.value, selection, host, manifests))
        }

    private fun Map<ServiceId, RealmHostPresence>.baselines(): Map<ServiceId, ProjectionReference> =
        mapNotNull { (host, presence) -> presence.activeProjection?.projection?.let { host to it } }.toMap()

    private fun requireAccepted(
        replies: List<ApplyRolloutCommandResponse>,
        expected: Set<ServiceId>,
    ) {
        val byService = replies.associateBy { it.serviceId }
        require(expected.all { it.value in byService }) { "Not every rollout participant replied." }
        require(expected.all { byService[it.value] is ApplyRolloutCommandResponse.AcceptedWrapper }) {
            "A rollout participant rejected the command."
        }
    }

    /**
     * Requires healthy observations of the requested projections across [healthyDuration].
     * Missing or unhealthy replies reset the interval; changes between probes are outside this evidence.
     */
    private suspend fun awaitStableHealthy(
        attempt: RolloutAttempt,
        references: Map<ServiceId, ProjectionReference>,
    ) {
        var healthySince: TimeMark? = null
        val deadline = timeSource.markNow()
        while (deadline.elapsedNow() < participantDeadline) {
            val statuses = messenger.statuses(QueryParticipantStatusRequest(attempt = attempt), references.keys, requestTimeout)
            val allHealthy = references.all { (host, reference) -> statuses[host]?.runsHealthy(reference) == true }
            if (!allHealthy) {
                healthySince = null
            } else {
                val started = healthySince ?: timeSource.markNow().also { healthySince = it }
                if (started.elapsedNow() >= healthyDuration) return
            }
            delay(100)
        }
        error("Timed out while proving rollout stability.")
    }

    private suspend fun awaitStatuses(
        attempt: RolloutAttempt,
        participants: Set<ServiceId>,
        condition: (ServiceId, ParticipantStatus) -> Boolean,
    ) {
        val deadline = timeSource.markNow()
        while (deadline.elapsedNow() < participantDeadline) {
            val statuses = messenger.statuses(QueryParticipantStatusRequest(attempt = attempt), participants, requestTimeout)
            if (participants.all { host -> statuses[host]?.let { condition(host, it) } == true }) return
            delay(100)
        }
        error("Timed out waiting for rollout participants.")
    }
}

/**
 * One attempt's participants with their exact projections and recovery baselines. [committing] records whether
 * compensation must roll back instead of abort.
 */
private data class RolloutProgress(
    val attempt: RolloutAttempt,
    val references: Map<ServiceId, ProjectionReference>,
    val baselines: Map<ServiceId, ProjectionReference>,
) {
    var committing = false

    fun request(command: RolloutCommand) = ApplyRolloutCommandRequest(attempt = attempt, command = command)
}

private fun Map<ServiceId, ProjectionReference>.participants() =
    map { (host, reference) -> ParticipantProjection(serviceId = host.value, projection = reference) }

private fun Map<ServiceId, ProjectionReference>.blobs() = mapValues { (_, reference) -> reference.blob.toApi() }

private fun ParticipantStatus.stagedCandidate(): ProjectionReference? = (phase as? ParticipantPhase.StagedWrapper)?.value?.candidate

/** Whether this status reports [reference] active and healthy. */
private fun ParticipantStatus.runsHealthy(reference: ProjectionReference): Boolean {
    val current = (phase as? ParticipantPhase.ActiveWrapper)?.value?.current ?: return false
    return current.projection == reference && current.health == ProjectionHealth.HEALTHY
}

/** Responding selected hosts for one rollout probe, including the required Realm host. */
data class RolloutParticipants(
    val hosts: Map<ServiceId, RealmHostPresence>,
)
