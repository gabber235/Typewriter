package com.typewritermc.services.libs.communicator.nats

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.testing.NatsTestServer
import com.typewritermc.services.libs.communicator.testing.onBroker
import com.typewritermc.services.libs.communicator.testing.requireSubscription
import com.typewritermc.services.libs.communicator.testing.success
import com.typewritermc.services.libs.communicator.transport.ConsumerGroup
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.SubscriptionOptions
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportResult
import de.infix.testBalloon.framework.core.TestConfig
import de.infix.testBalloon.framework.core.testScope
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldStartWith
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import kotlinx.coroutines.withTimeout
import kotlin.time.Duration.Companion.seconds

/** The NATS transport against a real nats-server, for what only the broker decides: routing, queue groups, inboxes. */
val NatsTransportOnBrokerTest by testSuite(testConfig = TestConfig.testScope(isEnabled = false)) {
    val broker = testFixture { NatsTestServer.start() }

    test("a request carries its payload and repeated headers to the server and the reply back") {
        onBroker(broker().url) {
            val server = transport()
            val client = transport()
            val received = CompletableDeferred<InboundMessage>()
            val requests = server.subscribe(AddressPattern.of("work")).requireSubscription()
            val serving =
                launch {
                    val request = (requests.deliveries.first() as TransportDelivery.Message).message
                    received.complete(request)
                    server.publish(
                        OutboundMessage(
                            requireNotNull(request.replyTo),
                            byteArrayOf(9),
                            headers = MessageHeaders.of("Y" to "c", "Y" to "d"),
                        ),
                    ) shouldBe TransportResult.Success(Unit)
                }

            val reply =
                client
                    .request(
                        OutboundMessage(MessageAddress.of("work"), byteArrayOf(1, 2), headers = MessageHeaders.of("X" to "a", "X" to "b")),
                        5.seconds,
                    ).success()

            received.await().payload shouldBe Payload.copyOf(byteArrayOf(1, 2))
            received.await().headers["x"] shouldBe listOf("a", "b")
            reply.payload shouldBe Payload.copyOf(byteArrayOf(9))
            reply.headers["y"] shouldBe listOf("c", "d")
            serving.join()
            requests.close()
        }
    }

    test("members of one queue group share a subject's messages, each message reaching one member") {
        onBroker(broker().url) {
            val workers = transport()
            val publisher = transport()
            val group = SubscriptionOptions(ConsumerGroup.of("workers"))
            val members = List(2) { workers.subscribe(AddressPattern.of("jobs.*"), group).requireSubscription() }
            val delivered = Channel<Pair<Int, String>>(Channel.UNLIMITED)
            val collecting =
                members.mapIndexed { member, subscription ->
                    launch {
                        subscription.deliveries.collect { delivery ->
                            if (delivery is TransportDelivery.Message) delivered.send(member to delivery.message.address.value)
                        }
                    }
                }

            val jobs = List(JOBS) { "jobs.$it" }
            jobs.forEach { publisher.publish(OutboundMessage(MessageAddress.of(it), byteArrayOf())) shouldBe TransportResult.Success(Unit) }
            val received = withTimeout(5.seconds) { List(JOBS) { delivered.receive() } }

            received.map { it.second }.sorted() shouldBe jobs.sorted()
            received.map { it.first }.toSet() shouldBe setOf(0, 1)
            members.forEach { it.close() }
            collecting.forEach { it.join() }
        }
    }

    test("a message that arrives before anyone collects the subscription is still delivered") {
        onBroker(broker().url) {
            val subscriber = transport()
            val news = subscriber.subscribe(AddressPattern.of("news")).requireSubscription()
            val marker = subscriber.subscribe(AddressPattern.of("marker")).requireSubscription()
            val publisher = transport()

            publisher.publish(OutboundMessage(MessageAddress.of("news"), byteArrayOf(1))) shouldBe TransportResult.Success(Unit)
            publisher.publish(OutboundMessage(MessageAddress.of("marker"), byteArrayOf())) shouldBe TransportResult.Success(Unit)
            // The broker keeps one publisher's order, so once the marker is in, the news reached the subscriber uncollected.
            withTimeout(5.seconds) { marker.deliveries.first() }.shouldBeInstanceOf<TransportDelivery.Message>()

            val delivered = withTimeout(5.seconds) { news.deliveries.first() }.shouldBeInstanceOf<TransportDelivery.Message>()
            delivered.message.payload shouldBe Payload.copyOf(byteArrayOf(1))
            news.close()
            marker.close()
        }
    }

    test("closing a subscription completes its deliveries") {
        onBroker(broker().url) {
            val subscription = transport().subscribe(AddressPattern.of("news")).requireSubscription()
            val received = Channel<TransportDelivery>(Channel.UNLIMITED)
            val collecting = launch { subscription.deliveries.collect(received::send) }
            transport().publish(OutboundMessage(MessageAddress.of("news"), byteArrayOf(1))) shouldBe TransportResult.Success(Unit)
            withTimeout(5.seconds) { received.receive() }.shouldBeInstanceOf<TransportDelivery.Message>()

            subscription.close()

            withTimeout(5.seconds) { received.receive() } shouldBe TransportDelivery.Completed
            collecting.join()
        }
    }

    test("reply channels use the configured inbox prefix") {
        onBroker(broker().url) {
            val channel = (transport(inboxPrefix = "_TYPEWRITER_REPLY.").openReplyChannel() as TransportResult.Success).value

            channel.address.value shouldStartWith "_TYPEWRITER_REPLY."
            channel.close()
        }
    }
}

private const val JOBS = 40
