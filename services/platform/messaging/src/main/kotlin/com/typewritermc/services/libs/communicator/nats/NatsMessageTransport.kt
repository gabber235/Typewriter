package com.typewritermc.services.libs.communicator.nats

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.transfer.REPLY_ASSEMBLY_BUDGET
import com.typewritermc.services.libs.communicator.transfer.ReplyAssembler
import com.typewritermc.services.libs.communicator.transfer.ReplyPlan
import com.typewritermc.services.libs.communicator.transfer.TransferFailure
import com.typewritermc.services.libs.communicator.transfer.TransferTooLarge
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transfer.interruptedReplyHeaders
import com.typewritermc.services.libs.communicator.transfer.planReply
import com.typewritermc.services.libs.communicator.transfer.withFraming
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.communicator.transport.MessagingSystem
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.ReplyChannel
import com.typewritermc.services.libs.communicator.transport.SubscriptionOptions
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.communicator.transport.TransportSubscription
import com.typewritermc.services.libs.utils.rethrowExceptional
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.channels.ChannelResult
import kotlinx.coroutines.channels.ReceiveChannel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.mapNotNull
import kotlinx.coroutines.flow.produceIn
import kotlinx.coroutines.flow.transformWhile
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import java.util.UUID
import kotlin.time.Duration

/**
 * Adapts core NATS messaging through a borrowed connected [NatsConnection].
 *
 * Operations fail when disconnected. Subscription creation waits for activation and flushes before returning so
 * callers can safely issue a subsequent request. Replies above [TransportLimits.chunkBytes] travel as frames on the
 * requester's reply address: [reply] splits them and [request] and reply channels reassemble them, so communicators
 * only ever see complete replies. No persistence or application delivery acknowledgment is added.
 */
class NatsMessageTransport(
    private val connection: NatsConnection,
    private val limits: TransportLimits,
) : MessageTransport {
    override val system: MessagingSystem = MessagingSystem.of("nats")

    /** Opens a temporary subscription at a transport owned inbox whose deliveries are assembled replies. */
    override suspend fun openReplyChannel(): TransportResult<ReplyChannel> =
        when (val inbox = openInbox()) {
            is TransportResult.Failure -> inbox
            is TransportResult.Success -> TransportResult.Success(NatsReplyChannel(inbox.value, limits))
        }

    /** Publishes [message] when the connection is currently usable. */
    override suspend fun publish(message: OutboundMessage): TransportResult<Unit> {
        val client = connection.connectedClient() ?: return disconnectedFailure()
        return transportCall { client.publish(message.toNatsMessage()) }
    }

    /**
     * Publishes a reply as one plain message, or as frames when it exceeds [TransportLimits.chunkBytes].
     *
     * A reply above [TransportLimits.maxEncodedSize] sends one too large failure frame and fails with
     * [TransferTooLarge]. A frame that cannot be published is followed by an interrupted frame, so the requester
     * fails at once instead of waiting for its assembly budget, and the publish failure is returned.
     */
    override suspend fun reply(message: OutboundMessage): TransportResult<Unit> =
        when (val plan = limits.planReply(message.payload)) {
            ReplyPlan.Single -> {
                publish(message)
            }

            is ReplyPlan.TooLarge -> {
                when (val published = publish(message.framed(Payload.Empty, plan.headers))) {
                    is TransportResult.Failure -> published
                    is TransportResult.Success -> TransportResult.Failure(TransportError.Failure(TransferTooLarge(plan.size, plan.limit)))
                }
            }

            is ReplyPlan.Framed -> {
                publishFrames(message, plan)
            }
        }

    private suspend fun publishFrames(
        message: OutboundMessage,
        plan: ReplyPlan.Framed,
    ): TransportResult<Unit> {
        for (frame in plan.frames) {
            val published = publish(message.framed(frame.payload, frame.headers))
            if (published is TransportResult.Failure) {
                publish(message.framed(Payload.Empty, interruptedReplyHeaders(plan.replyId)))
                return published
            }
        }
        return TransportResult.Success(Unit)
    }

    /**
     * Requests through a fresh transport owned inbox; caller-provided reply subjects are rejected.
     *
     * The first reply message must arrive within [timeout] and the remaining frames of a framed reply within the
     * thirty second assembly budget after it. Timeouts, no responders and framing failures are result values; the
     * inbox and every retained frame are released on every exit, including cancellation.
     */
    override suspend fun request(
        message: OutboundMessage,
        timeout: Duration,
    ): TransportResult<InboundMessage> {
        require(message.replyTo == null) { "NATS requests cannot specify replyTo" }
        timeout.toPositiveMilliseconds("Request timeout")
        val inbox =
            when (val opened = openInbox()) {
                is TransportResult.Failure -> return opened
                is TransportResult.Success -> opened.value
            }
        try {
            val published = publish(message.copy(replyTo = inbox.address))
            if (published is TransportResult.Failure) return published
            return awaitReply(inbox.subscription.deliveries, timeout)
        } finally {
            withContext(NonCancellable) { inbox.subscription.close() }
        }
    }

    private suspend fun awaitReply(
        deliveries: Flow<TransportDelivery>,
        timeout: Duration,
    ): TransportResult<InboundMessage> =
        coroutineScope {
            val frames = deliveries.produceIn(this)
            try {
                val assembler = ReplyAssembler(limits)
                val first = withTimeoutOrNull(timeout) { frames.receiveCatching() } ?: return@coroutineScope replyTimeout()
                withTimeoutOrNull(REPLY_ASSEMBLY_BUDGET) { frames.assemble(first, assembler) } ?: replyTimeout()
            } finally {
                frames.cancel()
            }
        }

    private suspend fun ReceiveChannel<TransportDelivery>.assemble(
        first: ChannelResult<TransportDelivery>,
        assembler: ReplyAssembler,
    ): TransportResult<InboundMessage> {
        var received = first
        while (true) {
            when (val delivery = received.getOrNull() ?: TransportDelivery.Completed) {
                is TransportDelivery.Message -> {
                    val reply =
                        try {
                            assembler.accept(delivery.message)
                        } catch (failure: TransferFailure) {
                            return TransportResult.Failure(TransportError.Failure(failure))
                        }
                    if (reply != null) return TransportResult.Success(reply)
                }

                is TransportDelivery.Failure -> {
                    return TransportResult.Failure(delivery.error)
                }

                TransportDelivery.Completed -> {
                    return TransportResult.Failure(TransportError.Unavailable(IllegalStateException("NATS reply inbox closed")))
                }
            }
            received = receiveCatching()
        }
    }

    private suspend fun openInbox(): TransportResult<NatsInbox> {
        val prefix = connection.connectedInboxPrefix() ?: return disconnectedFailure()
        val address = MessageAddress.of(prefix + UUID.randomUUID().toString().replace("-", ""))
        return when (val result = subscribe(AddressPattern.of(address.value))) {
            is TransportResult.Failure -> result
            is TransportResult.Success -> TransportResult.Success(NatsInbox(address, result.value))
        }
    }

    /**
     * Creates and activates a NATS subscription for [pattern].
     *
     * The adapter flushes before returning, so a caller can issue a request immediately after subscription. A
     * failure during activation rolls the native subscription back.
     */
    override suspend fun subscribe(
        pattern: AddressPattern,
        options: SubscriptionOptions,
    ): TransportResult<TransportSubscription> {
        val client = connection.connectedClient() ?: return disconnectedFailure()
        val subscription =
            try {
                client.subscribe(pattern.value, options.consumerGroup?.value)
            } catch (failure: Throwable) {
                failure.rethrowExceptional()
                return TransportResult.Failure(TransportError.Failure(failure))
            }
        return try {
            subscription.isActive.first { it }
            client.flush()
            TransportResult.Success(NatsTransportSubscription(subscription))
        } catch (failure: Throwable) {
            try {
                withContext(NonCancellable) { subscription.unsubscribe() }
            } catch (cleanup: Throwable) {
                throw combineFailures(failure, cleanup)
            }
            failure.rethrowExceptional()
            TransportResult.Failure(TransportError.Failure(failure))
        }
    }
}

/** A transport owned reply address with the subscription that receives its messages. */
private class NatsInbox(
    val address: MessageAddress,
    val subscription: TransportSubscription,
)

/**
 * A reply channel whose deliveries are complete replies. Each collection assembles frames by reply id; a framing
 * failure is delivered as a terminal [TransportDelivery.Failure] whose cause is the [TransferFailure].
 */
private class NatsReplyChannel(
    private val inbox: NatsInbox,
    private val limits: TransportLimits,
) : ReplyChannel {
    override val address: MessageAddress get() = inbox.address

    override val deliveries: Flow<TransportDelivery> =
        flow {
            val assembler = ReplyAssembler(limits)
            inbox.subscription.deliveries
                .mapNotNull { delivery -> delivery.assembledBy(assembler) }
                .transformWhile { delivery ->
                    emit(delivery)
                    delivery !is TransportDelivery.Failure
                }.collect { emit(it) }
        }

    override suspend fun close() = inbox.subscription.close()
}

private fun TransportDelivery.assembledBy(assembler: ReplyAssembler): TransportDelivery? =
    when (this) {
        is TransportDelivery.Message -> {
            try {
                assembler.accept(message)?.let(TransportDelivery::Message)
            } catch (failure: TransferFailure) {
                TransportDelivery.Failure(TransportError.Failure(failure))
            }
        }

        else -> {
            this
        }
    }

private fun OutboundMessage.framed(
    payload: Payload,
    framing: MessageHeaders,
) = copy(payload = payload, headers = headers.withFraming(framing))

private fun replyTimeout(): TransportResult<InboundMessage> = TransportResult.Failure(TransportError.Timeout())

private class NatsTransportSubscription(
    private val subscription: NatsClientSubscription,
) : TransportSubscription {
    private val closeMutex = Mutex()
    private var closed = false

    override val deliveries: Flow<TransportDelivery> =
        flow {
            var terminalFailure = false
            subscription.messages
                .map { message ->
                    message.statusError()?.let(TransportDelivery::Failure)
                        ?: TransportDelivery.Message(message.toInboundMessage())
                }.catch { failure ->
                    failure.rethrowExceptional()
                    emit(TransportDelivery.Failure(TransportError.Failure(failure)))
                }.transformWhile { delivery ->
                    emit(delivery)
                    terminalFailure = (delivery is TransportDelivery.Failure)
                    !terminalFailure
                }.collect { emit(it) }
            if (!terminalFailure) emit(TransportDelivery.Completed)
        }

    override suspend fun close() =
        closeMutex.withLock {
            if (closed) return@withLock
            subscription.unsubscribe()
            closed = true
        }
}

private fun OutboundMessage.toNatsMessage() =
    NatsClientMessage(
        subject = address.value,
        payload = payload,
        headers = headers.associate { it },
        replyTo = replyTo?.value,
        status = null,
        statusDescription = null,
    )

private fun NatsClientMessage.toInboundMessage() =
    InboundMessage(
        address = MessageAddress.of(subject),
        payload = payload ?: Payload.Empty,
        replyTo = replyTo?.let(MessageAddress::of),
        headers =
            headers.orEmpty().entries.fold(MessageHeaders.Empty) { result, (name, values) ->
                values.fold(result) { headers, value -> headers.plus(name, value) }
            },
    )

private fun NatsClientMessage.statusError(): TransportError? =
    when {
        status == 503 -> TransportError.NoResponders(NatsStatusException(status, statusDescription))
        status != null && status >= 300 -> TransportError.Failure(NatsStatusException(status, statusDescription))
        else -> null
    }

private class NatsStatusException(
    status: Int,
    description: String?,
) : RuntimeException("NATS status $status${description?.let { ": $it" }.orEmpty()}")

private suspend fun <Value> transportCall(block: suspend () -> Value): TransportResult<Value> =
    try {
        TransportResult.Success(block())
    } catch (failure: Throwable) {
        failure.rethrowExceptional()
        TransportResult.Failure(TransportError.Failure(failure))
    }

private fun <Value> disconnectedFailure(): TransportResult<Value> =
    TransportResult.Failure(TransportError.Unavailable(IllegalStateException("NATS connection is not connected")))
