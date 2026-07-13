package com.typewritermc.services.libs.communicator.interfaces

import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.types.shouldBeInstanceOf
import io.mockk.*
import io.opentelemetry.api.trace.Span
import io.opentelemetry.api.trace.SpanBuilder
import io.opentelemetry.api.trace.Tracer
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.flow.flowOf
import protokt.v1.typewriter.api.v1.*
import protokt.v1.typewriter.models.v1.Error
import java.io.ByteArrayOutputStream

private fun createMockTracer(): Tracer {
    val span = mockk<Span>(relaxed = true)
    val spanBuilder = mockk<SpanBuilder>(relaxed = true) {
        every { setParent(any()) } returns this
        every { setSpanKind(any()) } returns this
        every { setAttribute(any<String>(), any<String>()) } returns this
        every { setAttribute(any<String>(), any<Long>()) } returns this
        every { startSpan() } returns span
    }
    return mockk<Tracer>(relaxed = true) {
        every { spanBuilder(any()) } returns spanBuilder
    }
}

class NatsRegistrationClientTest : FunSpec({

    context("Happy Path Scenarios") {

        test("queryServiceStatus returns Bound with organization details when service is bound") {
            val messageBus = mockk<MessageBus>()

            val boundStatus = ServiceStatus {
                binding = ServiceStatus.Binding.Bound(BoundStatus {
                    organizationId = "org-123"
                    organizationName = "Test Organization"
                })
            }
            val response = GetServiceStatusResponse {
                result = GetServiceStatusResponse.Result.Status(boundStatus)
            }
            val responseBytes = ByteArrayOutputStream().also { response.serialize(it) }.toByteArray()

            coEvery { messageBus.request(any(), any(), any()) } returns Message(
                subject = "reply",
                data = responseBytes
            )

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            val result = client.queryServiceStatus("my-service")

            result.shouldBeInstanceOf<ServiceStatusResult.Bound>()
            result.organizationId shouldBe "org-123"
            result.organizationName shouldBe "Test Organization"
        }

        test("queryServiceStatus returns Unbound with registration token when service is unbound") {
            val messageBus = mockk<MessageBus>()

            val unboundStatus = ServiceStatus {
                binding = ServiceStatus.Binding.Unbound(UnboundStatus {
                    registrationToken = "REG-TOKEN-XYZ"
                })
            }
            val response = GetServiceStatusResponse {
                result = GetServiceStatusResponse.Result.Status(unboundStatus)
            }
            val responseBytes = ByteArrayOutputStream().also { response.serialize(it) }.toByteArray()

            coEvery { messageBus.request(any(), any(), any()) } returns Message(
                subject = "reply",
                data = responseBytes
            )

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            val result = client.queryServiceStatus("svc-1")

            result.shouldBeInstanceOf<ServiceStatusResult.Unbound>()
            result.token shouldBe "REG-TOKEN-XYZ"
        }

        test("subscribeToBoundNotification invokes callback with organization details on notification") {
            val messageBus = mockk<MessageBus>()

            val notification = ServiceBoundNotification {
                organizationId = "org-bound-123"
                organizationName = "Newly Bound Org"
            }
            val notificationBytes = ByteArrayOutputStream().also { notification.serialize(it) }.toByteArray()

            val subscription = mockk<Subscription>()
            coEvery { subscription.messages } returns flowOf(Message("subject", notificationBytes))
            coEvery { subscription.unsubscribe() } just runs
            coEvery { messageBus.subscribe(any()) } returns subscription

            val callbackResult = CompletableDeferred<Pair<String, String>>()

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            val job = client.subscribeToBoundNotification("svc") { orgId, orgName ->
                callbackResult.complete(orgId to orgName)
            }

            job.join()
            val (orgId, orgName) = callbackResult.await()

            orgId shouldBe "org-bound-123"
            orgName shouldBe "Newly Bound Org"
            coVerify { subscription.unsubscribe() }
        }
    }

    context("Error and Failure Scenarios") {

        test("queryServiceStatus returns Error when backend returns error response") {
            val messageBus = mockk<MessageBus>()

            val response = GetServiceStatusResponse {
                result = GetServiceStatusResponse.Result.Error(Error {
                    code = 403u
                    message = "Forbidden: insufficient permissions"
                })
            }
            val responseBytes = ByteArrayOutputStream().also { response.serialize(it) }.toByteArray()

            coEvery { messageBus.request(any(), any(), any()) } returns Message(
                subject = "reply",
                data = responseBytes
            )

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            val result = client.queryServiceStatus("svc")

            result.shouldBeInstanceOf<ServiceStatusResult.Error>()
            result.code shouldBe 403
            result.message shouldBe "Forbidden: insufficient permissions"
        }

        test("queryServiceStatus returns Error on empty response data") {
            val messageBus = mockk<MessageBus>()

            coEvery { messageBus.request(any(), any(), any()) } returns Message(
                subject = "reply",
                data = null
            )

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            val result = client.queryServiceStatus("svc")

            result.shouldBeInstanceOf<ServiceStatusResult.Error>()
            result.message shouldContain "empty data"
        }

        test("queryServiceStatus returns Error on empty byte array response") {
            val messageBus = mockk<MessageBus>()

            coEvery { messageBus.request(any(), any(), any()) } returns Message(
                subject = "reply",
                data = byteArrayOf()
            )

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            val result = client.queryServiceStatus("svc")

            result.shouldBeInstanceOf<ServiceStatusResult.Error>()
            result.message shouldContain "empty data"
        }

        test("queryServiceStatus returns Error on deserialization failure") {
            val messageBus = mockk<MessageBus>()

            coEvery { messageBus.request(any(), any(), any()) } returns Message(
                subject = "reply",
                data = byteArrayOf(0x00, 0xFF.toByte(), 0x01, 0x02)
            )

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            val result = client.queryServiceStatus("svc")

            result.shouldBeInstanceOf<ServiceStatusResult.Error>()
            result.message shouldContain "parse"
        }

        test("queryServiceStatus returns Error on NATS timeout") {
            val messageBus = mockk<MessageBus>()

            coEvery { messageBus.request(any(), any(), any()) } throws RuntimeException("Request timed out")

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            val result = client.queryServiceStatus("svc")

            result.shouldBeInstanceOf<ServiceStatusResult.Error>()
            result.message shouldContain "NATS request failed"
        }

        test("queryServiceStatus returns Error when status has no binding information") {
            val messageBus = mockk<MessageBus>()

            val statusWithNoBinding = ServiceStatus {}
            val response = GetServiceStatusResponse {
                result = GetServiceStatusResponse.Result.Status(statusWithNoBinding)
            }
            val responseBytes = ByteArrayOutputStream().also { response.serialize(it) }.toByteArray()

            coEvery { messageBus.request(any(), any(), any()) } returns Message(
                subject = "reply",
                data = responseBytes
            )

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            val result = client.queryServiceStatus("svc")

            result.shouldBeInstanceOf<ServiceStatusResult.Error>()
            result.message shouldContain "no binding information"
        }

        test("queryServiceStatus returns Error on response with null result field") {
            val messageBus = mockk<MessageBus>()

            val response = GetServiceStatusResponse {}
            val responseBytes = ByteArrayOutputStream().also { response.serialize(it) }.toByteArray()

            if (responseBytes.isEmpty()) {
                coEvery { messageBus.request(any(), any(), any()) } returns Message(
                    subject = "reply",
                    data = byteArrayOf(0x08, 0x00)
                )
            } else {
                coEvery { messageBus.request(any(), any(), any()) } returns Message(
                    subject = "reply",
                    data = responseBytes
                )
            }

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            val result = client.queryServiceStatus("svc")

            result.shouldBeInstanceOf<ServiceStatusResult.Error>()
        }
    }

    context("Edge Cases") {

        test("queryServiceStatus sends request to correct subject with serviceId") {
            val messageBus = mockk<MessageBus>()
            val subjectSlot = slot<String>()

            val boundStatus = ServiceStatus {
                binding = ServiceStatus.Binding.Bound(BoundStatus {
                    organizationId = "org"
                    organizationName = "Org"
                })
            }
            val response = GetServiceStatusResponse {
                result = GetServiceStatusResponse.Result.Status(boundStatus)
            }
            val responseBytes = ByteArrayOutputStream().also { response.serialize(it) }.toByteArray()

            coEvery { messageBus.request(capture(subjectSlot), any(), any()) } returns Message(
                subject = "reply",
                data = responseBytes
            )

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            client.queryServiceStatus("my-unique-service-123")

            subjectSlot.captured shouldBe "cloud.to.service.my-unique-service-123.status"
        }

        test("subscribeToBoundNotification subscribes to correct subject with serviceId") {
            val messageBus = mockk<MessageBus>()
            val subjectSlot = slot<String>()

            val subscription = mockk<Subscription>()
            coEvery { subscription.messages } returns flowOf()
            coEvery { subscription.unsubscribe() } just runs
            coEvery { messageBus.subscribe(capture(subjectSlot)) } returns subscription

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            val job = client.subscribeToBoundNotification("svc-xyz-789") { _, _ -> }

            job.join()

            subjectSlot.captured shouldBe "cloud.from.service.svc-xyz-789.registration.bound"
        }

        test("subscribeToBoundNotification handles null message data gracefully") {
            val messageBus = mockk<MessageBus>()

            val subscription = mockk<Subscription>()
            coEvery { subscription.messages } returns flowOf(Message("subject", null))
            coEvery { subscription.unsubscribe() } just runs
            coEvery { messageBus.subscribe(any()) } returns subscription

            var callbackInvoked = false

            val client = NatsRegistrationClient(messageBus, createMockTracer())
            val job = client.subscribeToBoundNotification("svc") { _, _ ->
                callbackInvoked = true
            }

            job.join()

            callbackInvoked shouldBe false
            coVerify { subscription.unsubscribe() }
        }
    }
})
