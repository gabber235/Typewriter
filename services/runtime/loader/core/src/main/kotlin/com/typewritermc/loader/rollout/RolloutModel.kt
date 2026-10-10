package com.typewritermc.loader.rollout

import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.registrar.ServiceId
import kotlinx.serialization.Serializable
import java.util.UUID

/**
 * Shared state model for Realm deployment rollout.
 *
 * The coordinator publishes immutable projection references, participants apply them locally, and status probes
 * verify attempt and health state. These serializable values are also the payload model for the rollout messaging
 * contracts in the rollout communication module.
 *
 * [RealmId] identifies the Realm whose hosts participate in a rollout.
 */
@JvmInline
@Serializable
value class RealmId(
    val value: String,
)

/** Requests presence from hosts assigned to a Realm, using [probeId] to reject replies from another probe. */
@Serializable
data class ProbeRealmHosts(
    val realmId: RealmId,
    val probeId: String = UUID.randomUUID().toString(),
)

/** Requests one participant status for a specific coordinator attempt. */
@Serializable
data class ProbeParticipantStatus(
    val realmId: RealmId,
    val attempt: RolloutAttempt,
)

/** Separates a participant status from a host side failure in scatter responses. */
@Serializable
sealed interface ParticipantStatusReply {
    val serviceId: ServiceId

    @Serializable
    data class Status(
        override val serviceId: ServiceId,
        val status: ParticipantStatus,
    ) : ParticipantStatusReply

    @Serializable
    data class InternalFailure(
        override val serviceId: ServiceId,
        val reason: String,
    ) : ParticipantStatusReply
}

/**
 * Pins one host generation to immutable projection bytes.
 *
 * Validate Realm, host, and generation after decoding. Runtime versions support reporting but do not replace
 * digest verification.
 */
@Serializable
data class ProjectionReference(
    val realmId: RealmId,
    val generation: DeploymentGeneration,
    val serviceId: ServiceId,
    val blob: ArtifactDigest,
    val runtimeVersions: Map<RuntimePlacement, ArtifactVersion> = emptyMap(),
)

/** Reports runtime health independently from whether a projection is merely staged or active. */
@Serializable
sealed interface RuntimeHealthSnapshot {
    @Serializable
    data object Staged : RuntimeHealthSnapshot

    @Serializable
    data object Healthy : RuntimeHealthSnapshot

    @Serializable
    data class Unhealthy(
        val reasons: List<String>,
    ) : RuntimeHealthSnapshot {
        init {
            require(reasons.isNotEmpty()) { "Unhealthy runtime state must include a reason." }
        }
    }
}

/** Identifies the projection currently active on a host and its observed health. */
@Serializable
data class ActiveProjectionReference(
    val projection: ProjectionReference,
    val health: RuntimeHealthSnapshot,
)

/** Snapshot returned by discovery, used to select responding participants and recovery baselines. */
@Serializable
data class RealmHostPresence(
    val probeId: String,
    val serviceId: ServiceId,
    val hostApi: ArtifactVersion,
    val assignedRoles: Set<RuntimePlacement>,
    val activeProjection: ActiveProjectionReference?,
)

/** Reports whether a host could answer a presence probe. */
@Serializable
sealed interface PresenceReply {
    @Serializable
    data class Present(
        val presence: RealmHostPresence,
    ) : PresenceReply

    @Serializable
    data class Failed(
        val reason: String,
    ) : PresenceReply
}

/**
 * Distinguishes coordinator attempts, including retries of the same generation.
 *
 * The positive ordinal fences stale commands; generation alone is not an attempt identity.
 */
@Serializable
data class RolloutAttempt(
    val ordinal: Long,
    val generation: DeploymentGeneration,
) {
    init {
        require(ordinal > 0) { "Rollout attempt ordinal must be positive." }
    }
}

/** Provides stable command names for telemetry and failed command reporting. */
@Serializable
enum class RolloutCommandKind {
    STAGE,
    COMMIT,
    ABORT,
    ROLLBACK,
}

/**
 * Specifies whether a participant must restore an empty state or an exact retained projection.
 *
 * Recovery never means selecting whichever artifact version happens to be newest.
 */
@Serializable
sealed interface RollbackTarget {
    @Serializable
    data object Empty : RollbackTarget

    @Serializable
    data class Projection(
        val reference: ProjectionReference,
    ) : RollbackTarget
}

/** A participant lifecycle command bound to one exact projection reference. */
@Serializable
sealed interface RolloutCommand {
    val kind: RolloutCommandKind

    @Serializable
    data object Stage : RolloutCommand {
        override val kind = RolloutCommandKind.STAGE
    }

    @Serializable
    data object Commit : RolloutCommand {
        override val kind = RolloutCommandKind.COMMIT
    }

    @Serializable
    data object Abort : RolloutCommand {
        override val kind = RolloutCommandKind.ABORT
    }

    @Serializable
    data class Rollback(
        val targets: Map<ServiceId, RollbackTarget>,
    ) : RolloutCommand {
        override val kind = RolloutCommandKind.ROLLBACK
    }
}

/**
 * Binds a command to participants and their exact projections.
 *
 * Every participant needs a projection and rollback needs an explicit recovery target. Participants additionally
 * validate attempt ordering and local lifecycle state.
 */
@Serializable
data class RolloutEnvelope(
    val realmId: RealmId,
    val attempt: RolloutAttempt,
    val participants: Set<ServiceId>,
    val projections: Map<ServiceId, ProjectionReference>,
    val command: RolloutCommand,
) {
    init {
        require(projections.keys.containsAll(participants)) { "Every participant requires an exact projection reference." }
        val rollback = command as? RolloutCommand.Rollback
        require(rollback == null || rollback.targets.keys.containsAll(participants)) {
            "Every rollback participant requires an explicit recovery target."
        }
    }
}

/**
 * Reports command handling separately from sustained runtime health.
 *
 * The coordinator still probes status and waits for a healthy interval before committing the deployment.
 */
@Serializable
data class CommandAcceptance(
    val serviceId: ServiceId,
    val accepted: Boolean,
    val reason: String? = null,
    val internalFailure: Boolean = false,
)

/** Describes the projection active before the candidate was staged. */
@Serializable
sealed interface ActiveBaseline {
    @Serializable
    data object Empty : ActiveBaseline

    @Serializable
    data class Present(
        val projection: ActiveProjectionReference,
    ) : ActiveBaseline
}

/** Identifies the one prior projection retained for rollback after activation. */
@Serializable
sealed interface RetainedProjection {
    @Serializable
    data object None : RetainedProjection

    @Serializable
    data class Present(
        val projection: ProjectionReference,
    ) : RetainedProjection
}

/**
 * Describes resources retained after a participant command fails.
 *
 * Recovery distinguishes empty, active, and staged states instead of assuming every failure leaves the same
 * baseline.
 */
@Serializable
sealed interface RecoverableParticipantState {
    @Serializable
    data object Empty : RecoverableParticipantState

    @Serializable
    data class Active(
        val current: ActiveProjectionReference,
        val retained: RetainedProjection,
    ) : RecoverableParticipantState

    @Serializable
    data class Staged(
        val candidate: ProjectionReference,
        val baseline: ActiveBaseline,
    ) : RecoverableParticipantState
}

/**
 * Reports lifecycle progress for one host attempt, including health and retained recovery state.
 *
 * Consumers must compare attempt and exact projection before treating an observation as confirmation. Active does
 * not necessarily mean healthy.
 */
@Serializable
sealed interface ParticipantStatus {
    val attempt: RolloutAttempt
    val serviceId: ServiceId

    @Serializable
    data class Idle(
        override val attempt: RolloutAttempt,
        override val serviceId: ServiceId,
    ) : ParticipantStatus

    @Serializable
    data class Staging(
        override val attempt: RolloutAttempt,
        override val serviceId: ServiceId,
        val candidate: ProjectionReference,
        val baseline: ActiveBaseline,
    ) : ParticipantStatus

    @Serializable
    data class Staged(
        override val attempt: RolloutAttempt,
        override val serviceId: ServiceId,
        val candidate: ProjectionReference,
        val baseline: ActiveBaseline,
    ) : ParticipantStatus

    @Serializable
    data class Committing(
        override val attempt: RolloutAttempt,
        override val serviceId: ServiceId,
        val candidate: ProjectionReference,
        val baseline: ActiveBaseline,
    ) : ParticipantStatus

    @Serializable
    data class Active(
        override val attempt: RolloutAttempt,
        override val serviceId: ServiceId,
        val current: ActiveProjectionReference,
        val retained: RetainedProjection,
    ) : ParticipantStatus

    @Serializable
    data class Aborting(
        override val attempt: RolloutAttempt,
        override val serviceId: ServiceId,
        val candidate: ProjectionReference,
        val baseline: ActiveBaseline,
    ) : ParticipantStatus

    @Serializable
    data class RollingBack(
        override val attempt: RolloutAttempt,
        override val serviceId: ServiceId,
        val failed: ProjectionReference,
        val target: RollbackTarget,
    ) : ParticipantStatus

    @Serializable
    data class Failed(
        override val attempt: RolloutAttempt,
        override val serviceId: ServiceId,
        val command: RolloutCommandKind,
        val recoverable: RecoverableParticipantState,
        val reason: String,
    ) : ParticipantStatus
}

/** Carries a participant lifecycle observation to coordinator persistence. */
@Serializable
data class ParticipantStateChanged(
    val realmId: RealmId,
    val status: ParticipantStatus,
)

/** Durable coordinator phases, including compensation after activation failure. */
@Serializable
enum class RolloutPhase {
    PROPOSED,
    DISCOVERING,
    STAGING,
    COMMITTING,
    STABILIZING,
    SUCCEEDED,
    ABORTING,
    ROLLING_BACK,
    FAILED,
}

/**
 * Journals coordinator phase and participant baselines for one attempt.
 *
 * This is separate from the committed deployment; reaching a command phase does not prove stability.
 */
@Serializable
data class PersistedRollout(
    val realmId: RealmId,
    val attempt: RolloutAttempt,
    val phase: RolloutPhase,
    val projections: Map<ServiceId, ProjectionReference>,
    val previous: Map<ServiceId, ProjectionReference>,
    val failure: String? = null,
)

/**
 * Records a snapshot and host projections accepted after rollout stability checks.
 *
 * Reconciliation repairs hosts to this selection without choosing new artifact content.
 */
@Serializable
data class CommittedDeployment(
    val snapshot: com.typewritermc.loader.deployment.DeploymentSnapshot,
    val projections: Map<ServiceId, ProjectionReference>,
)
