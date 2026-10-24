package com.typewritermc.realm.checking

import com.typewritermc.authoring.CheckExecutionId
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.configuration.RuleId
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe

val CheckAdmissionTest by testSuite {
    val id = ResourceId("page")
    val instance = CheckInstanceId(RuleId(RuleOrigin(TEST_TYPE, 0), 0), ValueLocation(id, ValuePath()))
    test("current admission installs evidence only while values and execution still match") {
        val catalog = TestCatalogLease()
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(mapOf(id to record(name = "Quest"))))
        var ticket = CheckTicket(instance, "catalog", CheckExecutionId("first"), catalog.generation)
        val result =
            CheckResult(
                ticket,
                CheckOutcome.Finished,
                listOf(EditExpectation.Value(location(id, "name"), DataValue.StringValue("Quest"))),
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
        ticket = ticket.copy(execution = CheckExecutionId("replacement"))
        admission.requireCurrentExecutionAndInputs(result) { installed++ } shouldBe AdmissionResult.Discarded
        installed shouldBe 2
        store.close()
    }
    test("captured acceptance compares with its retained view and requires finished checks") {
        val catalog = TestCatalogLease()
        val store = InMemoryAuthoringViewStore(catalog, AuthoringSeed(mapOf(id to record(name = "Quest"))))
        store.capture().use { captured ->
            val ticket = CheckTicket(instance, "catalog", CheckExecutionId("first"), catalog.generation)
            val result =
                CheckResult(
                    ticket,
                    CheckOutcome.Finished,
                    listOf(EditExpectation.Value(location(id, "name"), DataValue.StringValue("Quest"))),
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
            admission.requireEvidenceForCapture(result.copy(outcome = CheckOutcome.Incomplete("interrupted")), target) shouldBe
                AdmissionResult.RetryRequired
        }
        store.close()
    }
}
