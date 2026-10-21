package com.typewritermc.loader.rollout

import com.typewritermc.loader.api.RuntimeHealth
import com.typewritermc.loader.api.RuntimePlacement
import skirout.service.v1.rollout.ApplyRolloutCommandRequest
import skirout.service.v1.rollout.ApplyRolloutCommandResponse
import skirout.service.v1.rollout.ProjectionHealth
import skirout.service.v1.rollout.ProjectionReference
import skirout.service.v1.rollout.RollbackTarget
import skirout.service.v1.rollout.RolloutAttempt
import skirout.service.v1.rollout.RolloutCommand
import skirout.service.v1.rollout.RolloutCommandKind
import skirout.service.v1.rollout.RuntimePlacement as RolloutPlacement

/** Requires the positive ordinal that fences stale commands. */
internal fun RolloutAttempt.requireValid(): RolloutAttempt = apply { require(ordinal > 0) { "Rollout attempt ordinal must be positive." } }

/**
 * Requires a known command for a valid attempt whose every participant entry names its own projection and, for a
 * rollback, an explicit recovery target.
 */
internal fun ApplyRolloutCommandRequest.requireValid(): ApplyRolloutCommandRequest =
    apply {
        attempt.requireValid()
        require(command.kind != RolloutCommand.Kind.UNKNOWN) { "Rollout command is unknown." }
        require(command.serviceIds.all { command.projectionOf(it)?.serviceId == it }) {
            "Every participant requires its own exact projection reference."
        }
        val rollback = command as? RolloutCommand.RollBackWrapper
        require(rollback == null || rollback.value.participants.all { it.target.kind != RollbackTarget.Kind.UNKNOWN }) {
            "Every rollback participant requires an explicit recovery target."
        }
    }

/** The service identities of every participant the command lists. */
internal val RolloutCommand.serviceIds: Set<String>
    get() =
        when (this) {
            is RolloutCommand.StageWrapper -> value.participants.mapTo(linkedSetOf()) { it.serviceId }
            is RolloutCommand.CommitWrapper -> value.participants.mapTo(linkedSetOf()) { it.serviceId }
            is RolloutCommand.AbortWrapper -> value.participants.mapTo(linkedSetOf()) { it.serviceId }
            is RolloutCommand.RollBackWrapper -> value.participants.mapTo(linkedSetOf()) { it.serviceId }
            else -> emptySet()
        }

/** The exact projection the command binds to [serviceId], or null when the command does not list that host. */
internal fun RolloutCommand.projectionOf(serviceId: String): ProjectionReference? =
    when (this) {
        is RolloutCommand.StageWrapper -> value.participants.findByKey(serviceId)?.projection
        is RolloutCommand.CommitWrapper -> value.participants.findByKey(serviceId)?.projection
        is RolloutCommand.AbortWrapper -> value.participants.findByKey(serviceId)?.projection
        is RolloutCommand.RollBackWrapper -> value.participants.findByKey(serviceId)?.projection
        else -> null
    }

/** The stable command name used by telemetry and failed participant phases. */
internal val RolloutCommand.commandKind: RolloutCommandKind
    get() =
        when (this) {
            is RolloutCommand.StageWrapper -> RolloutCommandKind.STAGE
            is RolloutCommand.CommitWrapper -> RolloutCommandKind.COMMIT
            is RolloutCommand.AbortWrapper -> RolloutCommandKind.ABORT
            is RolloutCommand.RollBackWrapper -> RolloutCommandKind.ROLL_BACK
            else -> RolloutCommandKind.UNKNOWN
        }

/** The Skir variant name of a command kind, such as `roll_back`, for telemetry. */
internal val RolloutCommandKind.label: String
    get() =
        when (this) {
            RolloutCommandKind.STAGE -> "stage"
            RolloutCommandKind.COMMIT -> "commit"
            RolloutCommandKind.ABORT -> "abort"
            RolloutCommandKind.ROLL_BACK -> "roll_back"
            else -> "unknown"
        }

/** The host a command reply names; only the internal error fallback is unattributed. */
internal val ApplyRolloutCommandResponse.serviceId: String?
    get() =
        when (this) {
            is ApplyRolloutCommandResponse.AcceptedWrapper -> value.serviceId
            is ApplyRolloutCommandResponse.StaleAttemptErrorWrapper -> value.serviceId
            is ApplyRolloutCommandResponse.AttemptConflictErrorWrapper -> value.serviceId
            is ApplyRolloutCommandResponse.CommandRejectedErrorWrapper -> value.serviceId
            is ApplyRolloutCommandResponse.CommandFailedErrorWrapper -> value.serviceId
            else -> null
        }

/** The artifact version this projection runs in [placement], when the projection hosts that placement. */
internal fun ProjectionReference.runtimeVersion(placement: RuntimePlacement): String? =
    runtimeVersions.findByKey(placement.toSkir().kind)?.version

internal fun RuntimePlacement.toSkir(): RolloutPlacement =
    when (this) {
        RuntimePlacement.REALM -> RolloutPlacement.REALM
        RuntimePlacement.PANEL_ENGINE -> RolloutPlacement.PANEL_ENGINE
        RuntimePlacement.PRIMARY_ENGINE -> RolloutPlacement.PRIMARY_ENGINE
    }

/** The local placement of a contract placement, or null for a placement this loader does not know. */
internal fun RolloutPlacement.toApi(): RuntimePlacement? =
    when (this) {
        RolloutPlacement.REALM -> RuntimePlacement.REALM
        RolloutPlacement.PANEL_ENGINE -> RuntimePlacement.PANEL_ENGINE
        RolloutPlacement.PRIMARY_ENGINE -> RuntimePlacement.PRIMARY_ENGINE
        else -> null
    }

/** Combines runtime health: any unhealthy runtime makes the projection unhealthy, and only all healthy is healthy. */
internal fun List<RuntimeHealth>.toProjectionHealth(): ProjectionHealth {
    val unhealthy = filterIsInstance<RuntimeHealth.Unhealthy>()
    return when {
        unhealthy.isNotEmpty() -> ProjectionHealth.createUnhealthy(reasons = unhealthy.map(RuntimeHealth.Unhealthy::reason))
        all { it == RuntimeHealth.Healthy } -> ProjectionHealth.HEALTHY
        else -> ProjectionHealth.STAGED
    }
}
