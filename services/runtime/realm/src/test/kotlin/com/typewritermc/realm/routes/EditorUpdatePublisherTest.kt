package com.typewritermc.realm.routes

import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.realm.publication.PublicationFixture
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.flow.emptyFlow
import kotlinx.coroutines.test.advanceUntilIdle
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withTimeout
import kotlinx.coroutines.yield
import skirout.editor.v1.authoring.AuthoringChanged
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
    test("a failed hint is not retried until the next commit signal") {
        runTest {
            val publication = PublicationFixture()
            HintConnection().use { connection ->
                val events = connection.editorUpdates(publication, backgroundScope)
                try {
                    connection.transport.failNextPublish(TransportError.Unavailable())
                    events.configure(connection.address, connection.communicator)
                    connection.transport.awaitCount(1)
                    advanceUntilIdle()
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
}
