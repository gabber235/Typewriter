package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsClientAdapter
import com.typewritermc.services.libs.communicator.nats.NatsClientConnectivity
import com.typewritermc.services.libs.communicator.nats.NatsClientMessage
import com.typewritermc.services.libs.communicator.nats.NatsClientSubscription
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration
import com.typewritermc.services.libs.communicator.nats.NatsMessageTransport
import com.typewritermc.services.libs.communicator.transfer.ReplyPlan
import com.typewritermc.services.libs.communicator.transfer.TransferInterrupted
import com.typewritermc.services.libs.communicator.transfer.TransferRejected
import com.typewritermc.services.libs.communicator.transfer.TransferTooLarge
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transfer.planReply
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.collections.shouldContainExactlyInAnyOrder
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeInstanceOf
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.take
import kotlinx.coroutines.flow.toList
import kotlinx.coroutines.launch
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds

/** Covers the reply framing of [NatsMessageTransport] end to end over an in memory broker. */
val ChunkedReplyTest by testSuite {
    test("a reply within one chunk is one plain message") {
        val broker = LoopbackBroker()
        broker.roundTrip(bytes(LIMITS.chunkBytes)) shouldBe bytes(LIMITS.chunkBytes)
        broker.published
            .single()
            .headers
            .orEmpty()
            .keys shouldBe emptySet()
    }

    test("frames out of order and identical duplicates assemble") {
        val broker = LoopbackBroker(deliver = { frames -> listOf(frames.last()) + frames.reversed() })
        val response = bytes(LIMITS.chunkBytes * 3 + 5)

        broker.roundTrip(response) shouldBe response
        broker.published.map { it.headers?.get("Typewriter-Chunk")?.single() } shouldBe listOf("0/4", "1/4", "2/4", "3/4")
        broker.published
            .map { it.headers?.get("Typewriter-Reply") }
            .toSet()
            .size shouldBe 1
    }

    test("a changed duplicate is rejected") {
        val broker = LoopbackBroker(deliver = { frames -> listOf(frames.first(), frames.first().tampered()) + frames.drop(1) })

        shouldThrow<TransferRejected> { broker.roundTrip(bytes(LIMITS.chunkBytes * 2)) }
    }

    test("a frame that breaks the bounds is rejected before assembly") {
        val broker =
            LoopbackBroker(deliver = { frames ->
                frames.map { it.copy(headers = it.headers.orEmpty() + ("Typewriter-Chunk" to listOf("0/${LIMITS.maxChunks + 1}"))) }
            })

        shouldThrow<TransferRejected> { broker.roundTrip(bytes(LIMITS.chunkBytes * 2)) }
    }

    test("an oversize reply fails as TransferTooLarge before any chunk is allocated") {
        val broker = LoopbackBroker()
        val size = LIMITS.maxEncodedSize.toInt() + 1

        val failure = shouldThrow<TransferTooLarge> { broker.roundTrip(bytes(size)) }

        failure.size shouldBe size.toLong()
        failure.limit shouldBe LIMITS.maxEncodedSize
        val frame = broker.published.single()
        (frame.payload?.size ?: 0) shouldBe 0
        frame.headers?.get("Typewriter-Transfer-Failure") shouldBe listOf("too-large")
        broker.replyResults
            .single()
            .failureCause()
            .shouldBeInstanceOf<TransferTooLarge>()
        LIMITS.planReply(Payload.copyOf(bytes(size))).shouldBeInstanceOf<ReplyPlan.TooLarge>()
    }

    test("a publish failure part way ends the requester with TransferInterrupted") {
        val broker = LoopbackBroker(failPublishAt = 2)

        shouldThrow<TransferInterrupted> { broker.roundTrip(bytes(LIMITS.chunkBytes * 3)) }

        broker.published.map { it.headers?.get("Typewriter-Transfer-Failure") } shouldBe listOf(null, listOf("interrupted"))
        broker.replyResults
            .single()
            .failureCause()
            .shouldBeInstanceOf<IllegalStateException>()
    }

    test("frames from several responders on one reply channel never mix") {
        val broker = LoopbackBroker()
        val transport = broker.transport()
        val channel = (transport.openReplyChannel() as TransportResult.Success).value
        val first = bytes(LIMITS.chunkBytes * 2 + 1)
        val second = bytes(LIMITS.chunkBytes * 2 + 1, seed = 7)
        transport.reply(OutboundMessage(channel.address, first))
        transport.reply(OutboundMessage(channel.address, second))
        val frames = broker.takePublished()
        broker.deliver(
            channel.address.value,
            frames.filterIndexed { index, _ -> index % 2 == 0 } + frames.filterIndexed { index, _ -> index % 2 == 1 },
        )

        val replies =
            channel.deliveries
                .take(2)
                .toList()
                .map { (it as TransportDelivery.Message).message.payload.toByteArray() }

        replies.map(ByteArray::toList) shouldContainExactlyInAnyOrder listOf(first.toList(), second.toList())
        channel.close()
    }

    test("one responder's framing failure does not end a reply channel") {
        val broker = LoopbackBroker()
        val transport = broker.transport()
        val channel = (transport.openReplyChannel() as TransportResult.Success).value
        transport.reply(OutboundMessage(channel.address, bytes(LIMITS.maxEncodedSize.toInt() + 1)))
        transport.reply(OutboundMessage(channel.address, bytes(LIMITS.chunkBytes * 2 + 1, seed = 3)))
        val (tooLargeFrame, partialFrame) = broker.takePublished()
        val framed = bytes(LIMITS.chunkBytes * 2 + 1, seed = 7)
        transport.reply(OutboundMessage(channel.address, framed))
        broker.deliver(channel.address.value, listOf(tooLargeFrame, partialFrame, partialFrame.interrupted()) + broker.takePublished())

        val deliveries = channel.deliveries.take(3).toList()

        deliveries[0].failureCause().shouldBeInstanceOf<TransferTooLarge>()
        deliveries[1].failureCause().shouldBeInstanceOf<TransferInterrupted>()
        (deliveries[2] as TransportDelivery.Message)
            .message.payload
            .toByteArray()
            .toList() shouldBe framed.toList()
        channel.close()
    }

    test("cancellation closes the reply inbox") {
        coroutineScope {
            val broker = LoopbackBroker(respond = false)
            val transport = broker.transport()
            val request = launch { transport.request(OutboundMessage(REQUEST, byteArrayOf()), 10.seconds) }
            val inbox = broker.subscribed.await()

            request.cancelAndJoin()

            broker.unsubscribed shouldContainExactly listOf(inbox)
        }
    }
}

private val LIMITS = TransportLimits(chunkBytes = 64, maxChunks = 4)

private val REQUEST = MessageAddress.of("service.to.quests.organization.writers.realm.editor.catalog.fetch")

private fun bytes(
    size: Int,
    seed: Int = 0,
) = ByteArray(size) { (it * 31 + seed).toByte() }

private fun NatsClientMessage.tampered() = copy(payload = Payload.copyOf(payload!!.toByteArray().also { it[0] = (it[0] + 1).toByte() }))

private fun NatsClientMessage.interrupted() =
    copy(
        payload = Payload.Empty,
        headers =
            mapOf(
                "Typewriter-Reply" to headers!!.getValue("Typewriter-Reply"),
                "Typewriter-Transfer-Failure" to listOf("interrupted"),
            ),
    )

private fun TransportDelivery.failureCause(): Throwable? = ((this as TransportDelivery.Failure).error as TransportError.Failure).cause

private fun TransportResult<Unit>.failureCause(): Throwable? = ((this as TransportResult.Failure).error as TransportError.Failure).cause

/**
 * One client connection that answers requests on [REQUEST] by replying through the same transport. Reply frames
 * are recorded, rearranged by [deliver] and then delivered to the requester inbox. [failPublishAt] makes the
 * broker reject the reply message with that one based position.
 */
private class LoopbackBroker(
    private val deliver: (List<NatsClientMessage>) -> List<NatsClientMessage> = { it },
    private val failPublishAt: Int? = null,
    private val respond: Boolean = true,
) : NatsClientAdapter {
    override val connectivity = MutableStateFlow(NatsClientConnectivity.Connected)
    private val inboxes = mutableMapOf<String, Channel<NatsClientMessage>>()
    private val history = mutableListOf<NatsClientMessage>()
    private val undelivered = mutableListOf<NatsClientMessage>()
    private var replyPublishes = 0
    private var response: ByteArray = byteArrayOf()
    private lateinit var responder: NatsMessageTransport

    /** Every reply message published so far, in publish order. */
    val published: List<NatsClientMessage> get() = history.toList()

    /** The results the responding transport returned for its replies. */
    val replyResults = mutableListOf<TransportResult<Unit>>()

    val subscribed = CompletableDeferred<String>()
    val unsubscribed = mutableListOf<String>()

    suspend fun transport(): NatsMessageTransport {
        val connection = NatsConnection({ NatsConnectionConfiguration("nats://localhost") }, { NatsAuthentication() }, { _, _ -> this })
        connection.connect()
        return NatsMessageTransport(connection, LIMITS).also { responder = it }
    }

    /** Requests [reply] through one transport and returns the assembled bytes, throwing the transfer failure. */
    suspend fun roundTrip(reply: ByteArray): ByteArray {
        response = reply
        return when (val result = transport().request(OutboundMessage(REQUEST, byteArrayOf()), 5.seconds)) {
            is TransportResult.Success -> result.value.payload.toByteArray()
            is TransportResult.Failure -> throw result.error.cause ?: AssertionError("Request failed with ${result.error}")
        }
    }

    /** Reply messages published since the previous call, which the broker has not delivered yet. */
    fun takePublished(): List<NatsClientMessage> = undelivered.toList().also { undelivered.clear() }

    fun deliver(
        inbox: String,
        messages: List<NatsClientMessage>,
    ) = messages.forEach { inboxes.getValue(inbox).trySend(it.copy(subject = inbox)) }

    override suspend fun connect(): Result<Unit> = Result.success(Unit)

    override suspend fun disconnect() = Unit

    override suspend fun drain(timeout: Duration) = Unit

    override suspend fun flush() = Unit

    override suspend fun publish(message: NatsClientMessage) {
        if (message.subject == REQUEST.value) {
            if (!respond) return
            val inbox = requireNotNull(message.replyTo)
            replyResults += responder.reply(OutboundMessage(MessageAddress.of(inbox), response))
            deliver(inbox, deliver(takePublished()))
            return
        }
        replyPublishes++
        check(replyPublishes != failPublishAt) { "Broker rejected the reply frame" }
        history += message
        undelivered += message
    }

    override suspend fun subscribe(
        subject: String,
        queueGroup: String?,
    ): NatsClientSubscription {
        val channel = Channel<NatsClientMessage>(Channel.UNLIMITED)
        inboxes[subject] = channel
        subscribed.complete(subject)
        return object : NatsClientSubscription {
            override val messages: Flow<NatsClientMessage> = channel.receiveAsFlow()
            override val isActive: StateFlow<Boolean> = MutableStateFlow(true)

            override suspend fun unsubscribe() {
                unsubscribed += subject
                channel.close()
            }
        }
    }
}
