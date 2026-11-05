@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.engine.runtime

import com.typewritermc.engine.runtime.EngineContentDeliveryHealth
import com.typewritermc.engine.runtime.testing.absentContentReply
import com.typewritermc.engine.runtime.testing.delivery
import com.typewritermc.engine.runtime.testing.deliveryHost
import com.typewritermc.engine.runtime.testing.queryDeadline
import com.typewritermc.loader.api.HostedMessagingSession
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.time.Duration.Companion.milliseconds

val CompiledContentDeliveryTest by testSuite {
    val subscriptionCloseTime = 500.milliseconds

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
                transport.closeSubscriptionWith(1) { delay(subscriptionCloseTime) }
                transport.respondWith { _, _ -> awaitCancellation() }
                val delivery = delivery(transport, telemetry)
                delivery.start { error("No content was returned") }
                runCurrent()

                val stopped = async { delivery.stop() }
                runCurrent()
                stopped.isCompleted shouldBe false
                advanceTimeBy(subscriptionCloseTime)
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
                transport.requests.size shouldBe 1
                delivery.health.value shouldBe EngineContentDeliveryHealth.Idle
                transport.close()
            }
        }
    }
}

private const val REALM = "realm"
