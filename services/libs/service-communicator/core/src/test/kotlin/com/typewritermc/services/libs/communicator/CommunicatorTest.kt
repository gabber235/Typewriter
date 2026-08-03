package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.contract.WatchContract
import com.typewritermc.services.libs.communicator.contract.WatchMessage
import com.typewritermc.services.libs.communicator.result.CommunicationError
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.communicator.transport.MessagingSystem
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.SubscriptionOptions
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.communicator.transport.TransportSubscription
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.jobSpan
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
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
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.flowOf
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds

private data class Target(
    val id: String,
)

private val requestAddress =
    addressTemplate("service.{id}.get", { addressValuesOf("id" to it.id) }, { Target(it.require("id")) })
private val updateAddress =
    addressTemplate("service.{id}.updates", { addressValuesOf("id" to it.id) }, { Target(it.require("id")) })
private val strings =
    object : PayloadCodec<String> {
        override fun encode(value: String) = value.encodeToByteArray()

        override fun decode(payload: ByteArray) = payload.decodeToString().also { if (it == "bad") error("decode") }
    }
private val successPolicy =
    ResponsePolicy(
        "internal",
        {
            ResponseClassification(
                if (it == "internal") ResponseOutcome.INTERNAL_ERROR else ResponseOutcome.SUCCESS,
                ResponseVariant.of(it),
            )
        },
    )
private val unary =
    UnaryContract(
        OperationName.of("book.get"),
        requestAddress,
        strings,
        strings,
        successPolicy,
        2.seconds,
        ErrorSlug.of("book-get-failed"),
    )
private val event =
    EventContract(OperationName.of("book.changed"), requestAddress, strings, ErrorSlug.of("book-publish-failed"))
private val watch =
    WatchContract(
        OperationName.of("book.watch"),
        requestAddress,
        updateAddress,
        strings,
        strings,
        strings,
        successPolicy,
        successPolicy,
        2.seconds,
        ErrorSlug.of("book-watch-failed"),
    )
private val propagators = ContextPropagators.create(W3CTraceContextPropagator.getInstance())

@OptIn(ExperimentalCoroutinesApi::class)
val CommunicatorTest by testSuite {
    test("communicator creates a router with its private infrastructure") {
        runTest {
            fixture().use { (client, fake, _) ->
                val router = client.createRouter(communicatorRoutes { event(event) { } }, this)

                router.start() shouldBe RouterResult.Success
                fake.activeSubscriptionCount shouldBe 1
                router.stop() shouldBe RouterResult.Success
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
            fixture().use { (client, fake, _) ->
                fake.respondWith { message, timeout ->
                    message.address.value shouldBe "service.alpha.get"
                    timeout shouldBe 25.milliseconds
                    TransportResult.Success(InboundMessage(message.address, "ok".encodeToByteArray()))
                }
                client.request(
                    unary,
                    Target("alpha"),
                    "request",
                    timeout = 25.milliseconds,
                ) shouldBe CommunicationResult.Success("ok")
            }
        }
    }

    test("unary maps codecs and every transport error") {
        runTest {
            fixture().use { (client, fake, _) ->
                val brokenEncode =
                    UnaryContract(
                        unary.name,
                        requestAddress,
                        throwingCodec(true),
                        strings,
                        successPolicy,
                        1.seconds,
                        unary.failureSlug,
                    )
                (
                    client.request(
                        brokenEncode,
                        Target("a"),
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
                        Target("a"),
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
                            Target("a"),
                            "x",
                        ) as CommunicationResult.Failure
                    ).error::class shouldBe expected
                }
            }
        }
    }

    test("publish injects W3C context and maps failure") {
        runTest {
            fixture().use { (client, fake, harness) ->
                harness.telemetry.jobSpan("parent", ErrorSlug.of("parent-failed")) { _ ->
                    client.publish(
                        event,
                        Target("a"),
                        "value",
                    )
                }
                val published = (fake.actions.single() as FakeMessageTransport.Action.Publish).message
                published.headers["traceparent"].size shouldBe 1
                fake.failNextPublish(TransportError.Unavailable())
                (
                    client.publish(
                        event,
                        Target("a"),
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
            fixture().use { (client, fake, harness) ->
                harness.telemetry.jobSpan("parent", ErrorSlug.of("parent-failed")) { _ ->
                    client.publish(event, Target("a"), "value", staleHeaders)
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
            fixture(traceAndBaggage).use { (client, fake, harness) ->
                val context =
                    Baggage
                        .builder()
                        .put("fresh", "value")
                        .build()
                        .storeInContext(Context.current())
                context.makeCurrent().use {
                    harness.telemetry.jobSpan("parent", ErrorSlug.of("parent-failed")) { _ ->
                        client.publish(event, Target("a"), "value", staleHeaders)
                    }
                }
                val headers = (fake.actions.single() as FakeMessageTransport.Action.Publish).message.headers
                headers["baggage"] shouldBe listOf("fresh=value")
            }
        }
    }

    test("standalone operation has safe root messaging telemetry") {
        runTest {
            fixture().use { (client, fake, harness) ->
                fake.respondWith { message, _ ->
                    TransportResult.Success(
                        InboundMessage(
                            message.address,
                            "ok".encodeToByteArray(),
                        ),
                    )
                }
                client.request(unary, Target("secret"), "body", MessageHeaders.of("X-Secret" to "hidden"))
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
            fixture().use { (client, fake, harness) ->
                harness.telemetry.jobSpan("parent", ErrorSlug.of("parent-failed")) { _ ->
                    fake.failNextPublish(TransportError.Failure(IllegalStateException("private")))
                    client.publish(event, Target("a"), "value")
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

    test("publish update classifier failures are recorded by producer telemetry") {
        runTest {
            fixture().use { (client, _, harness) ->
                val programmerError = IllegalStateException("classifier")
                val policy =
                    ResponsePolicy<String>("internal") { value ->
                        if (value == "update") throw programmerError
                        ResponseClassification(ResponseOutcome.INTERNAL_ERROR, ResponseVariant.of("internal"))
                    }
                val contract =
                    WatchContract(
                        watch.name,
                        requestAddress,
                        updateAddress,
                        strings,
                        strings,
                        strings,
                        successPolicy,
                        policy,
                        watch.timeout,
                        watch.failureSlug,
                    )
                val thrown = shouldThrow<Throwable> { client.publishUpdate(contract, Target("a"), "update") }
                generateSequence(thrown) { it.cause }.contains(programmerError) shouldBe true
                val span = harness.finishedSpans().single()
                span.name shouldBe "book.watch publish"
                span.status.statusCode shouldBe StatusCode.ERROR
                span.attributes[AttributeKey.stringKey("messaging.destination.template")] shouldBe "service.{id}.updates"
            }
        }
    }

    test("typed internal response is success but operation span is error") {
        runTest {
            fixture().use { (client, fake, harness) ->
                fake.respondWith { message, _ ->
                    TransportResult.Success(
                        InboundMessage(
                            message.address,
                            "internal".encodeToByteArray(),
                        ),
                    )
                }
                client.request(unary, Target("a"), "x") shouldBe CommunicationResult.Success("internal")
                val span = harness.finishedSpans().single()
                span.status.statusCode shouldBe StatusCode.ERROR
                span.attributes[AttributeKey.stringKey("domain.outcome")] shouldBe "internal"
            }
        }
    }

    test("watch is cold and subscribes exact update address before requesting") {
        runTest {
            fixture().use { (client, fake, harness) ->
                fake.respondWith { message, _ -> TransportResult.Success(InboundMessage(message.address, "ok".encodeToByteArray())) }
                val flow = client.watch(watch, Target("a"), "start")
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
            fixture(deliveryBufferCapacity = 0).use { (client, fake, _) ->
                fake.respondWith { message, _ ->
                    fake.deliver(
                        TransportDelivery.Message(
                            InboundMessage(MessageAddress.of("service.a.updates"), "early".encodeToByteArray()),
                        ),
                    )
                    TransportResult.Success(InboundMessage(message.address, "initial".encodeToByteArray()))
                }

                client.watch(watch, Target("a"), "start").take(2).toList() shouldBe
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
            fixture().use { (client, fake, _) ->
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
                        watch.updateClassifier,
                        watch.timeout,
                        watch.failureSlug,
                        updateFilter = { request, update -> request == update },
                    )
                val values = async { client.watch(isolated, Target("a"), "wanted").take(2).toList() }
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
                        client.watch(watch, Target("a"), "start").toList()
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
                        client.watch(watch, Target("a"), "start").toList()
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
                        client.watch(watch, Target("a"), "start").toList()
                    }

                thrown shouldBeSameInstanceAs deliveryFailure
                thrown.suppressed.toList() shouldBe listOf(closeFailure)
            }
        }
    }

    test("watch caller cancellation remains cancellation and closes subscription") {
        runTest {
            throwingWatchFixture(flow { awaitCancellation() }).use { (client, subscription, _) ->
                val collection = async { client.watch(watch, Target("a"), "start").toList() }
                runCurrent()

                collection.cancel()
                shouldThrow<CancellationException> { collection.await() }
                subscription.closed shouldBe true
            }
        }
    }

    test("watch recovers after decode failure and terminal failure completes with error span") {
        runTest {
            fixture().use { (client, fake, harness) ->
                fake.respondWith { message, _ -> TransportResult.Success(InboundMessage(message.address, "ok".encodeToByteArray())) }
                val values = async { client.watch(watch, Target("a"), "start").toList() }
                runCurrent()
                val incoming =
                    MessageHeaders.of("traceparent" to "00-11111111111111111111111111111111-2222222222222222-01")
                fake.deliver(
                    TransportDelivery.Message(
                        InboundMessage(
                            MessageAddress.of("service.a.updates"),
                            "bad".encodeToByteArray(),
                            headers = incoming,
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
                fake.deliver(TransportDelivery.Failure(TransportError.Unavailable()))
                val results = values.await()
                results.map { it::class } shouldBe
                    listOf(
                        CommunicationResult.Success::class,
                        CommunicationResult.Failure::class,
                        CommunicationResult.Success::class,
                        CommunicationResult.Failure::class,
                    )
                harness
                    .finishedSpans()
                    .single { it.name == "book.watch receive" && it.parentSpanId == "2222222222222222" }
                harness
                    .finishedSpans()
                    .last { it.name == "book.watch receive" }
                    .status.statusCode shouldBe StatusCode.ERROR
                fake.actions.count { it is FakeMessageTransport.Action.SubscriptionClose } shouldBe 1
                harness.assertNoActiveSpans()
            }
        }
    }
}

private data class Fixture(
    val client: Communicator,
    val fake: FakeMessageTransport,
    val harness: TelemetryTestHarness,
) : AutoCloseable {
    override fun close() {
        fake.close()
        harness.close()
    }
}

private fun fixture(
    configuredPropagators: ContextPropagators = propagators,
    deliveryBufferCapacity: Int = kotlinx.coroutines.channels.Channel.UNLIMITED,
): Fixture {
    val fake = FakeMessageTransport(deliveryBufferCapacity = deliveryBufferCapacity)
    val harness = TelemetryTestHarness.create()
    return Fixture(Communicator(fake, harness.telemetry, configuredPropagators), fake, harness)
}

private data class ThrowingWatchFixture(
    val client: Communicator,
    val subscription: TestSubscription,
    val harness: TelemetryTestHarness,
) : AutoCloseable {
    override fun close() = harness.close()
}

private class TestSubscription(
    override val deliveries: Flow<TransportDelivery>,
    private val closeFailure: Throwable?,
) : TransportSubscription {
    var closed = false
        private set

    override suspend fun close() {
        closed = true
        closeFailure?.let { throw it }
    }
}

private fun throwingWatchFixture(
    deliveries: Flow<TransportDelivery>,
    closeFailure: Throwable? = null,
): ThrowingWatchFixture {
    val subscription = TestSubscription(deliveries, closeFailure)
    val transport =
        object : MessageTransport {
            override val system = MessagingSystem.of("test")

            override suspend fun publish(message: OutboundMessage): TransportResult<Unit> = error("Unexpected publish")

            override suspend fun request(
                message: OutboundMessage,
                timeout: kotlin.time.Duration,
            ) = TransportResult.Success(InboundMessage(message.address, "initial".encodeToByteArray()))

            override suspend fun subscribe(
                pattern: AddressPattern,
                options: SubscriptionOptions,
            ) = TransportResult.Success(subscription)
        }
    val harness = TelemetryTestHarness.create()
    return ThrowingWatchFixture(Communicator(transport, harness.telemetry, propagators), subscription, harness)
}

private fun throwingCodec(encode: Boolean) =
    object : PayloadCodec<String> {
        override fun encode(value: String): ByteArray = if (encode) error("encode") else value.encodeToByteArray()

        override fun decode(payload: ByteArray): String = if (!encode) error("decode") else payload.decodeToString()
    }
