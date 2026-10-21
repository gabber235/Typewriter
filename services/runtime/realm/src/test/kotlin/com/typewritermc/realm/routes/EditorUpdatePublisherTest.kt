package com.typewritermc.realm.routes

import com.typewritermc.authoring.CheckExecutionId
import com.typewritermc.authoring.EditExpectation
import com.typewritermc.authoring.ValueLocation
import com.typewritermc.authoring.ValuePath
import com.typewritermc.checking.CatalogGeneration
import com.typewritermc.checking.CheckOutcome
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.realm.authoring.AuthoringSeed
import com.typewritermc.realm.authoring.AuthoringViewDelta
import com.typewritermc.realm.authoring.InMemoryAuthoringViewStore
import com.typewritermc.realm.checking.CheckInstanceId
import com.typewritermc.realm.checking.CheckTicket
import com.typewritermc.realm.checking.FindingSet
import com.typewritermc.realm.checking.TestCatalogLease
import com.typewritermc.realm.checking.record
import com.typewritermc.realm.compiler.PublicationFixture
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import com.typewritermc.types.ResourceId
import com.typewritermc.types.qualified
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import skirout.editor.v1.authoring.AuthoringChanged
import skirout.editor.v1.checking.FindingStatus
import skirout.editor.v1.type_catalog.RuleId
import skirout.editor.v1.type_catalog.RuleOrigin
import skirout.editor.v1.type_catalog.TypeDefinitionId
import kotlin.time.Duration.Companion.seconds

val EditorUpdatePublisherTest by testSuite {
    test("configuration and commit signals publish current catalog hints") {
        runTest {
            val publication = PublicationFixture()
            HintConnection().use { connection ->
                val events = connection.editorUpdates(publication, backgroundScope)
                try {
                    events.configure(connection.address, connection.communicator)
                    connection.transport.awaitCount(1)
                    events.committed()
                    connection.transport.awaitCount(2)
                    connection.transport.hints().map { it.generation.value } shouldBe listOf("catalog", "catalog")
                } finally {
                    events.close()
                    publication.close()
                }
            }
        }
    }
    test("failed hints do not retain operation history or retry without a new signal") {
        runTest {
            val publication = PublicationFixture()
            HintConnection().use { connection ->
                val events = connection.editorUpdates(publication, backgroundScope)
                try {
                    connection.transport.failNextPublish(TransportError.Unavailable())
                    events.configure(connection.address, connection.communicator)
                    connection.transport.awaitCount(1)
                    runCurrent()
                    connection.transport.hints().size shouldBe 1
                    events.committed()
                    connection.transport.awaitCount(2)
                } finally {
                    events.close()
                    publication.close()
                }
            }
        }
    }
    test("connection replacement cancels a blocked send and sends a fresh hint") {
        runTest {
            val publication = PublicationFixture()
            val blocked = BlockingPublishTransport()
            val telemetry = TelemetryTestHarness.create()
            HintConnection().use { replacement ->
                val events = replacement.editorUpdates(publication, backgroundScope)
                try {
                    events.configure(
                        replacement.address,
                        Communicator(blocked, telemetry.telemetry, ContextPropagators.noop()),
                    )
                    withTimeout(2.seconds) { blocked.started.await() }
                    events.configure(replacement.address, replacement.communicator)
                    withTimeout(2.seconds) { blocked.cancelled.await() }
                    replacement.transport.awaitCount(1)
                } finally {
                    events.close()
                    publication.close()
                    blocked.close()
                    telemetry.close()
                }
            }
        }
    }
    test("finding evidence is current when expected values return") {
        runTest {
            val resource = ResourceId("resource")
            val original = record(name = "Quest")
            val views = InMemoryAuthoringViewStore(TestCatalogLease(), AuthoringSeed(mapOf(resource to original)))
            val ticket =
                CheckTicket(
                    CheckInstanceId(
                        RuleId(origin = RuleOrigin(owner = TypeDefinitionId.qualified("test", "rule"), ordinal = 0), localIndex = 0),
                        ValueLocation(resource, ValuePath()),
                    ),
                    "catalog:1",
                    CheckExecutionId("execution"),
                    CatalogGeneration("catalog"),
                )
            val finding =
                FindingSet(
                    ticket,
                    listOf(EditExpectation.Resource(resource, original)),
                    CheckOutcome.Finished,
                    emptyList(),
                    FindingStatus.CURRENT,
                )
            try {
                views.install(views.prepare(AuthoringViewDelta(upsertedResources = mapOf(resource to record(name = "Story")))))
                views.read { captureFindings(it, listOf(finding)).findings.single().status } shouldBe
                    FindingStatus.OUTDATED
                views.install(views.prepare(AuthoringViewDelta(upsertedResources = mapOf(resource to original))))
                views.read { captureFindings(it, listOf(finding)).findings.single().status } shouldBe
                    FindingStatus.CURRENT
            } finally {
                views.close()
            }
        }
    }
}

private class HintConnection : AutoCloseable {
    val address = RealmRouteScope(organizationId = "organization", realmId = "realm")
    val transport = FakeMessageTransport()
    private val telemetry = TelemetryTestHarness.create()
    val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())

    fun editorUpdates(
        publication: PublicationFixture,
        scope: CoroutineScope,
    ) = EditorUpdatePublisher(publication.views, publication.publisher, emptyFlow(), telemetry.telemetry, scope)

    override fun close() {
        transport.close()
        telemetry.close()
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

private fun FakeMessageTransport.hints(): List<AuthoringChanged> =
    actions
        .filterIsInstance<FakeMessageTransport.Action.Publish>()
        .filter {
            it.message.address.value
                .endsWith(".editor.authoring.changed")
        }.map { AuthoringChanged.serializer.fromBytes(it.message.payload.toByteArray()) }

private suspend fun FakeMessageTransport.awaitCount(count: Int) =
    withTimeout(2.seconds) {
        while (hints().size < count) yield()
    }
