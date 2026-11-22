package com.typewritermc.engine.delivery.testing

import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import kotlinx.coroutines.delay
import java.util.concurrent.atomic.AtomicInteger
import kotlin.time.Duration
import kotlin.time.TimeMark

/**
 * A transport that loses messages on purpose, as a network does: the next [loseRequests] requests to an engine's event
 * inbox never arrive, so the asker waits its whole timeout, and the next [loseReplies] answers the inbox sends never
 * reach the asker. Everything else passes to [delegate].
 */
class LossyTransport(
    private val delegate: MessageTransport,
) : MessageTransport by delegate {
    private val requests = AtomicInteger()
    private val replies = AtomicInteger()

    /** Loses the next [count] requests to an event inbox. */
    fun loseRequests(count: Int = 1) = requests.set(count)

    /** Loses the next [count] answers of this engine's event inbox. */
    fun loseReplies(count: Int = 1) = replies.set(count)

    override suspend fun request(
        message: OutboundMessage,
        timeout: Duration,
        limits: TransportLimits?,
    ): TransportResult<InboundMessage> {
        if (message.isInboxAsk() && requests.getAndUpdate { (it - 1).coerceAtLeast(0) } > 0) {
            delay(timeout)
            return TransportResult.Failure(TransportError.Timeout())
        }
        return delegate.request(message, timeout, limits)
    }

    override suspend fun reply(
        message: OutboundMessage,
        limits: TransportLimits?,
        received: TimeMark?,
    ): TransportResult<Unit> {
        if (replies.getAndUpdate { (it - 1).coerceAtLeast(0) } > 0) return TransportResult.Success(Unit)
        return delegate.reply(message, limits, received)
    }

    private fun OutboundMessage.isInboxAsk() = address.value.endsWith(".event") && ".engine." in address.value
}
