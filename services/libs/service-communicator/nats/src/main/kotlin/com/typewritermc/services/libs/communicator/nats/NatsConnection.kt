package com.typewritermc.services.libs.communicator.nats

import com.typewritermc.services.libs.utils.findExceptionalThrowable
import kotlinx.coroutines.*
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import java.util.concurrent.atomic.AtomicReference

/** Observable lifecycle states of [NatsConnection]. */
enum class NatsConnectionState { Disconnected, Connecting, Connected, Reconnecting, ShuttingDown }

/** Explicit lifecycle operation outcome. */
sealed interface NatsLifecycleResult {
    data object Success : NatsLifecycleResult
    data class Failure(val error: NatsLifecycleError) : NatsLifecycleResult
}

/** Typed connection lifecycle failures. */
sealed interface NatsLifecycleError {
    val cause: Throwable

    data class Configuration(override val cause: Throwable) : NatsLifecycleError
    data class Authentication(override val cause: Throwable) : NatsLifecycleError
    data class Connection(override val cause: Throwable) : NatsLifecycleError
    data class Shutdown(override val cause: Throwable) : NatsLifecycleError
}

/** Owns NATS lifecycle and clears constructed clients before exceptional failures escape. */
class NatsConnection internal constructor(
    private val configurationProvider: NatsConfigurationProvider,
    private val authenticationProvider: NatsAuthenticationProvider,
    private val clientFactory: NatsClientFactory,
) {
    /** Creates a connection using the production NATS.kt client factory. */
    constructor(
        configurationProvider: NatsConfigurationProvider,
        authenticationProvider: NatsAuthenticationProvider,
    ) : this(configurationProvider, authenticationProvider, DefaultNatsClientFactory)

    private val lifecycle = Mutex()
    private val mutableState = MutableStateFlow(NatsConnectionState.Disconnected)
    private var activeClient: NatsClientAdapter? = null
    private var activeConfiguration: NatsConnectionConfiguration? = null
    private var monitorJob: Job? = null
    private var monitorScope: CoroutineScope? = null

    /** Current lifecycle state. */
    val state: StateFlow<NatsConnectionState> = mutableState.asStateFlow()

    /** Connects a newly configured client. */
    suspend fun connect(): NatsLifecycleResult = lifecycle.withLock {
        check(activeClient == null && mutableState.value == NatsConnectionState.Disconnected) { "NATS connection is already active" }
        connectNew(NatsConnectionState.Connecting)
    }

    /** Deliberately disconnects the old client and reconnects using freshly loaded providers. */
    suspend fun reconnect(): NatsLifecycleResult = lifecycle.withLock {
        val old = checkNotNull(activeClient) { "NATS connection is not connected" }
        mutableState.value = NatsConnectionState.Reconnecting
        cancelMonitor()
        try {
            old.disconnect()
        } catch (failure: Throwable) {
            try {
                withContext(NonCancellable) { old.disconnect() }
            } catch (cleanupFailure: Throwable) {
                throw combineFailures(failure, cleanupFailure)
            } finally {
                clearConnection()
            }
            exceptionalCause(failure)?.let { throw it }
            return@withLock NatsLifecycleResult.Failure(NatsLifecycleError.Connection(failure))
        }
        clearConnection()
        connectNew(NatsConnectionState.Reconnecting)
    }

    /** Drains by the configured deadline, always disconnects, and leaves the connection reusable. */
    suspend fun shutdown(): NatsLifecycleResult = lifecycle.withLock {
        val client = activeClient ?: return@withLock NatsLifecycleResult.Success
        val timeout = checkNotNull(activeConfiguration).shutdownTimeout
        mutableState.value = NatsConnectionState.ShuttingDown
        cancelMonitor()
        var primary: Throwable? = null
        try {
            client.drain(timeout)
        } catch (failure: Throwable) {
            primary = failure
        }
        try {
            withContext(NonCancellable) { client.disconnect() }
        } catch (failure: Throwable) {
            primary = combineFailures(primary, failure)
        } finally {
            clearConnection()
        }
        primary?.let {
            exceptionalCause(it)?.let { exceptional -> throw exceptional }
            NatsLifecycleResult.Failure(NatsLifecycleError.Shutdown(it))
        } ?: NatsLifecycleResult.Success
    }

    internal fun connectedClient(): NatsClientAdapter? = activeClient?.takeIf {
        mutableState.value == NatsConnectionState.Connected && it.connectivity.value == NatsClientConnectivity.Connected
    }

    private suspend fun connectNew(connectingState: NatsConnectionState): NatsLifecycleResult {
        mutableState.value = connectingState
        val configuration = try {
            configurationProvider.configuration()
        } catch (failure: Throwable) {
            clearConnection()
            rethrowExceptional(failure)
            return NatsLifecycleResult.Failure(NatsLifecycleError.Configuration(failure))
        }
        val authenticationFailure = AtomicReference<Throwable?>(null)
        val client = try {
            clientFactory.create(configuration) { hasNonce, signer ->
                try {
                    authenticationProvider.authenticate(NatsAuthenticationChallenge(hasNonce, signer))
                } catch (failure: Throwable) {
                    authenticationFailure.compareAndSet(null, failure)
                    throw failure
                }
            }
        } catch (failure: Throwable) {
            clearConnection()
            rethrowExceptional(authenticationFailure.get() ?: failure)
            return NatsLifecycleResult.Failure(classifyConnectionFailure(failure, authenticationFailure.get()))
        }
        return try {
            client.connect().getOrThrow()
            activeClient = client
            activeConfiguration = configuration
            mutableState.value = NatsConnectionState.Connected
            startMonitor(client)
            NatsLifecycleResult.Success
        } catch (failure: Throwable) {
            val original = authenticationFailure.get() ?: failure
            try {
                cleanup(client)
            } catch (cleanupFailure: Throwable) {
                throw combineFailures(original, cleanupFailure)
            }
            rethrowExceptional(original)
            NatsLifecycleResult.Failure(classifyConnectionFailure(failure, authenticationFailure.get()))
        }
    }

    private fun startMonitor(client: NatsClientAdapter) {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.Unconfined)
        monitorScope = scope
        monitorJob = scope.launch(start = CoroutineStart.UNDISPATCHED) {
            client.connectivity.collectLatest { connectivity ->
                if (activeClient !== client) return@collectLatest
                mutableState.value = when (connectivity) {
                    NatsClientConnectivity.Connected -> NatsConnectionState.Connected
                    NatsClientConnectivity.Connecting -> NatsConnectionState.Reconnecting
                    NatsClientConnectivity.Disconnected -> NatsConnectionState.Disconnected
                }
            }
        }
    }

    private fun cancelMonitor() {
        monitorJob?.cancel()
        monitorJob = null
        monitorScope?.cancel()
        monitorScope = null
    }

    private fun clearConnection() {
        cancelMonitor()
        activeClient = null
        activeConfiguration = null
        mutableState.value = NatsConnectionState.Disconnected
    }

    private suspend fun cleanup(client: NatsClientAdapter) {
        withContext(NonCancellable) {
            try {
                client.disconnect()
            } catch (cleanupFailure: Throwable) {
                rethrowExceptional(cleanupFailure)
            } finally {
                clearConnection()
            }
        }
    }
}

private fun classifyConnectionFailure(failure: Throwable, authenticationFailure: Throwable?): NatsLifecycleError =
    authenticationFailure?.let(NatsLifecycleError::Authentication) ?: NatsLifecycleError.Connection(failure)

internal fun exceptionalCause(failure: Throwable): Throwable? = findExceptionalThrowable(failure)

internal fun combineFailures(primary: Throwable?, cleanup: Throwable): Throwable {
    if (primary == null) return cleanup
    val exceptionalCleanup = exceptionalCause(cleanup)
    if (exceptionalCleanup != null) {
        if (exceptionalCleanup !== primary) exceptionalCleanup.addSuppressed(primary)
        return exceptionalCleanup
    }
    if (cleanup !== primary) primary.addSuppressed(cleanup)
    return primary
}

internal fun rethrowExceptional(failure: Throwable) {
    exceptionalCause(failure)?.let { throw it }
}
