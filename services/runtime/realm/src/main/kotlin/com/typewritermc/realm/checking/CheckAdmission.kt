package com.typewritermc.realm.checking

import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.skir.SkirAuthoringOperationCodec
import com.typewritermc.realm.authoring.AuthoringView
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.repository.conflicts
import com.typewritermc.types.skir.getOrThrow
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.checking.FindingSet
import skirout.editor.v1.diagnostic.Diagnostic
import skirout.editor.v1.authoring_facts.EditExpectation as SkirEditExpectation

/**
 * The outcome of one scheduled check execution. Its expectations stay Kotlin edit expectations until those are Skir
 * values; [FindingSet] stores their Skir form.
 */
data class CheckResult(
    val ticket: CheckTicket,
    val outcome: CheckOutcome,
    val expectations: List<EditExpectation>,
    val findings: List<Diagnostic>,
)

/** The Skir form of check expectations, which finding sets store, until edit expectations are Skir values. */
internal fun List<EditExpectation>.encodedExpectations(): List<SkirEditExpectation> =
    map {
        SkirAuthoringOperationCodec.encode(it).getOrThrow()
    }

/** The Kotlin form of stored finding expectations, which conflict checks read, until edit expectations are Skir values. */
internal fun List<SkirEditExpectation>.decodedExpectations(): List<EditExpectation> =
    map {
        SkirAuthoringOperationCodec.decode(it).getOrThrow()
    }

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
