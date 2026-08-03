package com.typewritermc.services.libs.communicator.nats

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.MessageAddress
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
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.TimeoutCancellationException
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.catch
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.flow
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.transformWhile
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlin.time.Duration

/** Core-NATS transport adapter backed by a connected [NatsConnection]. */
class NatsMessageTransport(
    private val connection: NatsConnection,
) : MessageTransport {
    override val system: MessagingSystem = MessagingSystem.of("nats")

    override suspend fun publish(message: OutboundMessage): TransportResult<Unit> {
        val client = connection.connectedClient() ?: return disconnectedFailure()
        return transportCall { client.publish(message.toNatsMessage()) }
    }

    /** Requests using the inbox owned by NATS.kt; caller-provided reply subjects are rejected. */
    override suspend fun request(
        message: OutboundMessage,
        timeout: Duration,
    ): TransportResult<InboundMessage> {
        require(message.replyTo == null) { "NATS requests cannot specify replyTo" }
        val timeoutMs = timeout.toPositiveMilliseconds("Request timeout")
        val client = connection.connectedClient() ?: return disconnectedFailure()
        return try {
            val response = client.request(message.toNatsMessage(), timeoutMs)
            response.statusError()?.let { TransportResult.Failure(it) }
                ?: TransportResult.Success(response.toInboundMessage())
        } catch (failure: TimeoutCancellationException) {
            currentCoroutineContext().ensureActive()
            TransportResult.Failure(TransportError.Timeout(failure))
        } catch (failure: Throwable) {
            rethrowExceptional(failure)
            TransportResult.Failure(TransportError.Failure(failure))
        }
    }

    override suspend fun subscribe(
        pattern: AddressPattern,
        options: SubscriptionOptions,
    ): TransportResult<TransportSubscription> {
        val client = connection.connectedClient() ?: return disconnectedFailure()
        val subscription =
            try {
                client.subscribe(pattern.value, options.consumerGroup?.value)
            } catch (failure: Throwable) {
                rethrowExceptional(failure)
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
            rethrowExceptional(failure)
            TransportResult.Failure(TransportError.Failure(failure))
        }
    }
}

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
                    rethrowExceptional(failure)
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
        payload = payload ?: byteArrayOf(),
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
        rethrowExceptional(failure)
        TransportResult.Failure(TransportError.Failure(failure))
    }

private fun <Value> disconnectedFailure(): TransportResult<Value> =
    TransportResult.Failure(TransportError.Unavailable(IllegalStateException("NATS connection is not connected")))
