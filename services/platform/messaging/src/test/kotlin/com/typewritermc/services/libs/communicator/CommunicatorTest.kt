package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.EncodedPublication
import com.typewritermc.services.libs.communicator.client.ScatterPolicy
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.ReplyAddressRule
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.ScatterContract
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.contract.WatchContract
import com.typewritermc.services.libs.communicator.contract.WatchMessage
import com.typewritermc.services.libs.communicator.result.CommunicationError
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.testing.TestTarget
import com.typewritermc.services.libs.communicator.testing.communicatorFixture
import com.typewritermc.services.libs.communicator.testing.serviceRequestAddress
import com.typewritermc.services.libs.communicator.testing.serviceUpdateAddress
import com.typewritermc.services.libs.communicator.testing.stringPayloadCodec
import com.typewritermc.services.libs.communicator.testing.throwingCodec
import com.typewritermc.services.libs.communicator.testing.throwingWatchFixture
import com.typewritermc.services.libs.communicator.transfer.TransferTooLarge
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.jobSpan
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.kotest.matchers.types.shouldBeSameInstanceAs
import io.opentelemetry.api.baggage.Baggage
import io.opentelemetry.api.baggage.propagation.W3CBaggagePropagator
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator
import io.opentelemetry.context.Context
import io.opentelemetry.context.propagation.ContextPropagators
import io.opentelemetry.context.propagation.TextMapPropagator
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

@OptIn(ExperimentalCoroutinesApi::class)
val CommunicatorTest by testSuite {
    val successPolicy =
        ResponsePolicy(
            "internal",
            {
                ResponseClassification(
                    if (it == "internal") ResponseOutcome.INTERNAL_ERROR else ResponseOutcome.SUCCESS,
                    ResponseVariant.of(it),
                )
            },
        )

    /** Answers every reply address; CommunicatorRouterTest covers the reply rule itself. */
    val anyReply = ReplyAddressRule<Any> { _, _ -> true }

    val unary =
        UnaryContract(
            OperationName.of("book.get"),
            serviceRequestAddress,
            stringPayloadCodec,
            stringPayloadCodec,
            successPolicy,
            anyReply,
            2.seconds,
            ErrorSlug.of("book-get-failed"),
        )

    val scatter =
        ScatterContract(
            OperationName.of("host.probe"),
            serviceRequestAddress,
            stringPayloadCodec,
            stringPayloadCodec,
            successPolicy,
            anyReply,
            ErrorSlug.of("host-probe-failed"),
        )

    val event =
        EventContract(OperationName.of("book.changed"), serviceRequestAddress, stringPayloadCodec, ErrorSlug.of("book-publish-failed"))

    val watch =
        WatchContract(
            OperationName.of("book.watch"),
            serviceRequestAddress,
            serviceUpdateAddress,
            stringPayloadCodec,
            stringPayloadCodec,
            stringPayloadCodec,
            successPolicy,
            anyReply,
            2.seconds,
            ErrorSlug.of("book-watch-failed"),
        )

    test("scatter subscribes before publishing and collects every expected reply") {
        runTest {
            communicatorFixture().use { (client, fake, harness) ->
                val result =
                    async {
                        client
                            .scatter(
                                scatter,
                                TestTarget("realm"),
                                "probe",
                                ScatterPolicy(2.seconds) { responses -> responses.size == 2 },
                            ).toList()
                    }
                runCurrent()
                val actions = fake.actions
                actions.first()::class shouldBe FakeMessageTransport.Action.Subscribe::class
                val publication = actions.filterIsInstance<FakeMessageTransport.Action.Publish>().single().message
                val inbox = requireNotNull(publication.replyTo)
                fake.deliver(TransportDelivery.Message(InboundMessage(inbox, "host-a".encodeToByteArray())))
                fake.deliver(TransportDelivery.Message(InboundMessage(inbox, "host-b".encodeToByteArray())))

                result.await() shouldBe
                    listOf(
                        CommunicationResult.Success("host-a"),
                        CommunicationResult.Success("host-b"),
                    )
                fake.activeSubscriptionCount shouldBe 0
                val span = harness.finishedSpans().single { it.name == "host.probe scatter" }
                span.attributes[AttributeKey.longKey("messaging.reply.count")] shouldBe 2L
                span.attributes[AttributeKey.stringKey("messaging.destination.name")] shouldBe "service.realm.get"
                span.attributes[AttributeKey.stringKey("operation.outcome")] shouldBe "success"
            }
        }
    }

    test("scatter reports one responder's transfer failure and keeps collecting") {
        runTest {
            communicatorFixture().use { (client, fake, _) ->
                val result =
                    async {
                        client
                            .scatter(
                                scatter,
                                TestTarget("realm"),
                                "probe",
                                ScatterPolicy(2.seconds) { responses -> responses.size == 1 },
                            ).toList()
                    }
                runCurrent()
                val inbox =
                    requireNotNull(fake.publications.single().replyTo)
                val tooLarge = TransferTooLarge(size = 10, limit = 5)

                fake.deliver(TransportDelivery.Failure(TransportError.Failure(tooLarge)))
                fake.deliver(TransportDelivery.Message(InboundMessage(inbox, "host-b".encodeToByteArray())))

                result.await() shouldBe
                    listOf(
                        CommunicationResult.Failure(CommunicationError.Transport(scatter.failureSlug, tooLarge)),
                        CommunicationResult.Success("host-b"),
                    )
                fake.activeSubscriptionCount shouldBe 0
            }
        }
    }

    test("scatter completes after the configured quiet period") {
        runTest {
            communicatorFixture().use { (client, fake, _) ->
                val result =
                    async { client.scatter(scatter, TestTarget("realm"), "probe", ScatterPolicy(2.seconds, 100.milliseconds)).toList() }
                runCurrent()
                val publication =
                    fake.publications.single()
                val inbox = requireNotNull(publication.replyTo)

                fake.deliver(TransportDelivery.Message(InboundMessage(inbox, "host-a".encodeToByteArray())))
                advanceTimeBy(101)
                runCurrent()

                result.await() shouldBe listOf(CommunicationResult.Success("host-a"))
                fake.activeSubscriptionCount shouldBe 0
            }
        }
    }

    test("response policy rejects an internal response not classified as internal error") {
        shouldThrow<IllegalArgumentException> {
            ResponsePolicy("fixed") {
                ResponseClassification(ResponseOutcome.SUCCESS, ResponseVariant.of("success"))
            }
        }
    }

    test("unary renders destination, honors timeout, and decodes success") {
        runTest {
            communicatorFixture().use { (client, fake, _) ->
                fake.respondWith { message, timeout ->
                    message.address.value shouldBe "service.alpha.get"
                    timeout shouldBe 25.milliseconds
                    TransportResult.Success(InboundMessage(message.address, "ok".encodeToByteArray()))
                }
                client.request(
                    unary,
                    TestTarget("alpha"),
                    "request",
                    timeout = 25.milliseconds,
                ) shouldBe CommunicationResult.Success("ok")
            }
        }
    }

    test("unary maps codecs and every transport error") {
        runTest {
            communicatorFixture().use { (client, fake, _) ->
                val brokenEncode =
                    UnaryContract(
                        unary.name,
                        serviceRequestAddress,
                        throwingCodec(true),
                        stringPayloadCodec,
                        successPolicy,
                        anyReply,
                        1.seconds,
                        unary.failureSlug,
                    )
                (
                    client.request(
                        brokenEncode,
                        TestTarget("a"),
                        "x",
                    ) as CommunicationResult.Failure
                ).error::class shouldBe CommunicationError.Encode::class
                fake.respondWith { message, _ ->
                    TransportResult.Success(
                        InboundMessage(
                            message.address,
                            "bad".encodeToByteArray(),
                        ),
                    )
                }
                (
                    client.request(
                        unary,
                        TestTarget("a"),
                        "x",
                    ) as CommunicationResult.Failure
                ).error::class shouldBe CommunicationError.Decode::class
                listOf(
                    TransportError.Timeout() to CommunicationError.Timeout::class,
                    TransportError.Unavailable() to CommunicationError.Unavailable::class,
                    TransportError.NoResponders() to CommunicationError.NoResponders::class,
                    TransportError.Failure(IllegalStateException()) to CommunicationError.Transport::class,
                ).forEach { (transport, expected) ->
                    fake.failNextRequest(transport)
                    (
                        client.request(
                            unary,
                            TestTarget("a"),
                            "x",
                        ) as CommunicationResult.Failure
                    ).error::class shouldBe expected
                }
            }
        }
    }

    test("publish injects W3C context and maps failure") {
        runTest {
            communicatorFixture().use { (client, fake, harness) ->
                harness.telemetry.jobSpan("parent", ErrorSlug.of("parent-failed")) { _ ->
                    client.publish(
                        event,
                        TestTarget("a"),
                        "value",
                    )
                }
                val published = (fake.actions.single() as FakeMessageTransport.Action.Publish).message
                published.headers["traceparent"].size shouldBe 1
                fake.failNextPublish(TransportError.Unavailable())
                (
                    client.publish(
                        event,
                        TestTarget("a"),
                        "value",
                    ) as CommunicationResult.Failure
                ).error::class shouldBe CommunicationError.Unavailable::class
            }
        }
    }

    test("outbound injection replaces stale headers owned by configured propagators") {
        runTest {
            val staleHeaders =
                MessageHeaders.of(
                    "traceparent" to "stale-parent",
                    "tracestate" to "stale-state",
                    "baggage" to "stale=value",
                )
            communicatorFixture().use { (client, fake, harness) ->
                harness.telemetry.jobSpan("parent", ErrorSlug.of("parent-failed")) { _ ->
                    client.publish(event, TestTarget("a"), "value", staleHeaders)
                }
                val headers = (fake.actions.single() as FakeMessageTransport.Action.Publish).message.headers
                headers["traceparent"].size shouldBe 1
                (headers["traceparent"].single() == "stale-parent") shouldBe false
                headers["tracestate"] shouldBe emptyList()
                headers["baggage"] shouldBe listOf("stale=value")
            }

            val traceAndBaggage =
                ContextPropagators.create(
                    TextMapPropagator.composite(
                        W3CTraceContextPropagator.getInstance(),
                        W3CBaggagePropagator.getInstance(),
                    ),
                )
            communicatorFixture(traceAndBaggage).use { (client, fake, harness) ->
                val context =
                    Baggage
                        .builder()
                        .put("fresh", "value")
                        .build()
                        .storeInContext(Context.current())
                context.makeCurrent().use {
                    harness.telemetry.jobSpan("parent", ErrorSlug.of("parent-failed")) { _ ->
                        client.publish(event, TestTarget("a"), "value", staleHeaders)
                    }
                }
                val headers = (fake.actions.single() as FakeMessageTransport.Action.Publish).message.headers
                headers["baggage"] shouldBe listOf("fresh=value")
            }
        }
    }

    test("standalone operation has safe root messaging telemetry") {
        runTest {
            communicatorFixture().use { (client, fake, harness) ->
                fake.respondWith { message, _ ->
                    TransportResult.Success(
                        InboundMessage(
                            message.address,
                            "ok".encodeToByteArray(),
                        ),
                    )
                }
                client.request(unary, TestTarget("secret"), "body", MessageHeaders.of("X-Secret" to "hidden"))
                val span = harness.finishedSpans().single()
                span.name shouldBe "book.get request"
                span.kind shouldBe SpanKind.CLIENT
                span.parentSpanId shouldBe "0000000000000000"
                span.attributes[AttributeKey.stringKey("messaging.destination.name")] shouldBe "service.secret.get"
                span.attributes[AttributeKey.stringKey("messaging.destination.template")] shouldBe "service.{id}.get"
                span.attributes
                    .asMap()
                    .values
                    .contains("body") shouldBe false
                span.attributes
                    .asMap()
                    .values
                    .contains("hidden") shouldBe false
            }
        }
    }

    test("nested operation is a child and does not change parent outcome") {
        runTest {
            communicatorFixture().use { (client, fake, harness) ->
                harness.telemetry.jobSpan("parent", ErrorSlug.of("parent-failed")) { _ ->
                    fake.failNextPublish(TransportError.Failure(IllegalStateException("private")))
                    client.publish(event, TestTarget("a"), "value")
                }
                val parent = harness.finishedSpans().single { it.name == "parent" }
                val child = harness.finishedSpans().single { it.name == "book.changed publish" }
                child.parentSpanId shouldBe parent.spanId
                parent.status.statusCode shouldBe StatusCode.UNSET
                child.status.statusCode shouldBe StatusCode.ERROR
                child.attributes[AttributeKey.stringKey("exception.slug")] shouldBe "book-publish-failed"
            }
        }
    }

    test("encoded publication sends the exact immutable payload") {
        runTest {
            communicatorFixture().use { (client, fake, _) ->
                val source = byteArrayOf(0, 1, 2, 127, -1)
                val publication = EncodedPublication(MessageAddress.of("service.realm.watch"), Payload.copyOf(source))
                source.fill(42)

                client.publishEncoded(publication) shouldBe CommunicationResult.Success(Unit)

                val sent =
                    fake.publications.single()
                sent.address shouldBe publication.address
                sent.payload.toByteArray().toList() shouldBe listOf<Byte>(0, 1, 2, 127, -1)
                sent.replyTo shouldBe null
            }
        }
    }

    test("typed internal response is success without exception based span failure") {
        runTest {
            communicatorFixture().use { (client, fake, harness) ->
                fake.respondWith { message, _ ->
                    TransportResult.Success(
                        InboundMessage(
                            message.address,
                            "internal".encodeToByteArray(),
                        ),
                    )
                }
                client.request(unary, TestTarget("a"), "x") shouldBe CommunicationResult.Success("internal")
                val span = harness.finishedSpans().single()
                span.status.statusCode shouldBe StatusCode.UNSET
                span.attributes[AttributeKey.stringKey("domain.outcome")] shouldBe "internal"
            }
        }
    }

    test("watch is cold and subscribes exact update address before requesting") {
        runTest {
            communicatorFixture().use { (client, fake, harness) ->
                fake.respondWith { message, _ -> TransportResult.Success(InboundMessage(message.address, "ok".encodeToByteArray())) }
                val flow = client.watch(watch, TestTarget("a"), "start")
                fake.actions shouldBe emptyList()
                val collected = async { flow.take(1).toList() }
                runCurrent()
                fake.actions.take(2).map { it::class.simpleName } shouldBe listOf("Subscribe", "Request")
                (fake.actions[0] as FakeMessageTransport.Action.Subscribe).pattern.value shouldBe "service.a.updates"
                fake.deliver(
                    TransportDelivery.Message(
                        InboundMessage(
                            MessageAddress.of("service.b.updates"),
                            "wrong".encodeToByteArray(),
                        ),
                    ),
                )
                fake.deliver(
                    TransportDelivery.Message(
                        InboundMessage(
                            MessageAddress.of("service.a.updates"),
                            "ok".encodeToByteArray(),
                        ),
                    ),
                )
                collected.await() shouldBe listOf(CommunicationResult.Success(WatchMessage.Initial("ok")))
                fake.actions.count { it is FakeMessageTransport.Action.SubscriptionClose } shouldBe 1
                harness.assertNoActiveSpans()
            }
        }
    }

    test("watch buffers a zero-replay delivery until after the initial response") {
        runTest {
            communicatorFixture(deliveryBufferCapacity = 0).use { (client, fake, _) ->
                fake.respondWith { message, _ ->
                    fake.deliver(
                        TransportDelivery.Message(
                            InboundMessage(MessageAddress.of("service.a.updates"), "early".encodeToByteArray()),
                        ),
                    )
                    TransportResult.Success(InboundMessage(message.address, "initial".encodeToByteArray()))
                }

                client.watch(watch, TestTarget("a"), "start").take(2).toList() shouldBe
                    listOf(
                        CommunicationResult.Success(WatchMessage.Initial("initial")),
                        CommunicationResult.Success(WatchMessage.Update("early")),
                    )
                fake.activeSubscriptionCount shouldBe 0
            }
        }
    }

    test("watch update filter isolates resource updates") {
        runTest {
            communicatorFixture().use { (client, fake, _) ->
                fake.respondWith { message, _ ->
                    TransportResult.Success(InboundMessage(message.address, "initial".encodeToByteArray()))
                }
                val isolated =
                    WatchContract(
                        watch.name,
                        watch.requestAddress,
                        watch.updateAddress,
                        watch.requestCodec,
                        watch.initialCodec,
                        watch.updateCodec,
                        watch.initialPolicy,
                        watch.replyAddresses,
                        watch.timeout,
                        watch.failureSlug,
                        updateFilter = { request, update -> request == update },
                    )
                val values = async { client.watch(isolated, TestTarget("a"), "wanted").take(2).toList() }
                runCurrent()

                fake.deliver(
                    TransportDelivery.Message(
                        InboundMessage(MessageAddress.of("service.a.updates"), "other".encodeToByteArray()),
                    ),
                )
                fake.deliver(
                    TransportDelivery.Message(
                        InboundMessage(MessageAddress.of("service.a.updates"), "wanted".encodeToByteArray()),
                    ),
                )

                values.await() shouldBe
                    listOf(
                        CommunicationResult.Success(WatchMessage.Initial("initial")),
                        CommunicationResult.Success(WatchMessage.Update("wanted")),
                    )
            }
        }
    }

    test("watch delivery flow failure escapes after the initial response") {
        runTest {
            val deliveryFailure = IllegalStateException("deliveries")
            throwingWatchFixture(flow { throw deliveryFailure }).use { (client, subscription, _) ->
                val thrown =
                    shouldThrow<IllegalStateException> {
                        client.watch(watch, TestTarget("a"), "start").toList()
                    }

                thrown shouldBeSameInstanceAs deliveryFailure
                subscription.closed shouldBe true
            }
        }
    }

    test("watch close failure escapes when there is no primary failure") {
        runTest {
            val closeFailure = IllegalStateException("close")
            throwingWatchFixture(flowOf(TransportDelivery.Completed), closeFailure).use { (client, _, _) ->
                val thrown =
                    shouldThrow<IllegalStateException> {
                        client.watch(watch, TestTarget("a"), "start").toList()
                    }

                thrown shouldBeSameInstanceAs closeFailure
            }
        }
    }

    test("watch preserves delivery failure and suppresses close failure once") {
        runTest {
            val deliveryFailure = IllegalStateException("deliveries")
            val closeFailure = IllegalArgumentException("close")
            throwingWatchFixture(flow { throw deliveryFailure }, closeFailure).use { (client, _, _) ->
                val thrown =
                    shouldThrow<IllegalStateException> {
                        client.watch(watch, TestTarget("a"), "start").toList()
                    }

                thrown shouldBeSameInstanceAs deliveryFailure
                thrown.suppressed.toList() shouldBe listOf(closeFailure)
            }
        }
    }

    test("watch caller cancellation remains cancellation and closes subscription") {
        runTest {
            throwingWatchFixture(flow { awaitCancellation() }).use { (client, subscription, _) ->
                val collection = async { client.watch(watch, TestTarget("a"), "start").toList() }
                runCurrent()

                collection.cancel()
                shouldThrow<CancellationException> { collection.await() }
                subscription.closed shouldBe true
            }
        }
    }

    test("a watch update that cannot be decoded is reported as a decode failure and later updates still arrive") {
        runTest {
            communicatorFixture().use { (client, fake, _) ->
                fake.respondWith { message, _ -> TransportResult.Success(InboundMessage(message.address, "ok".encodeToByteArray())) }
                val values = async { client.watch(watch, TestTarget("a"), "start").toList() }
                runCurrent()

                fake.deliver(TransportDelivery.Message(InboundMessage(MessageAddress.of("service.a.updates"), "bad".encodeToByteArray())))
                fake.deliver(TransportDelivery.Message(InboundMessage(MessageAddress.of("service.a.updates"), "later".encodeToByteArray())))
                fake.deliver(TransportDelivery.Completed)

                val results = values.await()
                results[1].shouldBeInstanceOf<CommunicationResult.Failure>().error.shouldBeInstanceOf<CommunicationError.Decode>()
                results[2] shouldBe CommunicationResult.Success(WatchMessage.Update("later"))
            }
        }
    }

    test("a terminal subscription failure ends the watch with that failure and an error span") {
        runTest {
            communicatorFixture().use { (client, fake, harness) ->
                fake.respondWith { message, _ -> TransportResult.Success(InboundMessage(message.address, "ok".encodeToByteArray())) }
                val values = async { client.watch(watch, TestTarget("a"), "start").toList() }
                runCurrent()

                fake.deliver(TransportDelivery.Failure(TransportError.Unavailable()))

                values
                    .await()
                    .last()
                    .shouldBeInstanceOf<CommunicationResult.Failure>()
                    .error
                    .shouldBeInstanceOf<CommunicationError.Unavailable>()
                harness
                    .finishedSpans()
                    .last { it.name == "book.watch receive" }
                    .status.statusCode shouldBe StatusCode.ERROR
                harness.assertNoActiveSpans()
            }
        }
    }
}
