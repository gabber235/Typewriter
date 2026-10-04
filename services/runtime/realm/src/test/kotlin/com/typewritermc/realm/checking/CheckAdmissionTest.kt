package com.typewritermc.realm.checking

import com.typewritermc.authoring.CheckExecutionId
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputObservation
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.SnapshotId
import com.typewritermc.configuration.RuleId
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.realm.authoring.AuthoredSnapshotSeed
import com.typewritermc.realm.authoring.AuthoredSnapshotView
import com.typewritermc.realm.authoring.AuthoringSnapshotDelta
import com.typewritermc.realm.authoring.AuthoringSnapshotStore
import com.typewritermc.realm.authoring.InMemoryAuthoringSnapshotStore
import com.typewritermc.realm.authoring.SnapshotLease
import com.typewritermc.types.ResourceId
import de.infix.testBalloon.framework.core.testSuite
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicReference
import kotlin.collections.AbstractMap

val CheckAdmissionTest by testSuite {
    test("currentAdmissionReadsEveryObservationFromOneCapturedRoot") {
        val fixture = admissionFixture()
        val racing = CapturedRootRaceStore(fixture.store) { fixture.installNext() }
        val executions =
            object : CurrentCheckExecutions {
                override fun ticket(instance: CheckInstanceId): CheckTicket = fixture.ticket
            }

        val admitted = DefaultCheckAdmission(racing, executions).requireCurrentExecutionAndInputs(fixture.result)

        assertEquals(AdmissionResult.Published, admitted)
        assertEquals(1, racing.captureCalls.get())
        assertEquals(0, racing.currentTokenCalls.get())
        assertEquals(SnapshotId("s1"), fixture.store.capture().use { it.root.id })
        fixture.store.close()
    }

    test("executionFenceRejectsResultWhenInvalidationRacesWithEvidenceCapture") {
        val fixture = admissionFixture()
        val current = AtomicReference(fixture.ticket)
        val racing =
            CapturedRootRaceStore(fixture.store) {
                fixture.installNext()
                current.set(fixture.ticket.copy(execution = CheckExecutionId("new"), snapshot = SnapshotId("s1")))
            }
        val executions =
            object : CurrentCheckExecutions {
                override fun ticket(instance: CheckInstanceId): CheckTicket = current.get()
            }

        val admitted = DefaultCheckAdmission(racing, executions).requireCurrentExecutionAndInputs(fixture.result)

        assertEquals(AdmissionResult.Discarded, admitted)
        fixture.store.close()
    }
}

private class AdmissionFixture(
    val store: InMemoryAuthoringSnapshotStore,
    val ticket: CheckTicket,
    val result: CheckResult,
    private val resource: ResourceId,
) {
    fun installNext() {
        store.install(
            AuthoringSnapshotDelta(
                snapshot = SnapshotId("s1"),
                upsertedResources = mapOf(resource to record(name = "beta", count = 2)),
                inputTokens =
                    mapOf(
                        InputIdentity.Value(ValueLocation(resource, ValuePath())) to InputToken("root1"),
                        InputIdentity.Value(location(resource, "name")) to InputToken("name1"),
                        InputIdentity.Value(location(resource, "count")) to InputToken("count1"),
                    ),
            ),
        )
    }
}

private fun admissionFixture(): AdmissionFixture {
    val catalog = TestCatalogLease()
    val resource = ResourceId("page")
    val initial = record(name = "alpha", count = 1)
    val tokens = tokensFor(mapOf(resource to initial), catalog.generation)
    val store =
        InMemoryAuthoringSnapshotStore(
            catalog,
            AuthoredSnapshotSeed(SnapshotId("s0"), mapOf(resource to initial), tokens),
        )
    val instance = CheckInstanceId(RuleId(RuleOrigin(TEST_TYPE, 0), 0), ValueLocation(resource, ValuePath()))
    val ticket = CheckTicket(instance, "catalog:0", CheckExecutionId("old"), SnapshotId("s0"), catalog.generation)
    val observations =
        listOf(
            InputObservation(
                InputIdentity.Value(location(resource, "name")),
                tokens.getValue(InputIdentity.Value(location(resource, "name"))),
            ),
            InputObservation(
                InputIdentity.Value(location(resource, "count")),
                tokens.getValue(InputIdentity.Value(location(resource, "count"))),
            ),
        )
    return AdmissionFixture(store, ticket, CheckResult(ticket, CheckOutcome.Finished, observations, emptyList()), resource)
}

private class CapturedRootRaceStore(
    private val delegate: AuthoringSnapshotStore,
    private val afterFirstObservation: () -> Unit,
) : AuthoringSnapshotStore by delegate {
    val captureCalls = AtomicInteger()
    val currentTokenCalls = AtomicInteger()

    override fun capture(): SnapshotLease {
        captureCalls.incrementAndGet()
        val captured = delegate.capture()
        val reads = AtomicInteger()
        val inputs =
            object : AbstractMap<InputIdentity, InputToken>() {
                override val entries: Set<Map.Entry<InputIdentity, InputToken>> = captured.root.inputs.entries

                override fun get(key: InputIdentity): InputToken? {
                    val value = captured.root.inputs[key]
                    if (reads.incrementAndGet() == 1) afterFirstObservation()
                    return value
                }
            }
        val capturedRoot = captured.root.copy(inputs = inputs)
        return object : SnapshotLease {
            override val root = capturedRoot

            override fun originalView(): AuthoredSnapshotView = AuthoredSnapshotView.Original(capturedRoot)

            override fun stagedView(
                upsertedResources: Map<ResourceId, com.typewritermc.authoring.AuthoringRecord>,
                removedResources: Set<ResourceId>,
            ): AuthoredSnapshotView = captured.stagedView(upsertedResources, removedResources)

            override fun close() = captured.close()
        }
    }

    override fun currentToken(identity: InputIdentity): InputToken {
        currentTokenCalls.incrementAndGet()
        return delegate.currentToken(identity)
    }
}
