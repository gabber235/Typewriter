package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.transport.*
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import kotlinx.coroutines.async
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.test.runTest
import kotlin.time.Duration.Companion.seconds

val FakeMessageTransportTest by testSuite {
    test("actions preserve operation order and failures are one shot") {
        runTest {
            val fake = FakeMessageTransport()
            val message = OutboundMessage(MessageAddress.of("book.one"), byteArrayOf(1))
            fake.failNextPublish(TransportError.Unavailable())
            (fake.publish(message) is TransportResult.Failure) shouldBe true
            fake.publish(message) shouldBe TransportResult.Success(Unit)
            fake.failNextRequest(TransportError.Timeout())
            (fake.request(message, 1.seconds) is TransportResult.Failure) shouldBe true
            fake.respondWith { _, _ -> TransportResult.Success(InboundMessage(message.address, byteArrayOf(2))) }
            (fake.request(message, 1.seconds) is TransportResult.Success) shouldBe true
            fake.failNextSubscribe(TransportError.Failure(IllegalStateException()))
            (fake.subscribe(AddressPattern.of("book.*")) is TransportResult.Failure) shouldBe true
            (fake.subscribe(AddressPattern.of("book.*")) is TransportResult.Success) shouldBe true
            fake.actions.map { it::class.simpleName } shouldBe listOf(
                "Publish",
                "Publish",
                "Request",
                "Request",
                "Subscribe",
                "Subscribe"
            )
        }
    }

    test("wildcards deliver only matching messages") {
        runTest {
            val fake = FakeMessageTransport()
            val subscription = (fake.subscribe(AddressPattern.of("book.*")) as TransportResult.Success).value
            val received = async { subscription.deliveries.first() }
            fake.deliver(TransportDelivery.Message(InboundMessage(MessageAddress.of("other.one"), byteArrayOf())))
            fake.deliver(TransportDelivery.Message(InboundMessage(MessageAddress.of("book.one"), byteArrayOf(7))))
            ((received.await() as TransportDelivery.Message).message.payload.single()) shouldBe 7
        }
    }

    test("all close paths are idempotent and post-close delivery is ignored") {
        runTest {
            suspend fun verify(close: suspend (FakeMessageTransport, TransportSubscription) -> Unit) {
                val fake = FakeMessageTransport()
                val pattern = AddressPattern.of("book.*")
                val subscription = (fake.subscribe(pattern) as TransportResult.Success).value
                close(fake, subscription)
                close(fake, subscription)
                fake.deliver(TransportDelivery.Message(InboundMessage(MessageAddress.of("book.one"), byteArrayOf())))
                fake.actions.count { it is FakeMessageTransport.Action.SubscriptionClose } shouldBe 1
            }
            verify { fake, _ -> fake.deliver(TransportDelivery.Completed) }
            verify { _, subscription -> subscription.close() }
            verify { fake, _ -> fake.close() }
        }
    }

    test("recorded payloads are defensive snapshots") {
        runTest {
            val fake = FakeMessageTransport()
            val payload = byteArrayOf(1, 2)
            fake.publish(OutboundMessage(MessageAddress.of("book.one"), payload))
            payload[0] = 9
            ((fake.actions.single() as FakeMessageTransport.Action.Publish).message.payload.toList()) shouldBe listOf<Byte>(
                1,
                2
            )
        }
    }
}
