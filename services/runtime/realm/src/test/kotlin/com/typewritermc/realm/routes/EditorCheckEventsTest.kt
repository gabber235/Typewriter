package com.typewritermc.realm.routes

import com.typewritermc.authoring.AuthoringRecord
import com.typewritermc.authoring.BatchId
import com.typewritermc.authoring.CheckExecutionId
import com.typewritermc.authoring.RelationProjectionDelta
import com.typewritermc.authoring.ResourceDefinitionId
import com.typewritermc.authoring.TypeSelection
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.checking.FindingStatus
import com.typewritermc.checking.InputIdentity
import com.typewritermc.checking.InputObservation
import com.typewritermc.checking.InputToken
import com.typewritermc.checking.SnapshotId
import com.typewritermc.configuration.RuleId
import com.typewritermc.configuration.RuleOrigin
import com.typewritermc.realm.authoring.AuthoredSnapshotSeed
import com.typewritermc.realm.authoring.InMemoryAuthoringSnapshotStore
import com.typewritermc.realm.authoring.RESOURCE_SELECTION_INPUT
import com.typewritermc.realm.checking.CheckInstanceId
import com.typewritermc.realm.checking.CheckTicket
import com.typewritermc.realm.checking.FindingSet
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.realm.repository.AuthoringCommittedEvent
import com.typewritermc.realm.repository.AuthoringEventOutbox
import com.typewritermc.realm.repository.CommitDelta
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.types.DataValue
import com.typewritermc.types.ResourceId
import com.typewritermc.types.TypeDefinitionId
import com.typewritermc.types.TypeId
import com.typewritermc.types.TypeUse
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import skirout.editor.v1.authoring.AuthoringChanged
import skirout.editor.v1.authoring.AuthoringChangedTransferResult
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
val EditorCheckEventsTest by testSuite {
    test("startup drains the durable authoring backlog without a new commit signal") {
        runTest {
            val generation = CatalogGeneration("catalog")
            val snapshots = snapshots(generation)
            val event = committedEvent("batch", "snapshot_0", "snapshot_1", generation)
            val outbox = RecordingOutbox(event)
            val events = EditorCheckEvents(snapshots, outbox, backgroundScope)
            events.capture(snapshots.capture().use { it.root })

            try {
                RouteFixture { contracts, address, communicator ->
                    events.configure(contracts, address, communicator)
                    communicatorRoutes { }
                }.use { fixture ->
                    val changed = fixture.transport.awaitAuthoringChanges(outbox).single()
                    changed.previousSnapshot.value shouldBe "snapshot_0"
                    changed.snapshot.value shouldBe "snapshot_1"
                    changed.batch.value shouldBe "batch"
                    changed.resources shouldBe emptyList()
                    changed.changedObservations shouldBe emptyList()
                    outbox.acknowledged shouldBe listOf(BatchId("batch"))
                }
            } finally {
                events.close()
                snapshots.close()
            }
        }
    }

    test("a failed bounded part keeps the commit pending until the complete retry publishes") {
        runTest {
            val generation = CatalogGeneration("catalog")
            val snapshots = snapshots(generation)
            val event = largeCommittedEvent(generation)
            val outbox = RecordingOutbox(event)
            val events = EditorCheckEvents(snapshots, outbox, backgroundScope)
            events.capture(snapshots.capture().use { it.root })
            val transport = FailingPublishTransport(failAt = 2)
            val telemetry = TelemetryTestHarness.create()
            val address = RealmAddress("realm", "organization")

            try {
                events.configure(
                    EditorContracts(address),
                    address,
                    Communicator(transport, telemetry.telemetry, ContextPropagators.noop()),
                )
                withTimeout(2.seconds) {
                    while (transport.publishCalls < 2) yield()
                }
                outbox.acknowledged shouldBe emptyList()

                testScheduler.advanceTimeBy(251)
                transport.delegate.awaitAcknowledgements(outbox, 1)

                transport.publishCalls shouldBe 4
                transport.publishedChunkIndexes() shouldBe listOf(0, 0, 1)
                outbox.acknowledged shouldBe listOf(BatchId("large"))
            } finally {
                events.close()
                transport.close()
                telemetry.close()
                snapshots.close()
            }
        }
    }

    test("failed publication retries every durable commit that arrived while draining") {
        runTest {
            val generation = CatalogGeneration("catalog")
            val snapshots = snapshots(generation)
            val first = committedEvent("batch_1", "snapshot_0", "snapshot_1", generation)
            val second = committedEvent("batch_2", "snapshot_1", "snapshot_2", generation)
            val outbox = RecordingOutbox(first)
            val events = EditorCheckEvents(snapshots, outbox, backgroundScope)
            events.capture(snapshots.capture().use { it.root })

            try {
                RouteFixture { contracts, address, communicator ->
                    events.configure(contracts, address, communicator)
                    communicatorRoutes { }
                }.use { fixture ->
                    fixture.transport.failNextPublish(TransportError.Unavailable())
                    events.committed()
                    fixture.transport.awaitPublicationCount(1)
                    outbox.add(second)
                    events.committed()
                    testScheduler.advanceTimeBy(251)

                    fixture.transport.awaitAcknowledgements(outbox, 2)
                    outbox.acknowledged shouldBe listOf(BatchId("batch_1"), BatchId("batch_2"))
                    fixture.transport.authoringChanges().map { it.batch.value } shouldBe
                        listOf("batch_1", "batch_1", "batch_2")
                }
            } finally {
                events.close()
                snapshots.close()
            }
        }
    }

    test("a commit that invalidates finding evidence publishes a new findings token") {
        runTest {
            val generation = CatalogGeneration("catalog")
            val snapshots = snapshots(generation)
            val finding = finding(generation, InputToken("selection_token"))
            val outbox =
                RecordingOutbox(
                    committedEvent(
                        batch = "batch",
                        previous = "snapshot_0",
                        next = "snapshot_1",
                        generation = generation,
                        changed = mapOf(RESOURCE_SELECTION_INPUT to InputToken("selection_token_2")),
                    ),
                )
            val events = EditorCheckEvents(snapshots, outbox, backgroundScope)
            events.bindFindings { listOf(finding) }
            val captured = events.capture(snapshots.capture().use { it.root })

            try {
                RouteFixture { contracts, address, communicator ->
                    events.configure(contracts, address, communicator)
                    communicatorRoutes { }
                }.use { fixture ->
                    val changed = fixture.transport.awaitAuthoringChanges(outbox).single()

                    changed.previousFindings shouldBe captured.token
                    (changed.findingsToken == captured.token) shouldBe false
                    changed.findings
                        ?.findings
                        ?.single()
                        ?.status shouldBe skirout.editor.v1.checking.FindingStatus.OUTDATED
                }
            } finally {
                events.close()
                snapshots.close()
            }
        }
    }

    test("failed check notification remains pending until publication succeeds") {
        runTest {
            val generation = CatalogGeneration("catalog")
            val snapshots = snapshots(generation)
            val outbox = RecordingOutbox()
            val events = EditorCheckEvents(snapshots, outbox, backgroundScope)
            val initial = events.capture(snapshots.capture().use { it.root })
            val next = finding(generation, InputToken("selection_token"))
            events.bindFindings { listOf(next) }

            try {
                RouteFixture { contracts, address, communicator ->
                    events.configure(contracts, address, communicator)
                    communicatorRoutes { }
                }.use { fixture ->
                    fixture.transport.failNextPublish(TransportError.Unavailable())
                    events.publishChanged(next.ticket)
                    fixture.transport.awaitPublicationCount(1)
                    testScheduler.advanceTimeBy(251)
                    fixture.transport.awaitPublicationCount(2)

                    fixture.transport.authoringChanges().size shouldBe 2
                    val captured =
                        withTimeout(2.seconds) {
                            while (true) {
                                val current = events.capture(snapshots.capture().use { it.root })
                                if (current.token != initial.token) return@withTimeout current
                                yield()
                            }
                            error("Check finding publication wait ended unexpectedly")
                        }
                    (captured.token == initial.token) shouldBe false
                    captured.findings.size shouldBe 1
                }
            } finally {
                events.close()
                snapshots.close()
            }
        }
    }

    test("communicator replacement cancels a blocked send and resumes the durable backlog") {
        runTest {
            val generation = CatalogGeneration("catalog")
            val snapshots = snapshots(generation)
            val first = committedEvent("batch_1", "snapshot_0", "snapshot_1", generation)
            val second = committedEvent("batch_2", "snapshot_1", "snapshot_2", generation)
            val outbox = RecordingOutbox(first)
            val events = EditorCheckEvents(snapshots, outbox, backgroundScope)
            events.capture(snapshots.capture().use { it.root })
            val blocked = BlockingPublishTransport()
            val firstTelemetry = TelemetryTestHarness.create()
            val secondTelemetry = TelemetryTestHarness.create()
            val address = RealmAddress("realm", "organization")
            val contracts = EditorContracts(address)
            val replacement = FakeMessageTransport()

            try {
                events.configure(
                    contracts,
                    address,
                    Communicator(blocked, firstTelemetry.telemetry, ContextPropagators.noop()),
                )
                events.committed()
                withTimeout(2.seconds) { blocked.started.await() }
                outbox.add(second)
                events.committed()

                events.unconfigure()
                withTimeout(2.seconds) { blocked.cancelled.await() }
                outbox.acknowledged shouldBe emptyList()

                events.configure(
                    contracts,
                    address,
                    Communicator(replacement, secondTelemetry.telemetry, ContextPropagators.noop()),
                )
                events.committed()
                replacement.awaitAcknowledgements(outbox, 2)
                replacement.authoringChanges().map { it.batch.value } shouldBe listOf("batch_1", "batch_2")
                outbox.acknowledged shouldBe listOf(BatchId("batch_1"), BatchId("batch_2"))
            } finally {
                events.close()
                blocked.close()
                replacement.close()
                firstTelemetry.close()
                secondTelemetry.close()
                snapshots.close()
            }
        }
    }

    test("shutdown cancels a blocked check notification") {
        runTest {
            val generation = CatalogGeneration("catalog")
            val snapshots = snapshots(generation)
            val outbox = RecordingOutbox()
            val events = EditorCheckEvents(snapshots, outbox, backgroundScope)
            val initial = events.capture(snapshots.capture().use { it.root })
            val next = finding(generation, InputToken("selection_token"))
            events.bindFindings { listOf(next) }
            val blocked = BlockingPublishTransport()
            val telemetry = TelemetryTestHarness.create()
            val address = RealmAddress("realm", "organization")

            try {
                events.configure(
                    EditorContracts(address),
                    address,
                    Communicator(blocked, telemetry.telemetry, ContextPropagators.noop()),
                )
                events.publishChanged(next.ticket)
                withTimeout(2.seconds) { blocked.started.await() }
                val duringSend = events.capture(snapshots.capture().use { it.root })
                duringSend shouldBe initial

                withTimeout(2.seconds) { events.close() }
                withTimeout(2.seconds) { blocked.cancelled.await() }
            } finally {
                blocked.close()
                telemetry.close()
                snapshots.close()
            }
        }
    }
}

private class RecordingOutbox(
    vararg initial: AuthoringCommittedEvent,
) : AuthoringEventOutbox {
    private val events = initial.toMutableList()
    val acknowledged = mutableListOf<BatchId>()

    fun add(event: AuthoringCommittedEvent) {
        events += event
    }

    override suspend fun pending(): List<AuthoringCommittedEvent> = events.toList()

    override suspend fun acknowledge(batch: BatchId) {
        acknowledged += batch
        events.removeAll { it.batch == batch }
    }
}

private class BlockingPublishTransport(
    private val delegate: FakeMessageTransport = FakeMessageTransport(),
) : MessageTransport by delegate,
    AutoCloseable by delegate {
    val started = CompletableDeferred<Unit>()
    val cancelled = CompletableDeferred<Unit>()

    override suspend fun publish(message: OutboundMessage): TransportResult<Unit> {
        started.complete(Unit)
        try {
            awaitCancellation()
        } finally {
            cancelled.complete(Unit)
        }
    }
}

private class FailingPublishTransport(
    private val failAt: Int,
    val delegate: FakeMessageTransport = FakeMessageTransport(),
) : MessageTransport by delegate,
    AutoCloseable by delegate {
    var publishCalls = 0
        private set

    override suspend fun publish(message: OutboundMessage): TransportResult<Unit> {
        publishCalls++
        if (publishCalls == failAt) return TransportResult.Failure(TransportError.Unavailable())
        return delegate.publish(message)
    }

    fun publishedChunkIndexes(): List<Int> =
        delegate.actions
            .filterIsInstance<FakeMessageTransport.Action.Publish>()
            .map { action ->
                val result = AuthoringChangedTransferResult.serializer.fromBytes(action.message.payload.toByteArray())
                (result as AuthoringChangedTransferResult.ChunkWrapper).value.transfer.index
            }
}

private fun snapshots(generation: CatalogGeneration): InMemoryAuthoringSnapshotStore =
    InMemoryAuthoringSnapshotStore(
        TestCatalogLease(generation),
        AuthoredSnapshotSeed(
            snapshot = SnapshotId("snapshot_0"),
            resources = emptyMap(),
            inputTokens =
                mapOf(
                    InputIdentity.Catalog(generation) to InputToken("catalog_token"),
                    RESOURCE_SELECTION_INPUT to InputToken("selection_token"),
                ),
        ),
    )

private fun committedEvent(
    batch: String,
    previous: String,
    next: String,
    generation: CatalogGeneration,
    changed: Map<InputIdentity, InputToken> = emptyMap(),
): AuthoringCommittedEvent =
    AuthoringCommittedEvent(
        batch = BatchId(batch),
        delta =
            CommitDelta(
                previousSnapshot = SnapshotId(previous),
                snapshot = SnapshotId(next),
                catalog = generation,
                resources = emptyMap(),
                resourceDefinitions = emptyMap(),
                removedResources = emptySet(),
                relations = RelationProjectionDelta(emptyList(), emptyList(), emptyList()),
                inputTokens = changed,
            ),
    )

private fun largeCommittedEvent(generation: CatalogGeneration): AuthoringCommittedEvent {
    val resource = ResourceId("large")
    val definition = TypeDefinitionId(TypeId.Qualified("test", "large"), 1)
    return AuthoringCommittedEvent(
        batch = BatchId("large"),
        delta =
            CommitDelta(
                previousSnapshot = SnapshotId("snapshot_0"),
                snapshot = SnapshotId("snapshot_1"),
                catalog = generation,
                resources =
                    mapOf(
                        resource to
                            AuthoringRecord(
                                TypeSelection.Complete(TypeUse.Named(definition)),
                                mapOf("payload" to DataValue.StringValue("x".repeat(700_000))),
                            ),
                    ),
                resourceDefinitions = mapOf(resource to ResourceDefinitionId("large")),
                removedResources = emptySet(),
                relations = RelationProjectionDelta(emptyList(), emptyList(), emptyList()),
                inputTokens = emptyMap(),
            ),
    )
}

private fun finding(
    generation: CatalogGeneration,
    token: InputToken,
): FindingSet =
    FindingSet(
        ticket =
            CheckTicket(
                instance =
                    CheckInstanceId(
                        rule =
                            RuleId(
                                origin = RuleOrigin(TypeDefinitionId(TypeId.Qualified("test", "rule"), 1), 0),
                                localIndex = 0,
                            ),
                        location = ValueLocation(ResourceId("resource"), ValuePath()),
                    ),
                incarnation = "catalog:1",
                execution = CheckExecutionId("execution"),
                snapshot = SnapshotId("snapshot_0"),
                catalog = generation,
            ),
        observations = listOf(InputObservation(RESOURCE_SELECTION_INPUT, token)),
        outcome = CheckOutcome.Finished,
        findings = emptyList(),
        status = FindingStatus.Current,
    )

private fun FakeMessageTransport.authoringChanges(): List<AuthoringChanged> =
    actions
        .filterIsInstance<FakeMessageTransport.Action.Publish>()
        .mapNotNull { action ->
            runCatching {
                AuthoringChangedTransferResult.serializer.fromBytes(action.message.payload.toByteArray())
            }.getOrNull()
        }.mapNotNull { result ->
            (result as? AuthoringChangedTransferResult.ChunkWrapper)?.value?.transfer
        }.map { transfer -> AuthoringChanged.serializer.fromBytes(transfer.payload.toByteArray()) }

private suspend fun FakeMessageTransport.awaitAuthoringChanges(outbox: RecordingOutbox): List<AuthoringChanged> =
    withTimeout(2.seconds) {
        while (true) {
            authoringChanges()
                .takeIf { it.isNotEmpty() && outbox.acknowledged.isNotEmpty() }
                ?.let { return@withTimeout it }
            yield()
        }
        error("Authoring change wait ended unexpectedly")
    }

private suspend fun FakeMessageTransport.awaitPublicationCount(expected: Int) {
    withTimeout(2.seconds) {
        while (actions.filterIsInstance<FakeMessageTransport.Action.Publish>().size < expected) {
            yield()
        }
    }
}

private suspend fun FakeMessageTransport.awaitAcknowledgements(
    outbox: RecordingOutbox,
    expected: Int,
) {
    withTimeout(2.seconds) {
        while (outbox.acknowledged.size < expected) {
            yield()
        }
    }
}
