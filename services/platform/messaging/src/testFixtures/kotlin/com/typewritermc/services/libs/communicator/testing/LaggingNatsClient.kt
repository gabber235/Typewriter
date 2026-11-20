package com.typewritermc.services.libs.communicator.testing

import io.natskt.api.ConnectionPhase
import io.natskt.api.ConnectionState
import io.natskt.api.NatsClient
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.launch
import java.lang.reflect.Proxy
import kotlin.time.Duration.Companion.milliseconds

/**
 * A natskt client whose connect succeeds before its connection state says so, as natskt's does: its state reaches
 * collectors through coroutines of its own.
 */
class LaggingNatsClient : NatsClient by unusedClient {
    private val states = CoroutineScope(SupervisorJob() + Dispatchers.Default)
    override val connectionState = MutableStateFlow(state(ConnectionPhase.Idle))

    override suspend fun connect(): Result<Unit> {
        states.launch {
            delay(100.milliseconds)
            connectionState.value = state(ConnectionPhase.Connected)
        }
        return Result.success(Unit)
    }

    fun close() = states.cancel()

    private fun state(phase: ConnectionPhase) = ConnectionState(phase, null, null, null, 0u, 0u)
}

private val unusedClient: NatsClient =
    Proxy.newProxyInstance(NatsClient::class.java.classLoader, arrayOf(NatsClient::class.java)) { _, method, _ ->
        error("The lagging client does not offer ${method.name}.")
    } as NatsClient
