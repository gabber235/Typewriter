package com.typewritermc.services.libs.communicator.nats

import io.natskt.NatsClient
import io.natskt.api.AuthPayload
import io.natskt.api.ConnectionPhase
import io.natskt.api.Credentials
import io.natskt.api.Message
import io.natskt.api.Subscription
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.stateIn

internal data class NatsClientMessage(
    val subject: String,
    val payload: ByteArray?,
    val headers: Map<String, List<String>>?,
    val replyTo: String?,
    val status: Int?,
    val statusDescription: String?,
) {
    override fun equals(other: Any?): Boolean {
        if (this === other) return true
        if (javaClass != other?.javaClass) return false

        other as NatsClientMessage

        if (status != other.status) return false
        if (subject != other.subject) return false
        if (!payload.contentEquals(other.payload)) return false
        if (headers != other.headers) return false
        if (replyTo != other.replyTo) return false
        if (statusDescription != other.statusDescription) return false

        return true
    }

    override fun hashCode(): Int {
        var result = status ?: 0
        result = 31 * result + subject.hashCode()
        result = 31 * result + (payload?.contentHashCode() ?: 0)
        result = 31 * result + (headers?.hashCode() ?: 0)
        result = 31 * result + (replyTo?.hashCode() ?: 0)
        result = 31 * result + (statusDescription?.hashCode() ?: 0)
        return result
    }
}

internal interface NatsClientSubscription {
    val messages: Flow<NatsClientMessage>
    val isActive: StateFlow<Boolean>

    suspend fun unsubscribe()
}

internal enum class NatsClientConnectivity { Disconnected, Connecting, Connected }

internal interface NatsClientAdapter {
    val connectivity: StateFlow<NatsClientConnectivity>

    suspend fun connect(): Result<Unit>

    suspend fun disconnect()

    suspend fun drain(timeout: kotlin.time.Duration)

    suspend fun flush()

    suspend fun publish(message: NatsClientMessage)

    suspend fun request(
        message: NatsClientMessage,
        timeoutMs: Long,
    ): NatsClientMessage

    suspend fun subscribe(
        subject: String,
        queueGroup: String?,
    ): NatsClientSubscription
}

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

    override suspend fun flush() = client.flush()

    override suspend fun publish(message: NatsClientMessage) {
        client.publish(message.subject, message.payload, message.headers, message.replyTo)
    }

    override suspend fun request(
        message: NatsClientMessage,
        timeoutMs: Long,
    ): NatsClientMessage = client.request(message.subject, message.payload, message.headers, timeoutMs).toAdapterMessage()

    override suspend fun subscribe(
        subject: String,
        queueGroup: String?,
    ): NatsClientSubscription {
        val subscription =
            RealNatsClientSubscription(
                client.subscribe(subject, queueGroup, eager = true, unsubscribeOnLastCollector = false),
            )
        subscription.isActive.first { it }
        return subscription
    }
}

private class RealNatsClientSubscription(
    private val subscription: Subscription,
) : NatsClientSubscription {
    override val messages: Flow<NatsClientMessage> = subscription.messages.map { it.toAdapterMessage() }
    override val isActive: StateFlow<Boolean> = subscription.isActive

    override suspend fun unsubscribe() = subscription.unsubscribe()
}

private fun Message.toAdapterMessage() =
    NatsClientMessage(
        subject = subject.raw,
        payload = data,
        headers = headers,
        replyTo = replyTo?.raw,
        status = status,
        statusDescription = statusDescription,
    )
