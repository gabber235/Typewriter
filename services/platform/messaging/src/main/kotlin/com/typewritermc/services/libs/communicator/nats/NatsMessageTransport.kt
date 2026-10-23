package com.typewritermc.services.libs.communicator.nats

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.transfer.Assembly
import com.typewritermc.services.libs.communicator.transfer.FRAME_INACTIVITY
import com.typewritermc.services.libs.communicator.transfer.FrameChannel
import com.typewritermc.services.libs.communicator.transfer.PayloadAssembler
import com.typewritermc.services.libs.communicator.transfer.PayloadFrame
import com.typewritermc.services.libs.communicator.transfer.PayloadHeaders
import com.typewritermc.services.libs.communicator.transfer.PayloadPlan
import com.typewritermc.services.libs.communicator.transfer.TransferFailure
import com.typewritermc.services.libs.communicator.transfer.TransferRejected
import com.typewritermc.services.libs.communicator.transfer.TransferTooLarge
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transfer.interruptedHeaders
import com.typewritermc.services.libs.communicator.transfer.planPayload
import com.typewritermc.services.libs.communicator.transfer.sendInWindows
import com.typewritermc.services.libs.communicator.transfer.transferFailure
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
 * callers can safely issue a subsequent request. Payloads above [TransportLimits.chunkBytes] travel as frames in
 * credit windows: [reply] splits large replies on the requester's reply address, [request] splits large requests on
 * the route address when the route allows it, and both sides answer each window end with the next grant, so
 * communicators only ever see complete payloads. [limits] are the manifest defaults; a call may pass its route's.
 * [inactivity] bounds how long a sender waits for a credit and a requester for the next frame.
 * No persistence or application delivery acknowledgment is added.
 */
class NatsMessageTransport(
    private val connection: NatsConnection,
    private val limits: TransportLimits,
    private val inactivity: Duration = FRAME_INACTIVITY,
) : MessageTransport {
    override val system: MessagingSystem = MessagingSystem.of("nats")

    /** Opens a temporary subscription at a transport owned inbox whose deliveries are assembled replies. */
    override suspend fun openReplyChannel(): TransportResult<ReplyChannel> =
        when (val inbox = openInbox()) {
            is TransportResult.Failure -> inbox
            is TransportResult.Success -> TransportResult.Success(NatsReplyChannel(inbox.value, limits, inactivity, ::publish))
        }

    /** Publishes [message] when the connection is currently usable. */
    override suspend fun publish(message: OutboundMessage): TransportResult<Unit> {
        val client = connection.connectedClient() ?: return disconnectedFailure()
        return transportCall { client.publish(message.toNatsMessage()) }
    }

    /**
     * Publishes a reply as one plain message, or as frames in credit windows when it exceeds the chunk size.
     *
     * A reply above the route's [TransportLimits.replyMaxBytes] sends one too large failure message and fails with
     * [TransferTooLarge]. The last frame of each window waits for the requester's credit, so the reply never runs
     * more than one window ahead. A failure part way is followed by an interrupted frame, so the requester fails at
     * once, and the failure is returned.
     */
    override suspend fun reply(
        message: OutboundMessage,
        limits: TransportLimits?,
    ): TransportResult<Unit> {
        val route = limits ?: this.limits
        return when (val plan = route.planPayload(message.payload, route.replyMaxBytes)) {
            PayloadPlan.Single -> {
                publish(message)
            }

            is PayloadPlan.TooLarge -> {
                when (val published = publish(message.framed(Payload.Empty, plan.headers))) {
                    is TransportResult.Failure -> published
                    is TransportResult.Success -> TransportResult.Failure(TransportError.Failure(TransferTooLarge(plan.size, plan.limit)))
                }
            }

            is PayloadPlan.Framed -> {
                val sent = plan.sendInWindows(MessageFrames(message, route), route.windowFrames, false, inactivity, inactivity)
                when (sent) {
                    is TransportResult.Failure -> sent
                    is TransportResult.Success -> TransportResult.Success(Unit)
                }
            }
        }
    }

    /**
     * Requests through a fresh transport owned inbox; caller-provided reply subjects are rejected.
     *
     * A request above the chunk size travels as frames in credit windows when the route's
     * [TransportLimits.requestMaxBytes] allows it and fails with [TransferTooLarge] before any frame otherwise. The
     * first reply message must arrive within [timeout] and each further frame of a framed reply within the frame
     * inactivity bound. Timeouts, no responders and framing failures are result values; every inbox and retained
     * frame is released on every exit, including cancellation.
     */
    override suspend fun request(
        message: OutboundMessage,
        timeout: Duration,
        limits: TransportLimits?,
    ): TransportResult<InboundMessage> {
        require(message.replyTo == null) { "NATS requests cannot specify replyTo" }
        timeout.toPositiveMilliseconds("Request timeout")
        val route = limits ?: this.limits
        return when (val plan = route.planPayload(message.payload, route.requestMaxBytes)) {
            PayloadPlan.Single -> {
                exchange(message, timeout, route)
            }

            is PayloadPlan.TooLarge -> {
                TransportResult.Failure(TransportError.Failure(TransferTooLarge(plan.size, plan.limit)))
            }

            is PayloadPlan.Framed -> {
                when (val sent = plan.sendInWindows(MessageFrames(message, route), route.windowFrames, true, inactivity, timeout)) {
                    is TransportResult.Failure -> sent
                    is TransportResult.Success -> TransportResult.Success(requireNotNull(sent.value))
                }
            }
        }
    }

    /** Publishes [message] with a fresh inbox as its reply address and returns the complete answer. */
    private suspend fun exchange(
        message: OutboundMessage,
        timeout: Duration,
        route: TransportLimits,
    ): TransportResult<InboundMessage> {
        val inbox =
            when (val opened = openInbox()) {
                is TransportResult.Failure -> return opened
                is TransportResult.Success -> opened.value
            }
        try {
            val published = publish(message.copy(replyTo = inbox.address))
            if (published is TransportResult.Failure) return published
            return awaitReply(inbox.subscription.deliveries, timeout, route)
        } finally {
            withContext(NonCancellable) { inbox.subscription.close() }
        }
    }

    private suspend fun awaitReply(
        deliveries: Flow<TransportDelivery>,
        timeout: Duration,
        route: TransportLimits,
    ): TransportResult<InboundMessage> =
        coroutineScope {
            val frames = deliveries.produceIn(this)
            try {
                frames.receiveAssembled(PayloadAssembler(route, route.replyMaxBytes, inactivity = inactivity), timeout)
            } finally {
                frames.cancel()
            }
        }

    /** Receives until one payload is complete; the first message within [timeout], each later frame within the inactivity bound. */
    private suspend fun ReceiveChannel<TransportDelivery>.receiveAssembled(
        assembler: PayloadAssembler,
        timeout: Duration,
    ): TransportResult<InboundMessage> {
        var wait = timeout
        while (true) {
            val received = withTimeoutOrNull(wait) { receiveCatching() } ?: return replyTimeout()
            wait = inactivity
            when (val delivery = received.getOrNull() ?: TransportDelivery.Completed) {
                is TransportDelivery.Message -> {
                    when (val assembled = assembler.deliver(delivery.message, ::publish)) {
                        is TransportResult.Failure -> return assembled
                        is TransportResult.Success -> assembled.value?.let { return TransportResult.Success(it) }
                    }
                }

                is TransportDelivery.Failure -> {
                    return TransportResult.Failure(delivery.error)
                }

                TransportDelivery.Completed -> {
                    return TransportResult.Failure(TransportError.Unavailable(IllegalStateException("NATS reply inbox closed")))
                }
            }
        }
    }

    /** The frames of one outbound payload: published on its address, window ends exchanged for their answer. */
    private inner class MessageFrames(
        private val message: OutboundMessage,
        private val route: TransportLimits,
    ) : FrameChannel {
        override suspend fun publish(frame: PayloadFrame) = publish(message.framed(frame.payload, frame.headers))

        override suspend fun request(
            frame: PayloadFrame,
            timeout: Duration,
        ) = exchange(message.framed(frame.payload, frame.headers).copy(replyTo = null), timeout, route)

        override suspend fun interrupt(payloadId: String) {
            publish(message.framed(Payload.Empty, interruptedHeaders(payloadId)).copy(replyTo = null))
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
 * A reply channel whose deliveries are complete replies. Each collection assembles frames by payload id and answers
 * every window end with its credit. A framing failure belongs to one responder's reply: it is delivered as a
 * [TransportDelivery.Failure] whose cause is the [TransferFailure], and the channel keeps delivering the other
 * responders' replies. Only a failure of the underlying subscription ends the deliveries.
 */
private class NatsReplyChannel(
    private val inbox: NatsInbox,
    private val limits: TransportLimits,
    private val inactivity: Duration,
    private val publish: suspend (OutboundMessage) -> TransportResult<Unit>,
) : ReplyChannel {
    override val address: MessageAddress get() = inbox.address

    override val deliveries: Flow<TransportDelivery> =
        flow {
            val assembler = PayloadAssembler(limits, limits.replyMaxBytes, inactivity = inactivity)
            inbox.subscription.deliveries
                .mapNotNull { delivery ->
                    when (delivery) {
                        is TransportDelivery.Message -> {
                            when (val assembled = assembler.deliver(delivery.message, publish)) {
                                is TransportResult.Failure -> TransportDelivery.Failure(assembled.error)
                                is TransportResult.Success -> assembled.value?.let(TransportDelivery::Message)
                            }
                        }

                        else -> {
                            delivery
                        }
                    }
                }.collect { emit(it) }
        }

    override suspend fun close() = inbox.subscription.close()
}

/**
 * Accepts one received message: a complete payload, nothing yet, or a failure of this sender's payload. A window end
 * is answered through [publish] on its reply address.
 */
private suspend fun PayloadAssembler.deliver(
    message: InboundMessage,
    publish: suspend (OutboundMessage) -> TransportResult<Unit>,
): TransportResult<InboundMessage?> =
    try {
        when (val assembled = accept(message)) {
            is Assembly.Complete -> {
                TransportResult.Success(assembled.message)
            }

            is Assembly.Answer -> {
                val answered = publish(OutboundMessage(requireNotNull(message.replyTo), Payload.Empty, headers = assembled.headers))
                // Refusing a sender's window also ends this receiver's wait for the payload.
                val refusal = assembled.headers.first(PayloadHeaders.FAILURE)?.let { transferFailure(it, assembled.headers) }
                when {
                    answered is TransportResult.Failure -> answered
                    refusal != null -> TransportResult.Failure(TransportError.Failure(refusal))
                    else -> TransportResult.Success(null)
                }
            }

            Assembly.Waiting -> {
                TransportResult.Success(null)
            }

            is Assembly.Failed -> {
                TransportResult.Failure(TransportError.Failure(assembled.failure))
            }
        }
    } catch (rejected: TransferRejected) {
        TransportResult.Failure(TransportError.Failure(rejected))
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
