package com.typewritermc.realm.checking

import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.of
import com.typewritermc.authoring.root
import com.typewritermc.checking.toSkir
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import skirout.editor.v1.checking.CheckInstanceId
import skirout.editor.v1.checking.CheckOutcome
import skirout.editor.v1.checking.CheckTicket
import skirout.editor.v1.type_catalog.CheckExecutionId
import skirout.editor.v1.type_catalog.DataValue
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.ValueLocation

val CheckAdmissionTest by testSuite {
    val id = ResourceId("page")
    val instance =
        CheckInstanceId(
            rule = RuleId(origin = RuleOrigin(owner = TEST_TYPE, ordinal = 0), localIndex = 0),
            location = ValueLocation.of(id),
        )
    test("current admission installs evidence only while values and execution still match") {
        val catalog = TestCatalogLease()
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(mapOf(id to record(name = "Quest"))))
        var ticket =
            CheckTicket(
                instance = instance,
                incarnation = "catalog",
                execution = CheckExecutionId(value = "first"),
                catalog = catalog.generation.toSkir(),
            )
        val result =
            CheckResult(
                ticket,
                CheckOutcome.FINISHED,
                listOf(EditExpectation.Value(location(id, "name"), DataValue.StringValueWrapper("Quest"))),
                emptyList(),
            )
        val admission =
            DefaultCheckAdmission(
                store,
                object : CurrentCheckExecutions {
                    override fun ticket(instance: CheckInstanceId) = ticket
                },
            )
        var installed = 0
        admission.requireCurrentExecutionAndInputs(result) { installed++ } shouldBe AdmissionResult.Published
        store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Story")))))
        admission.requireCurrentExecutionAndInputs(result) { installed++ } shouldBe AdmissionResult.RetryRequired
        store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Quest")))))
        admission.requireCurrentExecutionAndInputs(result) { installed++ } shouldBe AdmissionResult.Published
        ticket = ticket.copy(execution = CheckExecutionId(value = "replacement"))
        admission.requireCurrentExecutionAndInputs(result) { installed++ } shouldBe AdmissionResult.Discarded
        installed shouldBe 2
        store.close()
    }
    test("captured acceptance compares with its retained view and requires finished checks") {
        val catalog = TestCatalogLease()
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(mapOf(id to record(name = "Quest"))))
        store.capture().use { captured ->
            val ticket =
                CheckTicket(
                    instance = instance,
                    incarnation = "catalog",
                    execution = CheckExecutionId(value = "first"),
                    catalog = catalog.generation.toSkir(),
                )
            val result =
                CheckResult(
                    ticket,
                    CheckOutcome.FINISHED,
                    listOf(EditExpectation.Value(location(id, "name"), DataValue.StringValueWrapper("Quest"))),
                    emptyList(),
                )
            val admission =
                DefaultCheckAdmission(
                    store,
                    object : CurrentCheckExecutions {
                        override fun ticket(instance: CheckInstanceId) = ticket
                    },
                )
            store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Story")))))
            val target = CheckAdmissionTarget.CapturedAcceptance(captured.root)
            admission.requireEvidenceForCapture(result, target) shouldBe AdmissionResult.Captured
            admission.requireEvidenceForCapture(result.copy(outcome = CheckOutcome.IncompleteWrapper("interrupted")), target) shouldBe
                AdmissionResult.RetryRequired
        }
        store.close()
    }
}
