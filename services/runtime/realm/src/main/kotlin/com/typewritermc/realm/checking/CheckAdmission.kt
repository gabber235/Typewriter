package com.typewritermc.realm.checking

import com.typewritermc.authoring.CheckExecutionId
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.checking.Diagnostic
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.repository.conflicts
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.type_catalog.RuleId

data class CheckInstanceId(
    val rule: RuleId,
    val location: ValueLocation,
)

data class CheckTicket(
    val instance: CheckInstanceId,
    val incarnation: String,
    val execution: CheckExecutionId,
    val catalog: CatalogGeneration,
)

data class CheckResult(
    val ticket: CheckTicket,
    val outcome: CheckOutcome,
    val expectations: List<EditExpectation>,
    val findings: List<Diagnostic>,
)

data class FindingSet(
    val ticket: CheckTicket,
    val expectations: List<EditExpectation>,
    val outcome: CheckOutcome,
    val findings: List<Diagnostic>,
    val status: FindingStatus,
)

sealed interface CheckAdmissionTarget {
    data object CurrentFindings : CheckAdmissionTarget

    data class CapturedAcceptance(
        val view: AuthoringView,
    ) : CheckAdmissionTarget {
        val catalog get() = view.catalog.generation
    }
}

sealed interface AdmissionResult {
    data object Published : AdmissionResult

    data object Captured : AdmissionResult

    data object Discarded : AdmissionResult

    data object RetryRequired : AdmissionResult
}

interface CheckAdmission {
    fun requireCurrentExecutionAndInputs(
        result: CheckResult,
        install: () -> Unit = {},
    ): AdmissionResult

    fun requireEvidenceForCapture(
        result: CheckResult,
        target: CheckAdmissionTarget.CapturedAcceptance,
    ): AdmissionResult
}

interface CurrentCheckExecutions {
    fun ticket(instance: CheckInstanceId): CheckTicket?
}

/**
 * Separates installation of current editor findings from evidence reuse for a captured publication.
 *
 * Current findings require the latest execution ticket and unchanged saved inputs. Captured acceptance instead
 * requires a finished result matching the target catalog and captured facts, even if that execution is no longer
 * current in the editor. These checks admit evidence; they do not rerun the callback.
 */
class DefaultCheckAdmission(
    private val views: AuthoringViewStore,
    private val executions: CurrentCheckExecutions,
) : CheckAdmission {
    override fun requireCurrentExecutionAndInputs(
        result: CheckResult,
        install: () -> Unit,
    ): AdmissionResult =
        views.read { current ->
            if (executions.ticket(result.ticket.instance) != result.ticket) return@read AdmissionResult.Discarded
            if (current.catalog.generation != result.ticket.catalog || current.values.conflicts(result.expectations).isNotEmpty()) {
                return@read AdmissionResult.RetryRequired
            }
            install()
            AdmissionResult.Published
        }

    override fun requireEvidenceForCapture(
        result: CheckResult,
        target: CheckAdmissionTarget.CapturedAcceptance,
    ): AdmissionResult {
        if (result.ticket.catalog != target.catalog) return AdmissionResult.Discarded
        if (result.outcome != CheckOutcome.Finished) return AdmissionResult.RetryRequired
        return if (target.view.values
                .conflicts(result.expectations)
                .isEmpty()
        ) {
            AdmissionResult.Captured
        } else {
            AdmissionResult.RetryRequired
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
