package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.router.RouterOptions
import com.typewritermc.services.libs.communicator.router.communicatorRoutes
import com.typewritermc.services.libs.communicator.testing.MemoryNatsBroker
import com.typewritermc.services.libs.communicator.testing.UPLOAD
import com.typewritermc.services.libs.communicator.testing.awaitSingle
import com.typewritermc.services.libs.communicator.testing.bytes
import com.typewritermc.services.libs.communicator.testing.failureCause
import com.typewritermc.services.libs.communicator.testing.framedLimits
import com.typewritermc.services.libs.communicator.testing.framedReply
import com.typewritermc.services.libs.communicator.testing.framedRequest
import com.typewritermc.services.libs.communicator.testing.replies
import com.typewritermc.services.libs.communicator.testing.request
import com.typewritermc.services.libs.communicator.testing.serveReplies
import com.typewritermc.services.libs.communicator.testing.uploadHandled
import com.typewritermc.services.libs.communicator.testing.windowEndOfUpload
import com.typewritermc.services.libs.communicator.testing.withUploadRouter
import com.typewritermc.services.libs.communicator.transfer.Assembly
import com.typewritermc.services.libs.communicator.transfer.PayloadAssembler
import com.typewritermc.services.libs.communicator.transfer.PayloadPlan
import com.typewritermc.services.libs.communicator.transfer.TransferBusy
import com.typewritermc.services.libs.communicator.transfer.TransferInterrupted
import com.typewritermc.services.libs.communicator.transfer.TransferRejected
import com.typewritermc.services.libs.communicator.transfer.TransferTooLarge
import com.typewritermc.services.libs.communicator.transfer.planPayload
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import java.util.Collections
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.TestTimeSource
import kotlin.time.TimeSource

/**
 * Covers the framing logic of [NatsMessageTransport] and the router over an in memory NATS broker: frame and credit
 * sequences, dropped and altered frames, ceilings, time to live and assembly bounds. NATS semantics the memory broker
 * does not model, max_payload and response permissions, are covered by `PayloadFramingOnNatsTest` in
 * protocol-transport against a real nats-server.
 */
val PayloadFramingTest by testSuite {
    /** Limits of a route a panel role calls, whose framed replies stream without credit. */
    val streamed = framedLimits.copy(replyCredit = false)

    test("a payload within one chunk is one plain message") {
        coroutineScope {
            val broker = MemoryNatsBroker()
            val server = launch { serveReplies(broker.transport(framedLimits), bytes(framedLimits.chunkBytes)) }

            broker.request(bytes(1)) shouldBe bytes(framedLimits.chunkBytes)

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
            val reply = bytes(framedLimits.chunkBytes * 6 + 5)
            val server = launch { serveReplies(broker.transport(framedLimits), reply) }

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
            val reply = bytes(framedLimits.chunkBytes * 6 + 5)
            val server = launch { serveReplies(broker.transport(streamed), reply) }

            broker.request(bytes(1), streamed) shouldBe reply

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
            val limits = framedLimits.copy(replyTtl = 1.seconds)
            val results = Collections.synchronizedList(mutableListOf<TransportResult<Unit>>())
            val received = TimeSource.Monotonic.markNow() - 2.seconds
            val server = launch { serveReplies(broker.transport(limits), bytes(framedLimits.chunkBytes * 6 + 5), results, received) }

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
                        broker.transport(framedLimits.copy(frameInactivity = 200.milliseconds)),
                        bytes(framedLimits.chunkBytes * 6 + 5),
                        results,
                    )
                }

            shouldThrow<TransferInterrupted> { broker.request(bytes(1)) }

            val frames = broker.replies().filter { it.header("Typewriter-Chunk") != null }
            frames.size shouldBe framedLimits.windowFrames
            broker.replies().last().header("Typewriter-Transfer-Failure") shouldBe "interrupted"
            (results.awaitSingle() as TransportResult.Failure).error.shouldBeInstanceOf<TransportError.Timeout>()
            server.cancelAndJoin()
        }
    }

    test("a reply above its ceiling fails as too large on both sides without any frame") {
        coroutineScope {
            val broker = MemoryNatsBroker()
            val results = Collections.synchronizedList(mutableListOf<TransportResult<Unit>>())
            val size = framedLimits.replyMaxBytes.toInt() + 1
            val server = launch { serveReplies(broker.transport(framedLimits), bytes(size), results) }

            val failure = shouldThrow<TransferTooLarge> { broker.request(bytes(1)) }

            failure.size shouldBe size.toLong()
            failure.limit shouldBe framedLimits.replyMaxBytes
            broker.replies().single().header("Typewriter-Transfer-Failure") shouldBe "too-large"
            results.awaitSingle().failureCause().shouldBeInstanceOf<TransferTooLarge>()
            server.cancelAndJoin()
        }
    }

    test("a request above its ceiling fails before any frame is sent") {
        val broker = MemoryNatsBroker()
        val transport = broker.transport(framedLimits)

        val result =
            transport.request(
                OutboundMessage(framedRequest, bytes(framedLimits.requestMaxBytes.toInt() + 1)),
                5.seconds,
                framedLimits,
            )

        result.failureCause().shouldBeInstanceOf<TransferTooLarge>().limit shouldBe framedLimits.requestMaxBytes
        broker.published shouldBe emptyList()
    }

    test("requests stay single messages unless the route raises the request ceiling") {
        val broker = MemoryNatsBroker()
        val transport = broker.transport(framedLimits.copy(requestMaxBytes = framedLimits.chunkBytes.toLong()))

        transport
            .request(
                OutboundMessage(framedRequest, bytes(framedLimits.chunkBytes + 1)),
                5.seconds,
            ).failureCause()
            .shouldBeInstanceOf<TransferTooLarge>()
        broker.published shouldBe emptyList()
    }

    test("a framed request completes, its handler runs once, and a framed reply comes back") {
        withUploadRouter { broker, client ->
            val request = bytes(framedLimits.chunkBytes * 5 + 3, seed = 11)

            client.upload(request) shouldBe request.reversedArray()

            uploadHandled.get() shouldBe 1
            val frames = broker.published.filter { it.subject == UPLOAD_SUBJECT }
            frames.map { it.header("Typewriter-Chunk") } shouldBe (0 until 6).map { "$it/6" }
            frames.filter { it.replyTo != null }.map { it.header("Typewriter-Chunk") } shouldBe listOf("1/6", "3/6", "5/6")
        }
    }

    test("a dropped frame fails the transfer instead of decoding a credit") {
        withUploadRouter(intercept = { message ->
            if (message.subject == UPLOAD_SUBJECT && message.header("Typewriter-Chunk") == "0/6") emptyList() else listOf(message)
        }) { broker, client ->
            client.uploadFailure(bytes(framedLimits.chunkBytes * 5 + 3)).shouldBeInstanceOf<TransferRejected>()

            uploadHandled.get() shouldBe 0
            broker.published
                .filter { it.subject == UPLOAD_SUBJECT }
                .last()
                .header("Typewriter-Transfer-Failure") shouldBe "interrupted"
        }
    }

    test("a rejected window end is answered rejected, so the sender fails at once") {
        withUploadRouter(intercept = { message ->
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
            // A sender left waiting would fail with a timeout after the frame inactivity instead of this rejection.
            client.uploadFailure(bytes(framedLimits.chunkBytes * 5 + 3)).shouldBeInstanceOf<TransferRejected>().message shouldBe
                "The receiver rejected a frame of the payload"

            uploadHandled.get() shouldBe 0
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
            val transport = broker.transport(framedLimits)
            val channel = (transport.openReplyChannel() as TransportResult.Success).value
            val first = bytes(framedLimits.chunkBytes * 4 + 1)
            val second = bytes(framedLimits.chunkBytes * 4 + 1, seed = 7)
            val replies = async { channel.deliveries.take(2).toList() }

            listOf(first, second).map { reply ->
                launch { broker.transport(framedLimits).reply(OutboundMessage(channel.address, reply)) }
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
            val transport = broker.transport(framedLimits)
            val request = launch { transport.request(OutboundMessage(framedRequest, byteArrayOf()), 10.seconds) }
            while (broker.activeSubscriptionCount == 0) kotlinx.coroutines.yield()

            request.cancelAndJoin()

            broker.activeSubscriptionCount shouldBe 0
        }
    }

    test("frames out of order and identical duplicates assemble") {
        val plan =
            framedLimits.planPayload(
                Payload.copyOf(bytes(framedLimits.chunkBytes * 3 + 5)),
                framedLimits.replyMaxBytes,
            ) as PayloadPlan.Framed
        val assembler = PayloadAssembler(framedLimits, framedLimits.replyMaxBytes)
        val frames = plan.frames.map { InboundMessage(framedRequest, it.payload, headers = it.headers) }

        val results = (listOf(frames.last()) + frames.reversed()).map { assembler.accept(it) }

        results
            .filterIsInstance<Assembly.Complete>()
            .single()
            .message.payload
            .toByteArray() shouldBe bytes(framedLimits.chunkBytes * 3 + 5)
    }

    test("a changed duplicate is rejected") {
        val plan =
            framedLimits.planPayload(
                Payload.copyOf(bytes(framedLimits.chunkBytes * 2)),
                framedLimits.replyMaxBytes,
            ) as PayloadPlan.Framed
        val assembler = PayloadAssembler(framedLimits, framedLimits.replyMaxBytes)
        val first = plan.frames.first()
        assembler.accept(InboundMessage(framedRequest, first.payload, headers = first.headers))

        shouldThrow<TransferRejected> {
            assembler.accept(
                InboundMessage(framedRequest, Payload.copyOf(first.payload.toByteArray().also { it[0]++ }), headers = first.headers),
            )
        }
    }

    test("an abandoned upload is freed by the sweep, so its bytes take a new upload") {
        val time = TestTimeSource()
        val assembler =
            PayloadAssembler(
                framedLimits.copy(frameInactivity = 30.seconds),
                framedLimits.requestMaxBytes,
                maxPendingBytes = framedLimits.chunkBytes * 5L,
                clock = time,
            )
        val abandoned =
            framedLimits.planPayload(
                Payload.copyOf(bytes(framedLimits.chunkBytes * 4)),
                framedLimits.requestMaxBytes,
            ) as PayloadPlan.Framed
        assembler.accept(InboundMessage(framedRequest, abandoned.frames[0].payload, headers = abandoned.frames[0].headers))

        assembler.sweep()
        assembler
            .windowEndOfUpload(seed = 3)
            .shouldBeInstanceOf<Assembly.Answer>()
            .headers
            .first("Typewriter-Transfer-Failure") shouldBe
            "busy"
        time += 31.seconds
        assembler.sweep()

        assembler
            .windowEndOfUpload(seed = 5)
            .shouldBeInstanceOf<Assembly.Answer>()
            .headers
            .first("Typewriter-Transfer-Failure") shouldBe
            null
    }

    test("a payload beyond the pending byte bound is answered busy at its window end") {
        val assembler = PayloadAssembler(framedLimits, framedLimits.requestMaxBytes, maxPendingBytes = framedLimits.chunkBytes * 5L)
        val first =
            framedLimits.planPayload(
                Payload.copyOf(bytes(framedLimits.chunkBytes * 4)),
                framedLimits.requestMaxBytes,
            ) as PayloadPlan.Framed
        val second =
            framedLimits.planPayload(
                Payload.copyOf(bytes(framedLimits.chunkBytes * 4, seed = 3)),
                framedLimits.requestMaxBytes,
            ) as PayloadPlan.Framed
        assembler.accept(InboundMessage(framedRequest, first.frames[0].payload, headers = first.frames[0].headers)) shouldBe
            Assembly.Waiting

        assembler.accept(InboundMessage(framedRequest, second.frames[0].payload, headers = second.frames[0].headers)) shouldBe
            Assembly.Waiting
        val answer = assembler.accept(InboundMessage(framedRequest, second.frames[1].payload, framedReply, second.frames[1].headers))

        answer.shouldBeInstanceOf<Assembly.Answer>().headers.first("Typewriter-Transfer-Failure") shouldBe "busy"
        assembler.pendingCount() shouldBe 1
    }

    test("a busy answer reaches the sender as TransferBusy") {
        withUploadRouter(options = RouterOptions(maxAssemblingBytes = framedLimits.chunkBytes.toLong())) { _, client ->
            client.uploadFailure(bytes(framedLimits.chunkBytes * 5 + 3)).shouldBeInstanceOf<TransferBusy>()
            uploadHandled.get() shouldBe 0
        }
    }
}

private const val UPLOAD_SUBJECT = "upload.quests.put"
