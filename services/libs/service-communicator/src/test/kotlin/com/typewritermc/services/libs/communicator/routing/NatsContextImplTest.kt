package com.typewritermc.services.libs.communicator.routing

import com.typewritermc.services.libs.communicator.interfaces.Message
import com.typewritermc.services.libs.communicator.interfaces.MessageBus
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.core.spec.style.FunSpec
import io.kotest.matchers.shouldBe
import io.mockk.*
import protokt.v1.typewriter.api.v1.GetServiceStatusRequest
import protokt.v1.typewriter.api.v1.GetServiceStatusResponse
import protokt.v1.typewriter.api.v1.ServiceStatus
import protokt.v1.typewriter.api.v1.UnboundStatus
import java.io.ByteArrayOutputStream
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

class NatsContextImplTest : FunSpec({

    context("reply") {
        test("publishes to replyTo subject when present") {
            val messageBus = mockk<MessageBus>()
            val message = Message(
                subject = "test.action",
                data = byteArrayOf(1, 2, 3),
                replyTo = "inbox.reply.123"
            )
            val context = NatsContextImpl(message, SubjectParams(emptyMap()), messageBus)
            val responseData = "response".toByteArray()

            coEvery { messageBus.publish(any(), any()) } returns Unit

            context.reply(responseData)

            coVerify(exactly = 1) { messageBus.publish("inbox.reply.123", responseData) }
        }

        test("does not publish when replyTo is null") {
            val messageBus = mockk<MessageBus>()
            val message = Message(
                subject = "test.action",
                data = byteArrayOf(1, 2, 3),
                replyTo = null
            )
            val context = NatsContextImpl(message, SubjectParams(emptyMap()), messageBus)

            context.reply("response".toByteArray())

            coVerify { messageBus wasNot Called }
        }
    }

    context("send") {
        test("publishes to specified subject") {
            val messageBus = mockk<MessageBus>()
            val message = Message(subject = "original", data = null, replyTo = null)
            val context = NatsContextImpl(message, SubjectParams(emptyMap()), messageBus)
            val data = "notification".toByteArray()

            coEvery { messageBus.publish(any(), any()) } returns Unit

            context.send("target.subject", data)

            coVerify(exactly = 1) { messageBus.publish("target.subject", data) }
        }
    }

    context("request") {
        test("forwards request to messageBus with correct timeout") {
            val messageBus = mockk<MessageBus>()
            val message = Message(subject = "original", data = null, replyTo = null)
            val context = NatsContextImpl(message, SubjectParams(emptyMap()), messageBus)
            val requestData = "query".toByteArray()
            val responseMessage = Message(subject = "response", data = "result".toByteArray(), replyTo = null)

            val timeoutSlot = slot<Duration>()
            coEvery { messageBus.request(any(), any(), capture(timeoutSlot)) } returns responseMessage

            val result = context.request("other.service", requestData, 3.seconds)

            result shouldBe responseMessage
            timeoutSlot.captured shouldBe 3.seconds
        }
    }

    context("accessors") {
        test("message property returns original message") {
            val messageBus = mockk<MessageBus>()
            val originalMessage = Message(
                subject = "test.subject",
                data = "data".toByteArray(),
                replyTo = "reply.to"
            )
            val context = NatsContextImpl(originalMessage, SubjectParams(emptyMap()), messageBus)

            context.message shouldBe originalMessage
        }

        test("params property returns SubjectParams") {
            val messageBus = mockk<MessageBus>()
            val params = SubjectParams(mapOf("id" to "123"))
            val message = Message(subject = "test", data = null, replyTo = null)
            val context = NatsContextImpl(message, params, messageBus)

            context.params.require("id") shouldBe "123"
        }
    }

    context("protobuf receive") {
        test("deserializes valid protobuf message") {
            val messageBus = mockk<MessageBus>()
            val request = GetServiceStatusRequest {}
            val serializedData = ByteArrayOutputStream().also { request.serialize(it) }.toByteArray()
            val message = Message(
                subject = "test.status",
                data = serializedData,
                replyTo = null
            )
            val context = NatsContextImpl(message, SubjectParams(emptyMap()), messageBus)

            val received = context.receive(GetServiceStatusRequest)

            received shouldBe request
        }

        test("throws exception when message data is null") {
            val messageBus = mockk<MessageBus>()
            val message = Message(
                subject = "test.status",
                data = null,
                replyTo = null
            )
            val context = NatsContextImpl(message, SubjectParams(emptyMap()), messageBus)

            shouldThrow<IllegalStateException> {
                context.receive(GetServiceStatusRequest)
            }
        }

        test("deserializes empty bytes as valid empty message") {
            val messageBus = mockk<MessageBus>()
            val message = Message(
                subject = "test.status",
                data = byteArrayOf(),
                replyTo = null
            )
            val context = NatsContextImpl(message, SubjectParams(emptyMap()), messageBus)

            val received = context.receive(GetServiceStatusRequest)

            received shouldBe GetServiceStatusRequest {}
        }

        test("throws exception when message data is invalid") {
            val messageBus = mockk<MessageBus>()
            val message = Message(
                subject = "test.status",
                data = byteArrayOf(0x7F, 0x45, 0x4C, 0x46),
                replyTo = null
            )
            val context = NatsContextImpl(message, SubjectParams(emptyMap()), messageBus)

            shouldThrow<Exception> {
                context.receive(GetServiceStatusRequest)
            }
        }
    }

    context("protobuf reply") {
        test("serializes and sends protobuf message") {
            val messageBus = mockk<MessageBus>()
            val message = Message(
                subject = "test.status",
                data = byteArrayOf(),
                replyTo = "inbox.reply.123"
            )
            val context = NatsContextImpl(message, SubjectParams(emptyMap()), messageBus)
            val unboundStatus = ServiceStatus {
                binding = ServiceStatus.Binding.Unbound(UnboundStatus {
                    registrationToken = "token123"
                })
            }
            val response = GetServiceStatusResponse {
                result = GetServiceStatusResponse.Result.Status(unboundStatus)
            }
            val expectedBytes = ByteArrayOutputStream().also { response.serialize(it) }.toByteArray()

            coEvery { messageBus.publish(any(), any()) } returns Unit

            context.reply(response)

            coVerify(exactly = 1) {
                messageBus.publish("inbox.reply.123", match { it.contentEquals(expectedBytes) })
            }
        }

        test("logs warning when replyTo is null") {
            val messageBus = mockk<MessageBus>()
            val message = Message(
                subject = "test.status",
                data = byteArrayOf(),
                replyTo = null
            )
            val context = NatsContextImpl(message, SubjectParams(emptyMap()), messageBus)
            val response = GetServiceStatusResponse {}

            context.reply(response)

            coVerify { messageBus wasNot Called }
        }
    }

    context("protobuf send") {
        test("serializes and sends protobuf message to subject") {
            val messageBus = mockk<MessageBus>()
            val message = Message(subject = "original", data = null, replyTo = null)
            val context = NatsContextImpl(message, SubjectParams(emptyMap()), messageBus)
            val notification = GetServiceStatusRequest {}
            val expectedBytes = ByteArrayOutputStream().also { notification.serialize(it) }.toByteArray()

            coEvery { messageBus.publish(any(), any()) } returns Unit

            context.send("target.subject", notification)

            coVerify(exactly = 1) {
                messageBus.publish("target.subject", match { it.contentEquals(expectedBytes) })
            }
        }
    }

    context("protobuf request") {
        test("serializes request and deserializes response") {
            val messageBus = mockk<MessageBus>()
            val message = Message(subject = "original", data = null, replyTo = null)
            val context = NatsContextImpl(message, SubjectParams(emptyMap()), messageBus)

            val request = GetServiceStatusRequest {}
            val requestBytes = ByteArrayOutputStream().also { request.serialize(it) }.toByteArray()

            val unboundStatus = ServiceStatus {
                binding = ServiceStatus.Binding.Unbound(UnboundStatus {
                    registrationToken = "token456"
                })
            }
            val expectedResponse = GetServiceStatusResponse {
                result = GetServiceStatusResponse.Result.Status(unboundStatus)
            }
            val responseBytes = ByteArrayOutputStream().also { expectedResponse.serialize(it) }.toByteArray()
            val responseMessage = Message(subject = "response", data = responseBytes, replyTo = null)

            coEvery { messageBus.request(any(), any(), any()) } returns responseMessage

            val result = context.request("other.service", request, GetServiceStatusResponse, 5.seconds)

            result shouldBe expectedResponse
            coVerify(exactly = 1) {
                messageBus.request("other.service", match { it.contentEquals(requestBytes) }, 5.seconds)
            }
        }
    }
})
