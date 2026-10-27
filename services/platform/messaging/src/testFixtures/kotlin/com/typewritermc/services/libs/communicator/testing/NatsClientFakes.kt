package com.typewritermc.services.libs.communicator.testing

import com.typewritermc.services.libs.communicator.nats.NatsAuthentication
import com.typewritermc.services.libs.communicator.nats.NatsClientAdapter
import com.typewritermc.services.libs.communicator.nats.NatsClientConnectivity
import com.typewritermc.services.libs.communicator.nats.NatsClientFactory
import com.typewritermc.services.libs.communicator.nats.NatsClientMessage
import com.typewritermc.services.libs.communicator.nats.NatsClientSubscription
import com.typewritermc.services.libs.communicator.nats.NatsConnection
import com.typewritermc.services.libs.communicator.nats.NatsConnectionConfiguration
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.flowOf
import kotlin.time.Duration

internal typealias NatsAuthenticationCallback = suspend (Boolean, suspend (String) -> String?) -> NatsAuthentication

/** A client factory that hands out [client] and reports the authentication callback it was created with. */
internal class FakeNatsClientFactory(
    private val client: FakeNatsClient,
    private val created: suspend (NatsAuthenticationCallback) -> Unit = {},
) : NatsClientFactory {
    override fun create(
        configuration: NatsConnectionConfiguration,
        authentication: suspend (Boolean, suspend (String) -> String?) -> NatsAuthentication,
    ): NatsClientAdapter {
        client.onConnect = { created(authentication) }
        return client
    }
}

/**
 * A NATS client that records its lifecycle calls in [events], connects with [connectResult], and fails publish,
 * flush, drain or disconnect when given the failure.
 */
internal class FakeNatsClient(
    private val connectResult: Result<Unit> = Result.success(Unit),
    private val publishFailure: Throwable? = null,
    private val subscription: FakeNatsSubscription = FakeNatsSubscription(flowOf()),
    private val flushFailure: Throwable? = null,
    var drainFailure: Throwable? = null,
    var disconnectFailure: Throwable? = null,
) : NatsClientAdapter {
    override val connectivity = MutableStateFlow(NatsClientConnectivity.Connected)
    val events = mutableListOf<String>()
    var onConnect: suspend () -> Unit = {}

    override suspend fun connect(): Result<Unit> {
        events += "connect"
        onConnect()
        return connectResult
    }

    override suspend fun disconnect() {
        events += "disconnect"
        disconnectFailure?.let { throw it }
    }

    override suspend fun drain(timeout: Duration) {
        events += "drain"
        drainFailure?.let { throw it }
    }

    override suspend fun flush() {
        events += "flush"
        flushFailure?.let { throw it }
    }

    override suspend fun publish(message: NatsClientMessage) {
        publishFailure?.let { throw it }
    }

    override suspend fun subscribe(
        subject: String,
        queueGroup: String?,
    ): NatsClientSubscription {
        events += "subscribe:$subject:$queueGroup"
        return subscription
    }
}

/** A subscription that delivers [messages] and counts unsubscribe calls. */
internal class FakeNatsSubscription(
    override val messages: Flow<NatsClientMessage>,
) : NatsClientSubscription {
    override val isActive: StateFlow<Boolean> = MutableStateFlow(true)
    var unsubscribeCalls = 0

    override suspend fun unsubscribe() {
        unsubscribeCalls++
    }
}

/** A connection to a fixed local URL that creates [client]. */
internal fun natsConnection(client: FakeNatsClient) =
    NatsConnection(
        { NatsConnectionConfiguration("nats://localhost") },
        { NatsAuthentication() },
        FakeNatsClientFactory(client),
    )
