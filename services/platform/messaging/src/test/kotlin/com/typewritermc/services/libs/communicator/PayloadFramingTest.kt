package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ResponseVariant
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.router.CommunicatorRouter
import com.typewritermc.services.libs.communicator.router.RouterOptions
import com.typewritermc.services.libs.communicator.router.RouterResult
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.testing.BrokerMessage
import com.typewritermc.services.libs.communicator.testing.MemoryNatsBroker
import com.typewritermc.services.libs.communicator.transfer.Assembly
import com.typewritermc.services.libs.communicator.transfer.PayloadAssembler
import com.typewritermc.services.libs.communicator.transfer.PayloadPlan
import com.typewritermc.services.libs.communicator.transfer.TransferBusy
import com.typewritermc.services.libs.communicator.transfer.TransferInterrupted
import com.typewritermc.services.libs.communicator.transfer.TransferRejected
import com.typewritermc.services.libs.communicator.transfer.TransferTooLarge
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transfer.planPayload
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import java.util.Collections
import java.util.concurrent.atomic.AtomicInteger
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.minutes
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * Covers the framing logic of [NatsMessageTransport] and the router over an in memory NATS broker: frame and credit
 * sequences, dropped and altered frames, ceilings, time to live and assembly bounds. NATS semantics the memory broker
 * does not model, max_payload and response permissions, are covered by `PayloadFramingOnNatsTest` in
 * protocol-transport against a real nats-server.
 */
val PayloadFramingTest by testSuite {
    test("a payload within one chunk is one plain message") {
        coroutineScope {
            val broker = MemoryNatsBroker()
            val server = launch { serveReplies(broker.transport(LIMITS), bytes(LIMITS.chunkBytes)) }

            broker.request(bytes(1)) shouldBe bytes(LIMITS.chunkBytes)

            broker
                .replies()
                .single()
                .headers.keys shouldBe emptySet()
            server.cancelAndJoin()
        }
    }

    test("a framed reply larger than one window completes, and every window end waited for its credit") {
        coroutineScope {
            val broker = MemoryNatsBroker()
            val reply = bytes(LIMITS.chunkBytes * 6 + 5)
            val server = launch { serveReplies(broker.transport(LIMITS), reply) }

            broker.request(bytes(1)) shouldBe reply

            val frames = broker.replies().filter { it.header("Typewriter-Payload") != null }
            frames.map { it.header("Typewriter-Chunk") } shouldBe (0 until 7).map { "$it/7" }
            frames.filter { it.replyTo != null }.map { it.header("Typewriter-Chunk") } shouldBe listOf("1/7", "3/7", "5/7")
            broker.published.mapNotNull { it.header("Typewriter-Credit") } shouldBe listOf("4", "6", "7")
            server.cancelAndJoin()
        }
    }

    test("a framed reply on a route without reply credit streams every frame and the requester grants nothing") {
        coroutineScope {
            val broker = MemoryNatsBroker()
            val reply = bytes(LIMITS.chunkBytes * 6 + 5)
            val server = launch { serveReplies(broker.transport(STREAMED), reply) }

            broker.request(bytes(1), STREAMED) shouldBe reply

            val frames = broker.replies().filter { it.header("Typewriter-Payload") != null }
            frames.map { it.header("Typewriter-Chunk") } shouldBe (0 until 7).map { "$it/7" }
            frames.filter { it.replyTo != null } shouldBe emptyList()
            broker.published.mapNotNull { it.header("Typewriter-Credit") } shouldBe emptyList()
            server.cancelAndJoin()
        }
    }

    test("a framed reply past its time to live stops as interrupted on both sides") {
        coroutineScope {
            val broker = MemoryNatsBroker()
            val limits = LIMITS.copy(replyTtl = 1.seconds)
            val results = Collections.synchronizedList(mutableListOf<TransportResult<Unit>>())
            val received = TimeSource.Monotonic.markNow() - 2.seconds
            val server = launch { serveReplies(broker.transport(limits), bytes(LIMITS.chunkBytes * 6 + 5), results, received) }

            shouldThrow<TransferInterrupted> { broker.request(bytes(1)) }

            broker.replies().filter { it.header("Typewriter-Chunk") != null } shouldBe emptyList()
            results.awaitSingle().failureCause().shouldBeInstanceOf<TransferInterrupted>()
            server.cancelAndJoin()
        }
    }

    test("a sender never runs more than one window ahead of a receiver that grants no credit") {
        coroutineScope {
            val broker =
                MemoryNatsBroker(intercept = { message ->
                    if (message.header("Typewriter-Credit") !=
                        null
                    ) {
                        emptyList()
                    } else {
                        listOf(message)
                    }
                })
            val results = Collections.synchronizedList(mutableListOf<TransportResult<Unit>>())
            val server =
                launch {
                    serveReplies(
                        broker.transport(LIMITS.copy(frameInactivity = 200.milliseconds)),
                        bytes(LIMITS.chunkBytes * 6 + 5),
                        results,
                    )
                }

            shouldThrow<TransferInterrupted> { broker.request(bytes(1)) }

            val frames = broker.replies().filter { it.header("Typewriter-Chunk") != null }
            frames.size shouldBe LIMITS.windowFrames
            broker.replies().last().header("Typewriter-Transfer-Failure") shouldBe "interrupted"
            (results.awaitSingle() as TransportResult.Failure).error.shouldBeInstanceOf<TransportError.Timeout>()
            server.cancelAndJoin()
        }
    }

    test("a reply above its ceiling fails as too large on both sides without any frame") {
        coroutineScope {
            val broker = MemoryNatsBroker()
            val results = Collections.synchronizedList(mutableListOf<TransportResult<Unit>>())
            val size = LIMITS.replyMaxBytes.toInt() + 1
            val server = launch { serveReplies(broker.transport(LIMITS), bytes(size), results) }

            val failure = shouldThrow<TransferTooLarge> { broker.request(bytes(1)) }

            failure.size shouldBe size.toLong()
            failure.limit shouldBe LIMITS.replyMaxBytes
            broker.replies().single().header("Typewriter-Transfer-Failure") shouldBe "too-large"
            results.awaitSingle().failureCause().shouldBeInstanceOf<TransferTooLarge>()
            server.cancelAndJoin()
        }
    }

    test("a request above its ceiling fails before any frame is sent") {
        val broker = MemoryNatsBroker()
        val transport = broker.transport(LIMITS)

        val result = transport.request(OutboundMessage(REQUEST, bytes(LIMITS.requestMaxBytes.toInt() + 1)), 5.seconds, LIMITS)

        result.failureCause().shouldBeInstanceOf<TransferTooLarge>().limit shouldBe LIMITS.requestMaxBytes
        broker.published shouldBe emptyList()
    }

    test("requests stay single messages unless the route raises the request ceiling") {
        val broker = MemoryNatsBroker()
        val transport = broker.transport(LIMITS.copy(requestMaxBytes = LIMITS.chunkBytes.toLong()))

        transport
            .request(
                OutboundMessage(REQUEST, bytes(LIMITS.chunkBytes + 1)),
                5.seconds,
            ).failureCause()
            .shouldBeInstanceOf<TransferTooLarge>()
        broker.published shouldBe emptyList()
    }

    test("a framed request completes, its handler runs once, and a framed reply comes back") {
        routerFixture { broker, client ->
            val request = bytes(LIMITS.chunkBytes * 5 + 3, seed = 11)

            client.upload(request) shouldBe request.reversedArray()

            handled.get() shouldBe 1
            val frames = broker.published.filter { it.subject == UPLOAD_SUBJECT }
            frames.map { it.header("Typewriter-Chunk") } shouldBe (0 until 6).map { "$it/6" }
            frames.filter { it.replyTo != null }.map { it.header("Typewriter-Chunk") } shouldBe listOf("1/6", "3/6", "5/6")
        }
    }

    test("a dropped frame fails the transfer instead of decoding a credit") {
        routerFixture(intercept = { message ->
            if (message.subject == UPLOAD_SUBJECT && message.header("Typewriter-Chunk") == "0/6") emptyList() else listOf(message)
        }) { broker, client ->
            client.uploadFailure(bytes(LIMITS.chunkBytes * 5 + 3)).shouldBeInstanceOf<TransferRejected>()

            handled.get() shouldBe 0
            broker.published
                .filter { it.subject == UPLOAD_SUBJECT }
                .last()
                .header("Typewriter-Transfer-Failure") shouldBe "interrupted"
        }
    }

    test("a rejected window end is answered rejected, so the sender fails at once") {
        routerFixture(intercept = { message ->
            if (message.subject == UPLOAD_SUBJECT && message.header("Typewriter-Chunk") == "1/6") {
                listOf(
                    message.copy(
                        headers =
                            message.headers.filterKeys { !it.equals("Typewriter-Size", ignoreCase = true) } +
                                ("Typewriter-Size" to listOf("1")),
                    ),
                )
            } else {
                listOf(message)
            }
        }) { broker, client ->
            val started = TimeSource.Monotonic.markNow()

            client.uploadFailure(bytes(LIMITS.chunkBytes * 5 + 3)).shouldBeInstanceOf<TransferRejected>()

            (started.elapsedNow() < ROUTER_LIMITS.frameInactivity) shouldBe true
            handled.get() shouldBe 0
            broker.published.mapNotNull { it.header("Typewriter-Transfer-Failure") } shouldBe listOf("rejected", "interrupted")
        }
    }

    test("a route whose requests may be framed cannot use a consumer group") {
        val failure =
            shouldThrow<IllegalArgumentException> {
                communicatorRoutes {
                    unary(
                        UPLOAD,
                        consumerGroup =
                            com.typewritermc.services.libs.communicator.transport.ConsumerGroup
                                .of("uploads"),
                    ) { it.request }
                }
            }
        failure.message shouldBe "upload.put frames requests, so it cannot use a consumer group: frames would scatter across members"
    }

    test("frames from several responders on one reply channel never mix") {
        coroutineScope {
            val broker = MemoryNatsBroker()
            val transport = broker.transport(LIMITS)
            val channel = (transport.openReplyChannel() as TransportResult.Success).value
            val first = bytes(LIMITS.chunkBytes * 4 + 1)
            val second = bytes(LIMITS.chunkBytes * 4 + 1, seed = 7)
            val replies = async { channel.deliveries.take(2).toList() }

            listOf(first, second).map { reply ->
                launch { broker.transport(LIMITS).reply(OutboundMessage(channel.address, reply)) }
            }

            replies.await().map {
                (it as TransportDelivery.Message)
                    .message.payload
                    .toByteArray()
                    .toList()
            } shouldContainExactlyInAnyOrder
                listOf(first.toList(), second.toList())
            channel.close()
        }
    }

    test("cancellation closes the reply inbox") {
        coroutineScope {
            val broker = MemoryNatsBroker()
            val transport = broker.transport(LIMITS)
            val request = launch { transport.request(OutboundMessage(REQUEST, byteArrayOf()), 10.seconds) }
            while (broker.activeSubscriptionCount == 0) kotlinx.coroutines.yield()

            request.cancelAndJoin()

            broker.activeSubscriptionCount shouldBe 0
        }
    }

    test("frames out of order and identical duplicates assemble") {
        val plan = LIMITS.planPayload(Payload.copyOf(bytes(LIMITS.chunkBytes * 3 + 5)), LIMITS.replyMaxBytes) as PayloadPlan.Framed
        val assembler = PayloadAssembler(LIMITS, LIMITS.replyMaxBytes)
        val frames = plan.frames.map { InboundMessage(REQUEST, it.payload, headers = it.headers) }

        val results = (listOf(frames.last()) + frames.reversed()).map { assembler.accept(it) }

        results
            .filterIsInstance<Assembly.Complete>()
            .single()
            .message.payload
            .toByteArray() shouldBe bytes(LIMITS.chunkBytes * 3 + 5)
    }

    test("a changed duplicate is rejected") {
        val plan = LIMITS.planPayload(Payload.copyOf(bytes(LIMITS.chunkBytes * 2)), LIMITS.replyMaxBytes) as PayloadPlan.Framed
        val assembler = PayloadAssembler(LIMITS, LIMITS.replyMaxBytes)
        val first = plan.frames.first()
        assembler.accept(InboundMessage(REQUEST, first.payload, headers = first.headers))

        shouldThrow<TransferRejected> {
            assembler.accept(InboundMessage(REQUEST, Payload.copyOf(first.payload.toByteArray().also { it[0]++ }), headers = first.headers))
        }
    }

    test("an abandoned upload is freed by the sweep") {
        val time = TestTimeSource()
        val assembler = PayloadAssembler(LIMITS.copy(frameInactivity = 30.seconds), LIMITS.requestMaxBytes, clock = time)
        val plan = LIMITS.planPayload(Payload.copyOf(bytes(LIMITS.chunkBytes * 6)), LIMITS.requestMaxBytes) as PayloadPlan.Framed
        plan.frames.take(3).forEach { assembler.accept(InboundMessage(REQUEST, it.payload, headers = it.headers)) }

        assembler.sweep()
        assembler.pendingCount() shouldBe 1
        time += 31.seconds
        assembler.sweep()

        assembler.pendingCount() shouldBe 0
    }

    test("a payload beyond the pending byte bound is answered busy at its window end") {
        val assembler = PayloadAssembler(LIMITS, LIMITS.requestMaxBytes, maxPendingBytes = LIMITS.chunkBytes * 5L)
        val first = LIMITS.planPayload(Payload.copyOf(bytes(LIMITS.chunkBytes * 4)), LIMITS.requestMaxBytes) as PayloadPlan.Framed
        val second =
            LIMITS.planPayload(
                Payload.copyOf(bytes(LIMITS.chunkBytes * 4, seed = 3)),
                LIMITS.requestMaxBytes,
            ) as PayloadPlan.Framed
        assembler.accept(InboundMessage(REQUEST, first.frames[0].payload, headers = first.frames[0].headers)) shouldBe Assembly.Waiting

        assembler.accept(InboundMessage(REQUEST, second.frames[0].payload, headers = second.frames[0].headers)) shouldBe Assembly.Waiting
        val answer = assembler.accept(InboundMessage(REQUEST, second.frames[1].payload, REPLY, second.frames[1].headers))

        answer.shouldBeInstanceOf<Assembly.Answer>().headers.first("Typewriter-Transfer-Failure") shouldBe "busy"
        assembler.pendingCount() shouldBe 1
    }

    test("a busy answer reaches the sender as TransferBusy") {
        routerFixture(options = RouterOptions(maxAssemblingBytes = LIMITS.chunkBytes.toLong())) { _, client ->
            client.uploadFailure(bytes(LIMITS.chunkBytes * 5 + 3)).shouldBeInstanceOf<TransferBusy>()
            handled.get() shouldBe 0
        }
    }
}

/** Limits of a route between services, whose framed replies wait for credit. */
private val LIMITS =
    TransportLimits(
        chunkBytes = 64,
        windowFrames = 2,
        requestMaxBytes = 64L * 16,
        replyMaxBytes = 64L * 16,
        frameInactivity = 5.seconds,
        replyTtl = 5.minutes,
        replyCredit = true,
    )

/** Limits of a route a panel role calls, whose framed replies stream without credit. */
private val STREAMED = LIMITS.copy(replyCredit = false)

/** The router fixture's limits: a short inactivity, so a missing answer would show as a slow failure. */
private val ROUTER_LIMITS = LIMITS.copy(frameInactivity = 1.seconds)

private val REQUEST = MessageAddress.of("service.to.quests.organization.writers.realm.editor.catalog.fetch")

private val REPLY = MessageAddress.of("_INBOX.sender.window")

private const val UPLOAD_SUBJECT = "upload.quests.put"

private data class UploadTarget(
    val id: String,
)

private val bytesCodec =
    object : PayloadCodec<ByteArray> {
        override fun encode(value: ByteArray) = Payload.copyOf(value)

        override fun decode(payload: Payload) = payload.toByteArray()
    }

private val UPLOAD =
    UnaryContract(
        OperationName.of("upload.put"),
        "upload.{id}.put".addressTemplate({ addressValuesOf("id" to it.id) }, { UploadTarget(it.require("id")) }),
        bytesCodec,
        bytesCodec,
        ResponsePolicy(byteArrayOf()) {
            if (it.isEmpty()) {
                ResponseClassification(ResponseOutcome.INTERNAL_ERROR, ResponseVariant.of("internal"))
            } else {
                ResponseClassification(ResponseOutcome.SUCCESS, ResponseVariant.of("success"))
            }
        },
        timeout = 5.seconds,
        failureSlug = ErrorSlug.of("upload-put-failed"),
        limits = ROUTER_LIMITS,
    )

private val handled = AtomicInteger()

private class UploadClient(
    private val communicator: Communicator,
) {
    suspend fun upload(request: ByteArray): ByteArray =
        when (val result = communicator.request(UPLOAD, UploadTarget("quests"), request)) {
            is CommunicationResult.Success -> result.value
            is CommunicationResult.Failure -> throw AssertionError("Upload failed with ${result.error}", result.error.cause)
        }

    suspend fun uploadFailure(request: ByteArray): Throwable? =
        when (val result = communicator.request(UPLOAD, UploadTarget("quests"), request)) {
            is CommunicationResult.Success -> throw AssertionError("Upload unexpectedly succeeded")
            is CommunicationResult.Failure -> result.error.cause
        }
}

/** Runs [block] against a router serving [UPLOAD], which answers every request with its bytes reversed. */
private suspend fun routerFixture(
    options: RouterOptions = RouterOptions(),
    intercept: (BrokerMessage) -> List<BrokerMessage> = { listOf(it) },
    block: suspend (MemoryNatsBroker, UploadClient) -> Unit,
) = coroutineScope {
    handled.set(0)
    val broker = MemoryNatsBroker(intercept)
    val harness = TelemetryTestHarness.create()
    val propagators = ContextPropagators.create(W3CTraceContextPropagator.getInstance())
    val serverTransport = broker.transport(ROUTER_LIMITS)
    val routes =
        communicatorRoutes {
            unaryAt(UPLOAD, UploadTarget("quests")) { call ->
                handled.incrementAndGet()
                call.request.reversedArray()
            }
        }
    val router =
        CommunicatorRouter(
            serverTransport,
            routes,
            Communicator(serverTransport, harness.telemetry, propagators),
            harness.telemetry,
            propagators,
            this,
            options,
        )
    try {
        router.start() shouldBe RouterResult.Success
        val clientTransport = broker.transport(ROUTER_LIMITS)
        block(broker, UploadClient(Communicator(clientTransport, harness.telemetry, propagators)))
    } finally {
        router.stop()
        harness.close()
    }
}

/** Answers every request on [REQUEST] with [reply], as if each arrived at [received], and records the reply results. */
private suspend fun serveReplies(
    transport: NatsMessageTransport,
    reply: ByteArray,
    results: MutableList<TransportResult<Unit>> = mutableListOf(),
    received: TimeMark? = null,
) = coroutineScope {
    val subscription = (transport.subscribe(AddressPattern.of(REQUEST.value)) as TransportResult.Success).value
    try {
        subscription.deliveries.collect { delivery ->
            val message = (delivery as? TransportDelivery.Message)?.message ?: return@collect
            launch { results += transport.reply(OutboundMessage(requireNotNull(message.replyTo), reply), received = received) }
        }
    } finally {
        subscription.close()
    }
}

/** Requests from a fresh client and returns the complete reply, throwing its transfer failure. */
private suspend fun MemoryNatsBroker.request(
    payload: ByteArray,
    limits: TransportLimits = LIMITS,
): ByteArray {
    val transport = transport(limits)
    while (activeSubscriptionCount == 0) kotlinx.coroutines.yield()
    return when (val result = transport.request(OutboundMessage(REQUEST, payload), 5.seconds)) {
        is TransportResult.Success -> result.value.payload.toByteArray()
        is TransportResult.Failure -> throw result.error.cause ?: AssertionError("Request failed with ${result.error}")
    }
}

/** Messages published to reply inboxes by the responder, excluding credits the requester sent back. */
private fun MemoryNatsBroker.replies(): List<BrokerMessage> =
    published.filter { it.subject.startsWith("_INBOX.") && it.header("Typewriter-Credit") == null }

private fun bytes(
    size: Int,
    seed: Int = 0,
) = ByteArray(size) { (it * 31 + seed).toByte() }

/** The one result a responder recorded, waiting briefly because it records after its last message went out. */
private suspend fun <Value> List<Value>.awaitSingle(): Value =
    kotlinx.coroutines.withTimeout(5.seconds) {
        while (isEmpty()) kotlinx.coroutines.delay(10.milliseconds)
        single()
    }

private fun TransportResult<*>.failureCause(): Throwable? = ((this as TransportResult.Failure).error as? TransportError.Failure)?.cause
