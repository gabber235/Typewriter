package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.CommunicatorRoutes
import com.typewritermc.services.libs.communicator.router.RouterOptions
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.communicator.transport.MessagingSystem
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.ReplyChannel
import com.typewritermc.services.libs.communicator.transport.SubscriptionOptions
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.communicator.transport.TransportSubscription
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlin.time.Duration

/** The target whose `{id}` segment the test address templates fill. */
data class TestTarget(
    val id: String,
)

/** Propagators with W3C trace context only, the set the communicator fixtures inject with. */
val testPropagators: ContextPropagators = ContextPropagators.create(W3CTraceContextPropagator.getInstance())

/** Encodes text as UTF-8. Decoding the text `bad` fails, so a test can provoke a decode error. */
val stringPayloadCodec: PayloadCodec<String> =
    object : PayloadCodec<String> {
        override fun encode(value: String) = Payload.copyOf(value.encodeToByteArray())

        override fun decode(payload: Payload) = payload.toByteArray().decodeToString().also { if (it == "bad") error("decode") }
    }

/** A codec whose encode or decode step throws, to check that the communicator maps the failure. */
fun throwingCodec(encode: Boolean): PayloadCodec<String> =
    object : PayloadCodec<String> {
        override fun encode(value: String): Payload = if (encode) error("encode") else Payload.copyOf(value.encodeToByteArray())

        override fun decode(payload: Payload): String = if (!encode) error("decode") else payload.toByteArray().decodeToString()
    }

/** Address template for `service.{id}.get` requests, filled from [TestTarget]. */
val serviceRequestAddress =
    "service.{id}.get".addressTemplate({ addressValuesOf("id" to it.id) }, { TestTarget(it.require("id")) })

/** Address template for `service.{id}.updates` streams, filled from [TestTarget]. */
val serviceUpdateAddress =
    "service.{id}.updates".addressTemplate({ addressValuesOf("id" to it.id) }, { TestTarget(it.require("id")) })

/** Address template for `router.{id}.get` requests, filled from [TestTarget]. */
val routerAddress =
    "router.{id}.get".addressTemplate({ addressValuesOf("id" to it.id) }, { TestTarget(it.require("id")) })

/** Event contract of the router tests, published to [routerAddress]. */
val routerEvent =
    EventContract(
        OperationName.of("router.event"),
        routerAddress,
        stringPayloadCodec,
        ErrorSlug.of("router-event-failed"),
    )

/** Event contract on `other.{id}.get`, a second route beside the `router.{id}.get` ones. */
val routerOtherEvent =
    EventContract(
        OperationName.of("router.other"),
        "other.{id}.get".addressTemplate({ addressValuesOf("id" to it.id) }, { TestTarget(it.require("id")) }),
        stringPayloadCodec,
        ErrorSlug.of("router-other-failed"),
    )

/** Routes holding [routerEvent] and [routerOtherEvent]. */
fun twoEventRoutes(): CommunicatorRoutes =
    communicatorRoutes {
        event(routerEvent) { }
        event(routerOtherEvent) { }
    }

/** A delivery of [payload] to [address], with an optional reply address, as the transport would hand it over. */
fun deliveryOf(
    address: String,
    payload: String = "message",
    replyTo: String? = null,
) = TransportDelivery.Message(
    InboundMessage(
        MessageAddress.of(address),
        payload.encodeToByteArray(),
        replyTo?.let(MessageAddress::of),
    ),
)

/** A communicator over a [FakeMessageTransport] and a telemetry harness, closed together. */
data class CommunicatorFixture(
    val client: Communicator,
    val fake: FakeMessageTransport,
    val harness: TelemetryTestHarness,
) : AutoCloseable {
    override fun close() {
        fake.close()
        harness.close()
    }
}

/** Builds a [CommunicatorFixture]; [deliveryBufferCapacity] bounds the fake's delivery buffer. */
fun communicatorFixture(
    configuredPropagators: ContextPropagators = testPropagators,
    deliveryBufferCapacity: Int = Channel.UNLIMITED,
): CommunicatorFixture {
    val fake = FakeMessageTransport(deliveryBufferCapacity = deliveryBufferCapacity)
    val harness = TelemetryTestHarness.create()
    return CommunicatorFixture(Communicator(fake, harness.telemetry, configuredPropagators), fake, harness)
}

/** A subscription whose [deliveries] are scripted and whose close may throw [closeFailure]. */
class TestSubscription(
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

/** A communicator whose transport answers a request with `initial` and subscribes to a [TestSubscription]. */
data class ThrowingWatchFixture(
    val client: Communicator,
    val subscription: TestSubscription,
    val harness: TelemetryTestHarness,
) : AutoCloseable {
    override fun close() = harness.close()
}

/** Builds a [ThrowingWatchFixture] over [deliveries]; the subscription's close throws [closeFailure] when set. */
fun throwingWatchFixture(
    deliveries: Flow<TransportDelivery>,
    closeFailure: Throwable? = null,
): ThrowingWatchFixture {
    val subscription = TestSubscription(deliveries, closeFailure)
    val transport =
        object : MessageTransport {
            override val system = MessagingSystem.of("test")

            override suspend fun openReplyChannel(): TransportResult<ReplyChannel> = error("Unexpected reply channel")

            override suspend fun publish(message: OutboundMessage): TransportResult<Unit> = error("Unexpected publish")

            override suspend fun request(
                message: OutboundMessage,
                timeout: Duration,
                limits: TransportLimits?,
            ) = TransportResult.Success(InboundMessage(message.address, "initial".encodeToByteArray()))

            override suspend fun subscribe(
                pattern: AddressPattern,
                options: SubscriptionOptions,
            ) = TransportResult.Success(subscription)
        }
    val harness = TelemetryTestHarness.create()
    return ThrowingWatchFixture(Communicator(transport, harness.telemetry, testPropagators), subscription, harness)
}

/** A router over a [FakeMessageTransport] with its own communicator and telemetry, closed together. */
class RouterFixture(
    val router: CommunicatorRouter,
    val fake: FakeMessageTransport,
    val harness: TelemetryTestHarness,
) : AutoCloseable {
    override fun close() {
        fake.close()
        harness.close()
    }
}

/** Builds a [RouterFixture] that serves [routes] on [scope]. */
fun routerFixture(
    routes: CommunicatorRoutes,
    scope: CoroutineScope,
    options: RouterOptions = RouterOptions(),
): RouterFixture {
    val fake = FakeMessageTransport()
    val harness = TelemetryTestHarness.create()
    val communicator = Communicator(fake, harness.telemetry, testPropagators)
    return RouterFixture(
        CommunicatorRouter(fake, routes, communicator, harness.telemetry, testPropagators, scope, options),
        fake,
        harness,
    )
}
