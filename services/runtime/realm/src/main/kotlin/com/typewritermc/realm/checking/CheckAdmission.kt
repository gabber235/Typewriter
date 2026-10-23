package com.typewritermc.realm.checking

import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.conflicts
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckResult
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.diagnostic.Diagnostic

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
            if (current.catalog.generation != result.ticket.catalog ||
                current.values.conflicts(result.expectations).isNotEmpty()
            ) {
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
        if (result.outcome != CheckOutcome.FINISHED) return AdmissionResult.RetryRequired
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
