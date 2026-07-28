package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.transport.*
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.receiveAsFlow
import kotlin.time.Duration

/** Deterministic in-memory transport for communicator and downstream tests. */
class FakeMessageTransport(
    override val system: MessagingSystem = MessagingSystem.of("fake"),
    private val deliveryBufferCapacity: Int = Channel.UNLIMITED,
) : MessageTransport, AutoCloseable {
    private val lock = Any()
    private val recorded = mutableListOf<Action>()
    private val subscriptions = mutableSetOf<FakeSubscription>()
    private val responders = ArrayDeque<suspend (OutboundMessage, Duration) -> TransportResult<InboundMessage>>()
    private val requestFailures = ArrayDeque<TransportError>()
    private val publishFailures = ArrayDeque<TransportError>()
    private val subscribeFailures = ArrayDeque<TransportError>()
    private var closed = false
    private var subscriptionAttempts = 0
    private val subscriptionFailuresAt = mutableMapOf<Int, TransportError>()
    private val subscriptionCloseBehaviorsAt = mutableMapOf<Int, suspend () -> Unit>()

    /** Immutable ordered snapshot of recorded actions. */
    val actions: List<Action> get() = synchronized(lock) { recorded.toList() }

    /** Number of subscriptions that have not been closed. */
    val activeSubscriptionCount: Int get() = synchronized(lock) { subscriptions.size }

    /** Configures a one-shot subscription failure at the one-based [attempt]. */
    fun failSubscribeAt(attempt: Int, error: TransportError) = synchronized(lock) {
        require(attempt > 0) { "attempt must be positive" }
        subscriptionFailuresAt[attempt] = error
    }

    /** Configures close behavior for the subscription created by the one-based [attempt]. */
    fun closeSubscriptionWith(attempt: Int, behavior: suspend () -> Unit) = synchronized(lock) {
        require(attempt > 0) { "attempt must be positive" }
        subscriptionCloseBehaviorsAt[attempt] = behavior
    }

    /** Adds a one-shot request responder. */
    fun respondWith(responder: suspend (OutboundMessage, Duration) -> TransportResult<InboundMessage>) =
        synchronized(lock) {
            responders.addLast(responder)
        }

    /** Configures the next request to return [error]. */
    fun failNextRequest(error: TransportError) = synchronized(lock) { requestFailures.addLast(error) }

    /** Configures the next publish to return [error]. */
    fun failNextPublish(error: TransportError) = synchronized(lock) { publishFailures.addLast(error) }

    /** Configures the next subscription to return [error]. */
    fun failNextSubscribe(error: TransportError) = synchronized(lock) { subscribeFailures.addLast(error) }

    /** Delivers [delivery] to every currently matching subscription. */
    fun deliver(delivery: TransportDelivery) {
        val targets = synchronized(lock) {
            subscriptions.filter { delivery !is TransportDelivery.Message || it.matches(delivery.message) }
        }
        targets.forEach { it.deliver(delivery) }
    }

    override suspend fun publish(message: OutboundMessage): TransportResult<Unit> = synchronized(lock) {
        ensureOpen()
        recorded += Action.Publish(message.snapshot())
        publishFailures.removeFirstOrNull()?.let { return TransportResult.Failure(it) }
        TransportResult.Success(Unit)
    }

    override suspend fun request(message: OutboundMessage, timeout: Duration): TransportResult<InboundMessage> {
        val responder = synchronized(lock) {
            ensureOpen()
            recorded += Action.Request(message.snapshot(), timeout)
            requestFailures.removeFirstOrNull()?.let { return TransportResult.Failure(it) }
            responders.removeFirstOrNull()
        } ?: return TransportResult.Failure(TransportError.NoResponders())
        return responder(message.snapshot(), timeout)
    }

    override suspend fun subscribe(
        pattern: AddressPattern,
        options: SubscriptionOptions
    ): TransportResult<TransportSubscription> = synchronized(lock) {
        ensureOpen()
        recorded += Action.Subscribe(pattern, options)
        subscriptionAttempts++
        subscriptionFailuresAt.remove(subscriptionAttempts)?.let { return TransportResult.Failure(it) }
        subscribeFailures.removeFirstOrNull()?.let { return TransportResult.Failure(it) }
        TransportResult.Success(
            FakeSubscription(
                pattern,
                subscriptionCloseBehaviorsAt.remove(subscriptionAttempts)
            ).also(subscriptions::add),
        )
    }

    override fun close() {
        val active = synchronized(lock) {
            if (closed) return
            closed = true
            recorded += Action.Close
            subscriptions.toList()
        }
        active.forEach(FakeSubscription::closeImmediately)
    }

    private fun deregister(subscription: FakeSubscription) = synchronized(lock) {
        if (subscriptions.remove(subscription)) recorded += Action.SubscriptionClose(subscription.pattern)
    }

    private fun ensureOpen() = check(!closed) { "Fake transport is closed" }

    /** An operation observed by the fake transport. */
    sealed interface Action {
        data class Subscribe(val pattern: AddressPattern, val options: SubscriptionOptions) : Action
        data class Publish(val message: OutboundMessage) : Action
        data class Request(val message: OutboundMessage, val timeout: Duration) : Action
        data class SubscriptionClose(val pattern: AddressPattern) : Action
        data object Close : Action
    }

    private inner class FakeSubscription(
        val pattern: AddressPattern,
        private val closeBehavior: (suspend () -> Unit)?,
    ) : TransportSubscription {
        private val channel = Channel<TransportDelivery>(deliveryBufferCapacity)
        private var closed = false
        override val deliveries: Flow<TransportDelivery> = channel.receiveAsFlow()

        fun deliver(delivery: TransportDelivery) {
            val accepted = synchronized(lock) {
                if (closed) false else {
                    channel.trySend(delivery)
                    if (delivery !is TransportDelivery.Message) {
                        closed = true
                        channel.close()
                        subscriptions.remove(this).also { if (it) recorded += Action.SubscriptionClose(pattern) }
                    }
                    true
                }
            }
            if (!accepted) return
        }

        fun matches(message: InboundMessage): Boolean {
            val expected = pattern.value.split('.')
            val actual = message.address.value.split('.')
            return expected.size == actual.size && expected.zip(actual)
                .all { (left, right) -> left == "*" || left == right }
        }

        override suspend fun close() {
            closeBehavior?.invoke()
            closeImmediately()
        }

        fun closeImmediately() {
            synchronized(lock) {
                if (closed) return
                closed = true
                channel.close()
            }
            deregister(this)
        }
    }
}

private fun OutboundMessage.snapshot() = copy(payload = payload.copyOf())
