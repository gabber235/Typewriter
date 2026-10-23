@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.engine.runtime

import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.loader.api.HostedRuntimeHost
import com.typewritermc.loader.api.artifact.PublishSharedArtifact
import com.typewritermc.loader.api.artifact.SharedArtifactAccess
import com.typewritermc.loader.api.artifact.SharedArtifactId
import com.typewritermc.loader.api.artifact.SharedArtifactProvenance
import com.typewritermc.loader.api.artifact.SharedArtifactRevision
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.filetransfer.blob.ArtifactDigest
import com.typewritermc.services.libs.filetransfer.blob.BlobMetadata
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.withClue
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest

val CompiledContentDeliveryTest by testSuite {
    test("local query deadline retries within the same messaging session") {
        runTest {
            TelemetryTestHarness.create().use { telemetry ->
                val transport = FakeMessageTransport()
                repeat(2) {
                    transport.respondWith { _, timeout ->
                        delay(timeout)
                        TransportResult.Failure(TransportError.Timeout())
                    }
                }
                val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
                val session = HostedMessagingSession(1, "organization", communicator)
                val host = deliveryHost(session, telemetry)
                val delivery = MessagingEngineContentDelivery(host, "realm", backgroundScope)
                delivery.start { error("No content was returned") }
                runCurrent()
                withClue("health=${delivery.health.value}; actions=${transport.actions}") {
                    transport.actions.filterIsInstance<FakeMessageTransport.Action.Request>().size shouldBe 1
                }
                advanceTimeBy(11_001)
                runCurrent()
                transport.actions.filterIsInstance<FakeMessageTransport.Action.Request>().size shouldBe 2
                host.messaging.value shouldBe session
                delivery.health.value shouldBe EngineContentDeliveryHealth.Watching
                delivery.stop()
                transport.activeSubscriptionCount shouldBe 0
                transport.close()
            }
        }
    }
    test("subscription setup failure retries and stop awaits cooperative cleanup without retrying cancellation") {
        runTest {
            TelemetryTestHarness.create().use { telemetry ->
                val transport = FakeMessageTransport()
                transport.failNextSubscribe(TransportError.Unavailable())
                transport.closeSubscriptionWith(2) { delay(500) }
                transport.respondWith { _, _ -> awaitCancellation() }
                val communicator = Communicator(transport, telemetry.telemetry, ContextPropagators.noop())
                val delivery =
                    MessagingEngineContentDelivery(
                        deliveryHost(HostedMessagingSession(1, "organization", communicator), telemetry),
                        "realm",
                        backgroundScope,
                    )
                delivery.start { error("No content was returned") }
                runCurrent()
                (delivery.health.value is EngineContentDeliveryHealth.Failed) shouldBe true
                advanceTimeBy(1_001)
                runCurrent()
                withClue("health=${delivery.health.value}; actions=${transport.actions}") {
                    transport.actions.filterIsInstance<FakeMessageTransport.Action.Request>().size shouldBe 1
                }
                // Attempt one failed before subscribing. Attempt two owns the hint subscription.
                val stopped = async { delivery.stop() }
                runCurrent()
                stopped.isCompleted shouldBe false
                advanceTimeBy(501)
                runCurrent()
                stopped.await()
                val requests = transport.actions.filterIsInstance<FakeMessageTransport.Action.Request>().size
                advanceTimeBy(11_001)
                runCurrent()
                transport.actions.filterIsInstance<FakeMessageTransport.Action.Request>().size shouldBe requests
                delivery.health.value shouldBe EngineContentDeliveryHealth.Idle
                transport.activeSubscriptionCount shouldBe 0
                transport.close()
            }
        }
    }
}

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
