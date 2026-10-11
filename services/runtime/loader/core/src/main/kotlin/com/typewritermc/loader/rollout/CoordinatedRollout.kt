package com.typewritermc.loader.rollout

import com.typewritermc.imprint.ArtifactId
import com.typewritermc.imprint.ImprintManifest
import com.typewritermc.loader.artifactSpan
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.DeploymentSnapshot
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.RealmDeploymentSelection
import com.typewritermc.loader.deployment.projectFor
import com.typewritermc.services.libs.registrar.ServiceId
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import kotlinx.coroutines.delay
import kotlin.time.Duration
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * Exchanges bounded presence, command, and status requests with hosts.
 *
 * Timeouts can produce incomplete replies. The coordinator validates expected hosts and exact attempt and
 * projection state.
 */
interface RolloutMessenger {
    suspend fun discover(
        probe: ProbeRealmHosts,
        expected: Set<ServiceId>,
        timeout: Duration,
    ): List<RealmHostPresence>

    suspend fun command(
        envelope: RolloutEnvelope,
        timeout: Duration,
    ): List<CommandAcceptance>

    suspend fun statuses(
        probe: ProbeParticipantStatus,
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
 * Persists attempt ordering, progress, participant observations, and committed deployments.
 *
 * Progress persistence and final commit are separate operations. Attempt ordinals must survive restart to
 * distinguish stale commands.
 */
interface RolloutStateRepository {
    suspend fun nextAttempt(generation: DeploymentGeneration): RolloutAttempt

    suspend fun persist(rollout: PersistedRollout)

    suspend fun participantStatuses(attempt: RolloutAttempt): Map<ServiceId, ParticipantStatus>

    suspend fun committed(): CommittedDeployment?

    suspend fun commit(deployment: CommittedDeployment)

    suspend fun record(event: ParticipantStateChanged)
}

/**
 * Stages and activates projections across responding selected hosts, then proves a healthy stability interval.
 *
 * The Realm host must answer discovery; absent engine hosts can reconcile later. Selection must remain unchanged
 * before commit. Failure triggers abort before committing or rollback afterward; compensation itself may fail and
 * is not an atomic distributed transaction.
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
    private val commandTimeout: Duration = 5.minutes,
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
        ) { span ->
            span?.annotate {
                attribute("realm.id", realmId.value)
                attribute("deployment.generation", snapshot.generation.value)
            }
            rollOutContents(snapshot)
        }

    private suspend fun rollOutContents(snapshot: DeploymentSnapshot) {
        val attempt = state.nextAttempt(snapshot.generation)
        var persisted = PersistedRollout(realmId, attempt, RolloutPhase.PROPOSED, emptyMap(), emptyMap())
        state.persist(persisted)
        try {
            persisted = persisted.copy(phase = RolloutPhase.DISCOVERING)
            state.persist(persisted)
            val participants = discoverParticipants()
            val references = publishProjections(snapshot, participants.hosts.keys)
            persisted = persisted.copy(phase = RolloutPhase.STAGING, projections = references, previous = participants.hosts.baselines())
            state.persist(persisted)
            requireAccepted(
                messenger.command(envelope(attempt, references, RolloutCommand.Stage), commandTimeout),
                participants.hosts.keys,
            )
            awaitStatuses(attempt, references.keys) { host, status ->
                status is ParticipantStatus.Staged && status.candidate == references.getValue(host)
            }
            require(currentSelection() == selection) { "Realm selection changed while the deployment was staged." }

            persisted = persisted.copy(phase = RolloutPhase.COMMITTING)
            state.persist(persisted)
            requireAccepted(
                messenger.command(envelope(attempt, references, RolloutCommand.Commit), commandTimeout),
                participants.hosts.keys,
            )
            persisted = persisted.copy(phase = RolloutPhase.STABILIZING)
            state.persist(persisted)
            awaitStableHealthy(attempt, references)
            state.commit(CommittedDeployment(snapshot, references))
            state.persist(persisted.copy(phase = RolloutPhase.SUCCEEDED))
        } catch (failure: Throwable) {
            compensate(persisted, failure)
            throw failure
        }
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
                    presence.activeProjection?.projection != expected.getValue(host) ||
                        presence.activeProjection.health != RuntimeHealthSnapshot.Healthy
                }.keys
        if (stale.isEmpty()) return

        val attempt = state.nextAttempt(deployment.snapshot.generation)
        val references = expected.filterKeys { it in stale }
        var persisted =
            PersistedRollout(
                realmId,
                attempt,
                RolloutPhase.STAGING,
                references,
                participants.hosts.filterKeys { it in stale }.baselines(),
            )
        state.persist(persisted)
        try {
            requireAccepted(messenger.command(envelope(attempt, references, RolloutCommand.Stage), commandTimeout), stale)
            awaitStatuses(attempt, stale) { host, status ->
                status is ParticipantStatus.Staged && status.candidate == references.getValue(host)
            }
            require(currentSelection() == selection) { "Realm selection changed while participants reconciled." }
            persisted = persisted.copy(phase = RolloutPhase.COMMITTING)
            state.persist(persisted)
            requireAccepted(messenger.command(envelope(attempt, references, RolloutCommand.Commit), commandTimeout), stale)
            persisted = persisted.copy(phase = RolloutPhase.STABILIZING)
            state.persist(persisted)
            awaitStableHealthy(attempt, references)
            state.commit(CommittedDeployment(deployment.snapshot, expected))
            state.persist(persisted.copy(phase = RolloutPhase.SUCCEEDED))
        } catch (failure: Throwable) {
            compensate(persisted, failure)
            throw failure
        }
    }

    /** Records failure and drives abort or exact baseline rollback before rethrowing the original failure. */
    private suspend fun compensate(
        rollout: PersistedRollout,
        failure: Throwable,
    ) {
        val participants = rollout.projections.keys
        if (participants.isEmpty()) {
            state.persist(rollout.copy(phase = RolloutPhase.FAILED, failure = failure.message))
            return
        }
        if (rollout.phase < RolloutPhase.COMMITTING) {
            state.persist(rollout.copy(phase = RolloutPhase.ABORTING, failure = failure.message))
            messenger.command(envelope(rollout.attempt, rollout.projections, RolloutCommand.Abort), commandTimeout)
        } else {
            val targets =
                participants.associateWith { host ->
                    rollout.previous[host]?.let(RollbackTarget::Projection) ?: RollbackTarget.Empty
                }
            state.persist(rollout.copy(phase = RolloutPhase.ROLLING_BACK, failure = failure.message))
            messenger.command(
                envelope(rollout.attempt, rollout.projections, RolloutCommand.Rollback(targets)),
                commandTimeout,
            )
        }
        awaitRecovered(rollout.attempt, rollout.previous, participants)
        state.persist(rollout.copy(phase = RolloutPhase.FAILED, failure = failure.message))
    }

    private suspend fun awaitRecovered(
        attempt: RolloutAttempt,
        previous: Map<ServiceId, ProjectionReference>,
        participants: Set<ServiceId>,
    ) = awaitStatuses(attempt, participants) { host, status ->
        val target = previous[host]
        if (target == null) {
            status is ParticipantStatus.Idle
        } else {
            status is ParticipantStatus.Active &&
                status.current.projection == target &&
                status.current.health == RuntimeHealthSnapshot.Healthy
        }
    }

    /** Uses a fresh probe to define the responding participant set for this attempt. */
    private suspend fun discoverParticipants(): RolloutParticipants {
        val probe = ProbeRealmHosts(realmId)
        val selected = selection.selectedServices()
        val responding =
            messenger
                .discover(probe, selected, requestTimeout)
                .filter { it.probeId == probe.probeId && it.serviceId in selected }
                .associateBy(RealmHostPresence::serviceId)
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

    private fun envelope(
        attempt: RolloutAttempt,
        references: Map<ServiceId, ProjectionReference>,
        command: RolloutCommand,
    ) = RolloutEnvelope(realmId, attempt, references.keys, references, command)

    private fun Map<ServiceId, RealmHostPresence>.baselines(): Map<ServiceId, ProjectionReference> =
        mapNotNull { (host, presence) -> presence.activeProjection?.projection?.let { host to it } }.toMap()

    private fun requireAccepted(
        replies: List<CommandAcceptance>,
        expected: Set<ServiceId>,
    ) {
        val byService = replies.associateBy(CommandAcceptance::serviceId)
        require(byService.keys.containsAll(expected)) { "Not every rollout participant replied." }
        require(expected.all { byService.getValue(it).accepted }) { "A rollout participant rejected the command." }
    }

    /** Requires every participant to report the requested projection as healthy continuously for [healthyDuration]. */
    private suspend fun awaitStableHealthy(
        attempt: RolloutAttempt,
        references: Map<ServiceId, ProjectionReference>,
    ) {
        var healthySince: TimeMark? = null
        val deadline = timeSource.markNow()
        while (deadline.elapsedNow() < participantDeadline) {
            val statuses = messenger.statuses(ProbeParticipantStatus(realmId, attempt), references.keys, requestTimeout)
            val allHealthy =
                references.all { (host, reference) ->
                    val status = statuses[host]
                    status is ParticipantStatus.Active &&
                        status.current.projection == reference &&
                        status.current.health == RuntimeHealthSnapshot.Healthy
                }
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
            val statuses = messenger.statuses(ProbeParticipantStatus(realmId, attempt), participants, requestTimeout)
            if (participants.all { host -> statuses[host]?.let { condition(host, it) } == true }) return
            delay(100)
        }
        error("Timed out waiting for rollout participants.")
    }
}

/** Responding selected hosts for one rollout probe, including the required Realm host. */
data class RolloutParticipants(
    val hosts: Map<ServiceId, RealmHostPresence>,
)
