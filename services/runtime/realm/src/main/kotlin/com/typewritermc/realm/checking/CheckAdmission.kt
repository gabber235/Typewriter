package com.typewritermc.realm.checking

import com.typewritermc.authoring.CheckExecutionId
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.checking.Diagnostic
import com.typewritermc.checking.FindingStatus
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputObservation
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.SnapshotId
import com.typewritermc.configuration.RuleId
import com.typewritermc.realm.authoring.AuthoringSnapshotStore
import com.typewritermc.realm.authoring.absentInputToken

data class CheckInstanceId(
    val rule: RuleId,
    val location: ValueLocation,
)

data class CheckTicket(
    val instance: CheckInstanceId,
    val incarnation: String,
    val execution: CheckExecutionId,
    val snapshot: SnapshotId,
    val catalog: CatalogGeneration,
)

data class CheckResult(
    val ticket: CheckTicket,
    val outcome: CheckOutcome,
    val observations: List<InputObservation>,
    val findings: List<Diagnostic>,
)

data class FindingSet(
    val ticket: CheckTicket,
    val observations: List<InputObservation>,
    val outcome: CheckOutcome,
    val findings: List<Diagnostic>,
    val status: FindingStatus,
)

sealed interface CheckAdmissionTarget {
    data object CurrentFindings : CheckAdmissionTarget

    data class CapturedAcceptance(
        val snapshot: SnapshotId,
        val catalog: CatalogGeneration,
    ) : CheckAdmissionTarget
}

sealed interface AdmissionResult {
    data object Published : AdmissionResult

    data object Captured : AdmissionResult

    data object Discarded : AdmissionResult

    data object RetryRequired : AdmissionResult
}

interface CheckAdmission {
    fun requireCurrentExecutionAndInputs(result: CheckResult): AdmissionResult

    fun requireEvidenceForCapture(
        result: CheckResult,
        target: CheckAdmissionTarget.CapturedAcceptance,
    ): AdmissionResult
}

interface CurrentCheckExecutions {
    fun ticket(instance: CheckInstanceId): CheckTicket?
}

class DefaultCheckAdmission(
    private val snapshots: AuthoringSnapshotStore,
    private val executions: CurrentCheckExecutions,
) : CheckAdmission {
    override fun requireCurrentExecutionAndInputs(result: CheckResult): AdmissionResult {
        if (executions.ticket(result.ticket.instance) != result.ticket) return AdmissionResult.Discarded
        val evidenceMatches =
            snapshots.capture().use { current ->
                current.root.catalog.generation == result.ticket.catalog &&
                    result.observations.all { observation -> current.root.token(observation.identity) == observation.token }
            }
        if (executions.ticket(result.ticket.instance) != result.ticket) return AdmissionResult.Discarded
        if (!evidenceMatches) return AdmissionResult.RetryRequired
        return AdmissionResult.Published
    }

    override fun requireEvidenceForCapture(
        result: CheckResult,
        target: CheckAdmissionTarget.CapturedAcceptance,
    ): AdmissionResult {
        if (result.ticket.snapshot != target.snapshot || result.ticket.catalog != target.catalog) {
            return AdmissionResult.Discarded
        }
        if (result.outcome is CheckOutcome.Incomplete) return AdmissionResult.RetryRequired
        val lease =
            try {
                snapshots.retain(target.snapshot)
            } catch (_: IllegalArgumentException) {
                return AdmissionResult.RetryRequired
            }
        lease.use {
            if (it.root.catalog.generation != target.catalog) return AdmissionResult.Discarded
            val exact = result.observations.all { observation -> it.root.token(observation.identity) == observation.token }
            return if (exact) AdmissionResult.Captured else AdmissionResult.RetryRequired
        }
    }
}

fun CheckResult.admit(
    target: CheckAdmissionTarget,
    admission: CheckAdmission,
): AdmissionResult =
    when (target) {
        CheckAdmissionTarget.CurrentFindings -> admission.requireCurrentExecutionAndInputs(this)
        is CheckAdmissionTarget.CapturedAcceptance -> admission.requireEvidenceForCapture(this, target)
    }

private fun com.typewritermc.realm.authoring.AuthoredSnapshotRoot.token(identity: InputIdentity): InputToken =
    inputs[identity] ?: absentInputToken()
