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
        assertEquals(AdmissionResult.Published, admission.requireCurrentExecutionAndInputs(result) { installed++ })
        store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Story")))))
        assertEquals(AdmissionResult.RetryRequired, admission.requireCurrentExecutionAndInputs(result) { installed++ })
        store.install(store.prepare(AuthoringViewDelta(mapOf(id to record(name = "Quest")))))
        assertEquals(AdmissionResult.Published, admission.requireCurrentExecutionAndInputs(result) { installed++ })
        ticket = ticket.copy(execution = CheckExecutionId("replacement"))
        assertEquals(AdmissionResult.Discarded, admission.requireCurrentExecutionAndInputs(result) { installed++ })
        assertEquals(2, installed)
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
            assertEquals(AdmissionResult.Captured, admission.requireEvidenceForCapture(result, target))
            assertEquals(
                AdmissionResult.RetryRequired,
                admission.requireEvidenceForCapture(result.copy(outcome = CheckOutcome.Incomplete("interrupted")), target),
            )
        }
        store.close()
    }
}
