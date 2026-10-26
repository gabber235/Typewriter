@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.engine.runtime

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.artifact.PublishSharedArtifact
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.api.artifact.SharedArtifactRevision
import com.typewritermc.protocol.transport.RealmRouteScope
import com.typewritermc.protocol.transport.generated.authoringCompiledQuery
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.TestScope
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import skirout.editor.v1.compiled_content.QueryPublishedContentResponse
import kotlin.time.Duration.Companion.milliseconds

val CompiledContentDeliveryTest by testSuite {
    test("a query that misses its deadline is retried in the same session and the answer keeps delivery watching") {
        runTest {
            TelemetryTestHarness.create().use { telemetry ->
                val transport = FakeMessageTransport()
                transport.respondWith { _, timeout ->
                    delay(timeout)
                    TransportResult.Failure(TransportError.Timeout())
                }
                transport.respondWith { request, _ -> absentContentReply(request) }
                val session =
                    HostedMessagingSession(1, "organization", Communicator(transport, telemetry.telemetry, ContextPropagators.noop()))
                val host = deliveryHost(session, telemetry)
                val delivery = MessagingEngineContentDelivery(host, REALM, backgroundScope)
                delivery.start { error("No content was returned") }
                runCurrent()

                advanceTimeBy(queryDeadline)
                runCurrent()
                (delivery.health.value is EngineContentDeliveryHealth.Failed) shouldBe true

                advanceTimeBy(CONTENT_DELIVERY_RETRY_DELAY)
                runCurrent()
                // The answered retry waits for a change hint; an unanswered one would fail again after its deadline.
                advanceTimeBy(queryDeadline)
                runCurrent()
                delivery.health.value shouldBe EngineContentDeliveryHealth.Watching
                host.messaging.value shouldBe session

                delivery.stop()
                transport.close()
            }
        }
    }

    test("a failed change subscription is retried after the retry delay") {
        runTest {
            TelemetryTestHarness.create().use { telemetry ->
                val transport = FakeMessageTransport()
                transport.failNextSubscribe(TransportError.Unavailable())
                transport.respondWith { _, _ -> awaitCancellation() }
                val delivery = delivery(transport, telemetry)
                delivery.start { error("No content was returned") }
                runCurrent()
                (delivery.health.value is EngineContentDeliveryHealth.Failed) shouldBe true

                advanceTimeBy(CONTENT_DELIVERY_RETRY_DELAY)
                runCurrent()

                delivery.health.value shouldBe EngineContentDeliveryHealth.Watching
                transport.activeSubscriptionCount shouldBe 1
                delivery.stop()
                transport.close()
            }
        }
    }

    test("stopping waits until the change subscription has closed") {
        runTest {
            TelemetryTestHarness.create().use { telemetry ->
                val transport = FakeMessageTransport()
                transport.closeSubscriptionWith(1) { delay(SUBSCRIPTION_CLOSE_TIME) }
                transport.respondWith { _, _ -> awaitCancellation() }
                val delivery = delivery(transport, telemetry)
                delivery.start { error("No content was returned") }
                runCurrent()

                val stopped = async { delivery.stop() }
                runCurrent()
                stopped.isCompleted shouldBe false
                advanceTimeBy(SUBSCRIPTION_CLOSE_TIME)
                runCurrent()

                stopped.isCompleted shouldBe true
                transport.activeSubscriptionCount shouldBe 0
                delivery.health.value shouldBe EngineContentDeliveryHealth.Idle
                transport.close()
            }
        }
    }

    test("stopping cancels the pending query without retrying it") {
        runTest {
            TelemetryTestHarness.create().use { telemetry ->
                val transport = FakeMessageTransport()
                transport.respondWith { _, _ -> awaitCancellation() }
                val delivery = delivery(transport, telemetry)
                delivery.start { error("No content was returned") }
                runCurrent()

                delivery.stop()
                advanceTimeBy(queryDeadline + CONTENT_DELIVERY_RETRY_DELAY)
                runCurrent()

                // The count is the requirement: a stopped delivery never queries again.
                transport.actions.filterIsInstance<FakeMessageTransport.Action.Request>().size shouldBe 1
                delivery.health.value shouldBe EngineContentDeliveryHealth.Idle
                transport.close()
            }
        }
    }
}

private const val REALM = "realm"
private val SUBSCRIPTION_CLOSE_TIME = 500.milliseconds
private val queryAddress = RealmRouteScope(organizationId = "organization", realmId = REALM)
private val queryDeadline get() = queryAddress.authoringCompiledQuery.timeout

private fun TestScope.delivery(
    transport: FakeMessageTransport,
    telemetry: TelemetryTestHarness,
) = MessagingEngineContentDelivery(
    deliveryHost(
        HostedMessagingSession(1, "organization", Communicator(transport, telemetry.telemetry, ContextPropagators.noop())),
        telemetry,
    ),
    REALM,
    backgroundScope,
)

private fun absentContentReply(request: OutboundMessage): TransportResult<InboundMessage> =
    TransportResult.Success(
        InboundMessage(
            request.address,
            queryAddress.authoringCompiledQuery.responseCodec.encode(QueryPublishedContentResponse.createAbsent()),
        ),
    )

private fun deliveryHost(
    session: HostedMessagingSession,
    telemetry: TelemetryTestHarness,
) = object : HostedRuntimeHost {
    override val messaging = MutableStateFlow<HostedMessagingSession?>(session)
    override val openTelemetry = telemetry.openTelemetry
    override val sharedArtifacts =
        object : SharedArtifactAccess {
            override suspend fun publish(command: PublishSharedArtifact): Nothing = error("No content was returned")

            override suspend fun delete(
                id: SharedArtifactId,
                expectedRevision: SharedArtifactRevision,
                provenance: SharedArtifactProvenance,
            ): Nothing = error("No content was returned")

            override suspend fun catalog(): Nothing = error("No content was returned")

            override suspend fun metadata(digest: ArtifactDigest): Nothing = error("No content was returned")

            override suspend fun fetch(digest: ArtifactDigest): Nothing = error("No content was returned")

            override suspend fun store(
                expected: BlobMetadata,
                content: ByteArray,
            ): Nothing = error("No content was returned")
        }
}
