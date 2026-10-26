package com.typewritermc.realm.checking

import com.typewritermc.authoring.of
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.authoring.TEST_TYPE
import com.typewritermc.realm.authoring.TestCatalogLease
import com.typewritermc.realm.authoring.location
import com.typewritermc.realm.authoring.record
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.authoring_facts.EditExpectation
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckResult
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.type_catalog.CatalogGeneration
import skirout.editor.v1.type_catalog.CheckExecutionId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ValueLocation
import skirout.kernel.v1.resource_id.ResourceId

private val page = ResourceId(value = "page")
private val instance =
    CheckInstanceId(
        rule = RuleId(origin = RuleOrigin(owner = TEST_TYPE, ordinal = 0), localIndex = 0),
        location = ValueLocation.of(page),
    )
private val catalog = CatalogGeneration(value = "catalog")
private val first =
    CheckTicket(instance = instance, incarnation = "catalog", execution = CheckExecutionId(value = "first"), catalog = catalog)

/** A finished check result of [ticket] that read the page name as [name]. */
private fun resultOf(
    ticket: CheckTicket = first,
    name: String = "Quest",
    outcome: CheckOutcome = CheckOutcome.FINISHED,
) = CheckResult(
    ticket = ticket,
    outcome = outcome,
    expectations = listOf(EditExpectation.createValue(at = location(page, "name"), expected = DataValue.StringValueWrapper(name))),
    findings = emptyList(),
)

/** Runs [test] with a view store whose page is named [name], admitting against [current] as the latest execution. */
private fun admitting(
    name: String = "Quest",
    current: CheckTicket = first,
    test: (InMemoryAuthoringViewStore, DefaultCheckAdmission) -> Unit,
) {
    InMemoryAuthoringViewStore(TestCatalogLease(catalog), AuthoringSeed(mapOf(page to record(name = name)))).use { store ->
        val executions =
            object : CurrentCheckExecutions {
                override fun ticket(instance: CheckInstanceId) = current
            }
        test(store, DefaultCheckAdmission(store, executions))
    }
}

/** Admits [result] as current findings and reports whether it was installed. */
private fun DefaultCheckAdmission.publish(result: CheckResult): Pair<AdmissionResult, Boolean> {
    var installed = false
    return requireCurrentExecutionAndInputs(result) { installed = true } to installed
}

val CheckAdmissionTest by testSuite {
    test("findings of the current execution whose inputs still match are published") {
        admitting { _, admission ->
            admission.publish(resultOf()) shouldBe (AdmissionResult.Published to true)
        }
    }

    test("findings whose saved inputs changed since the check read them require a retry") {
        admitting(name = "Story") { _, admission ->
            admission.publish(resultOf(name = "Quest")) shouldBe (AdmissionResult.RetryRequired to false)
        }
    }

    test("findings from an older catalog generation require a retry instead of publishing") {
        val older = first.copy(catalog = CatalogGeneration(value = "older"))
        admitting(current = older) { _, admission ->
            admission.publish(resultOf(ticket = older)) shouldBe (AdmissionResult.RetryRequired to false)
        }
    }

    test("findings of an execution that was replaced are discarded") {
        admitting(current = first.copy(execution = CheckExecutionId(value = "replacement"))) { _, admission ->
            admission.publish(resultOf()) shouldBe (AdmissionResult.Discarded to false)
        }
    }

    test("captured acceptance reuses finished evidence matching the captured view even after a later edit") {
        admitting { store, admission ->
            store.capture().use { captured ->
                store.install(store.prepare(AuthoringViewDelta(mapOf(page to record(name = "Story")))))
                admission.requireEvidenceForCapture(resultOf(), CheckAdmissionTarget.CapturedAcceptance(captured.root)) shouldBe
                    AdmissionResult.Captured
            }
        }
    }

    test("captured acceptance requires a retry for evidence of an unfinished check") {
        admitting { store, admission ->
            store.capture().use { captured ->
                val interrupted = resultOf(outcome = CheckOutcome.IncompleteWrapper("interrupted"))
                admission.requireEvidenceForCapture(interrupted, CheckAdmissionTarget.CapturedAcceptance(captured.root)) shouldBe
                    AdmissionResult.RetryRequired
            }
        }
    }

    test("captured acceptance requires a retry for evidence that conflicts with the captured view") {
        admitting { store, admission ->
            store.capture().use { captured ->
                val conflicting = resultOf(name = "Story")
                admission.requireEvidenceForCapture(conflicting, CheckAdmissionTarget.CapturedAcceptance(captured.root)) shouldBe
                    AdmissionResult.RetryRequired
            }
        }
    }

    test("captured acceptance discards evidence checked on another catalog") {
        admitting { store, admission ->
            store.capture().use { captured ->
                val other = resultOf(ticket = first.copy(catalog = CatalogGeneration(value = "other")))
                admission.requireEvidenceForCapture(other, CheckAdmissionTarget.CapturedAcceptance(captured.root)) shouldBe
                    AdmissionResult.Discarded
            }
        }
    }
}
