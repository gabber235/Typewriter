package com.typewritermc.services.libs.communicator.nats

import com.typewritermc.services.libs.communicator.transport.Payload
import io.natskt.NatsClient
import io.natskt.api.AuthPayload
import io.natskt.api.ConnectionPhase
import io.natskt.api.ConnectionState
import io.natskt.api.Credentials
import io.natskt.api.Message
import io.natskt.api.Subscription
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.receiveAsFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.coroutines.cancellation.CancellationException
import kotlin.time.Duration.Companion.seconds

internal data class NatsClientMessage(
    val subject: String,
    val payload: Payload?,
    val headers: Map<String, List<String>>?,
    val replyTo: String?,
    val status: Int?,
    val statusDescription: String?,
)

internal interface NatsClientSubscription {
    val messages: Flow<NatsClientMessage>
    val isActive: StateFlow<Boolean>

    suspend fun unsubscribe()
}

internal enum class NatsClientConnectivity { Disconnected, Connecting, Connected }

/**
 * Isolates the vendor NATS client behind the operations needed by lifecycle and transport adapters.
 *
 * Subscriptions and connectivity remain observable for deterministic tests. The connection owner drives drain and
 * disconnect; transport callers borrow this adapter.
 */
internal interface NatsClientAdapter {
    val connectivity: StateFlow<NatsClientConnectivity>

    suspend fun connect(): Result<Unit>

    suspend fun disconnect()

    suspend fun drain(timeout: kotlin.time.Duration)

    /** Returns once the server has processed every operation this client wrote before the call. */
    suspend fun flush()

    suspend fun publish(message: NatsClientMessage)

    suspend fun subscribe(
        subject: String,
        queueGroup: String?,
    ): NatsClientSubscription
}

/**
 * Constructs an unconnected client using explicit configuration and challenge authentication.
 *
 * Authentication can be invoked during connection or reconnection. Ownership transfers to [NatsConnection] after
 * construction.
 */
internal fun interface NatsClientFactory {
    fun create(
        configuration: NatsConnectionConfiguration,
        authentication: suspend (Boolean, suspend (String) -> String?) -> NatsAuthentication,
    ): NatsClientAdapter
}

internal object DefaultNatsClientFactory : NatsClientFactory {
    override fun create(
        configuration: NatsConnectionConfiguration,
        authentication: suspend (Boolean, suspend (String) -> String?) -> NatsAuthentication,
    ): NatsClientAdapter {
        val client =
            NatsClient {
                server = configuration.serverUrl
                name = configuration.clientName
                inboxPrefix = configuration.inboxPrefix
                connectTimeout = configuration.normalizedConnectTimeout
                maxReconnects = configuration.natsMaxConnectionAttempts
                reconnectDebounce = configuration.normalizedReconnectDelay
                this.authentication =
                    Credentials.Custom { info ->
                        val auth = authentication(info.nonce != null) { seed -> signNonce(seed, info) }
                        AuthPayload(auth.authToken, auth.username, auth.password, auth.jwt, auth.signature, auth.nkey)
                    }
            }
        return RealNatsClientAdapter(client)
    }
}

private class RealNatsClientAdapter(
    private val client: io.natskt.api.NatsClient,
) : NatsClientAdapter {
    private val clientScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    override val connectivity: StateFlow<NatsClientConnectivity> =
        client.connectionState
            .map { state ->
                when (state.phase) {
                    ConnectionPhase.Connected, ConnectionPhase.Draining, ConnectionPhase.LameDuck -> NatsClientConnectivity.Connected
                    ConnectionPhase.Connecting -> NatsClientConnectivity.Connecting
                    else -> NatsClientConnectivity.Disconnected
                }
            }.stateIn(clientScope, SharingStarted.Eagerly, NatsClientConnectivity.Disconnected)

    override suspend fun connect(): Result<Unit> = client.connect()

    override suspend fun disconnect() {
        try {
            client.disconnect()
        } finally {
            clientScope.cancel()
        }
    }

    override suspend fun drain(timeout: kotlin.time.Duration) = client.drain(timeout)

    private val roundTrips = Mutex()

    /**
     * Writes a PING and waits for its PONG. The server answers operations in order, so the PONG proves every
     * subscription written before is registered; writing the buffer alone does not. Round trips are serialized so a
     * PONG answers the PING of the caller that waits for it. The vendor records a PONG only as its time and round trip
     * time, so the wait ends when that pair changes.
     */
    override suspend fun flush() =
        roundTrips.withLock {
            val before = client.connectionState.value.lastPong()
            client.ping()
            client.flush()
            withTimeoutOrNull(ROUND_TRIP_TIMEOUT) { client.connectionState.first { it.lastPong() != before } }
                ?: throw IllegalStateException("The NATS server did not answer a PING within $ROUND_TRIP_TIMEOUT")
            Unit
        }

    override suspend fun publish(message: NatsClientMessage) {
        client.publish(message.subject, message.payload?.toByteArray(), message.headers, message.replyTo)
    }

    override suspend fun subscribe(
        subject: String,
        queueGroup: String?,
    ): NatsClientSubscription {
        val subscription =
            RealNatsClientSubscription(
                client.subscribe(subject, queueGroup, eager = true, unsubscribeOnLastCollector = false),
                clientScope,
            )
        subscription.isActive.first { it }
        return subscription
    }
}

private fun ConnectionState.lastPong() = lastPongAt to rtt

private val ROUND_TRIP_TIMEOUT = 5.seconds

/**
 * A vendor subscription whose messages are buffered from the moment it exists.
 *
 * The vendor hands messages to a shared flow without replay, which drops every message that arrives while nothing
 * collects. A request answered before its caller starts collecting would be lost, so a collector starts here, before
 * the server can deliver anything, and buffers each message until [messages] is collected. It runs unconfined so it
 * is collecting when the constructor returns.
 */
private class RealNatsClientSubscription(
    private val subscription: Subscription,
    scope: CoroutineScope,
) : NatsClientSubscription {
    private val buffered = Channel<NatsClientMessage>(Channel.UNLIMITED)
    private val bridge =
        scope
            .launch(Dispatchers.Unconfined, start = CoroutineStart.UNDISPATCHED) {
                subscription.messages.collect { buffered.send(it.toAdapterMessage()) }
            }.apply { invokeOnCompletion { cause -> buffered.close(cause.takeUnless { it is CancellationException }) } }

    override val messages: Flow<NatsClientMessage> = buffered.receiveAsFlow()
    override val isActive: StateFlow<Boolean> = subscription.isActive

    override suspend fun unsubscribe() {
        try {
            subscription.unsubscribe()
        } finally {
            bridge.cancel()
        }
    }
}

private fun Message.toAdapterMessage() =
    NatsClientMessage(
        subject = subject.raw,
        payload = data?.let(Payload::copyOf),
        headers = headers,
        replyTo = replyTo?.raw,
        status = status,
        statusDescription = statusDescription,
    )
