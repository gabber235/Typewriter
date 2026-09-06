package com.typewritermc.loader.rollout

import com.typewritermc.imprint.ArtifactVersion
import com.typewritermc.loader.api.RuntimePlacement
import com.typewritermc.loader.artifact.ArtifactDigest
import com.typewritermc.loader.deployment.DeploymentGeneration
import com.typewritermc.loader.deployment.HostDeploymentProjection
import com.typewritermc.loader.deployment.HostId
import kotlinx.serialization.Serializable
import java.util.UUID

@JvmInline
@Serializable
value class RealmId(
    val value: String,
)

@Serializable
data class ProbeRealmHosts(
    val realmId: RealmId,
    val probeId: String = UUID.randomUUID().toString(),
)

@Serializable
data class ProbeParticipantStatus(
    val realmId: RealmId,
    val attempt: RolloutAttempt,
)

@Serializable
sealed interface ParticipantStatusReply {
    val hostId: HostId

    @Serializable
    data class Status(
        override val hostId: HostId,
        val status: ParticipantStatus,
    ) : ParticipantStatusReply

    @Serializable
    data class InternalFailure(
        override val hostId: HostId,
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
    val hostId: HostId,
    val blob: ArtifactDigest,
    val runtimeVersions: Map<RuntimePlacement, ArtifactVersion> = emptyMap(),
)

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

@Serializable
data class ActiveProjectionReference(
    val projection: ProjectionReference,
    val health: RuntimeHealthSnapshot,
)

@Serializable
data class RealmHostPresence(
    val probeId: String,
    val hostId: HostId,
    val hostApi: ArtifactVersion,
    val assignedRoles: Set<RuntimePlacement>,
    val activeProjection: ActiveProjectionReference?,
)

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
        val targets: Map<HostId, RollbackTarget>,
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
    val participants: Set<HostId>,
    val projections: Map<HostId, ProjectionReference>,
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
    val hostId: HostId,
    val accepted: Boolean,
    val reason: String? = null,
    val internalFailure: Boolean = false,
)

@Serializable
sealed interface ActiveBaseline {
    @Serializable
    data object Empty : ActiveBaseline

    @Serializable
    data class Present(
        val projection: ActiveProjectionReference,
    ) : ActiveBaseline
}

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
    val hostId: HostId

    @Serializable
    data class Idle(
        override val attempt: RolloutAttempt,
        override val hostId: HostId,
    ) : ParticipantStatus

    @Serializable
    data class Staging(
        override val attempt: RolloutAttempt,
        override val hostId: HostId,
        val candidate: ProjectionReference,
        val baseline: ActiveBaseline,
    ) : ParticipantStatus

    @Serializable
    data class Staged(
        override val attempt: RolloutAttempt,
        override val hostId: HostId,
        val candidate: ProjectionReference,
        val baseline: ActiveBaseline,
    ) : ParticipantStatus

    @Serializable
    data class Committing(
        override val attempt: RolloutAttempt,
        override val hostId: HostId,
        val candidate: ProjectionReference,
        val baseline: ActiveBaseline,
    ) : ParticipantStatus

    @Serializable
    data class Active(
        override val attempt: RolloutAttempt,
        override val hostId: HostId,
        val current: ActiveProjectionReference,
        val retained: RetainedProjection,
    ) : ParticipantStatus

    @Serializable
    data class Aborting(
        override val attempt: RolloutAttempt,
        override val hostId: HostId,
        val candidate: ProjectionReference,
        val baseline: ActiveBaseline,
    ) : ParticipantStatus

    @Serializable
    data class RollingBack(
        override val attempt: RolloutAttempt,
        override val hostId: HostId,
        val failed: ProjectionReference,
        val target: RollbackTarget,
    ) : ParticipantStatus

    @Serializable
    data class Failed(
        override val attempt: RolloutAttempt,
        override val hostId: HostId,
        val command: RolloutCommandKind,
        val recoverable: RecoverableParticipantState,
        val reason: String,
    ) : ParticipantStatus
}

@Serializable
data class ParticipantStateChanged(
    val realmId: RealmId,
    val status: ParticipantStatus,
)

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
    val projections: Map<HostId, ProjectionReference>,
    val previous: Map<HostId, ProjectionReference>,
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
    val projections: Map<HostId, ProjectionReference>,
)
