package com.typewritermc.services.libs.registrar.testing

import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.registrar.BindingObservation
import com.typewritermc.services.libs.registrar.BindingStatus
import com.typewritermc.services.libs.registrar.CredentialLoadResult
import com.typewritermc.services.libs.registrar.CredentialStorage
import com.typewritermc.services.libs.registrar.CredentialStoreResult
import com.typewritermc.services.libs.registrar.IdentityCredentials
import com.typewritermc.services.libs.registrar.IdentityIssueResult
import com.typewritermc.services.libs.registrar.IdentityIssuer
import com.typewritermc.services.libs.registrar.RegistrarDelay
import com.typewritermc.services.libs.registrar.RegistrarRuntime
import com.typewritermc.services.libs.registrar.RegistrarRuntimeFactory
import com.typewritermc.services.libs.registrar.RetryRandom
import com.typewritermc.services.libs.registrar.RuntimeCloseResult
import com.typewritermc.services.libs.registrar.RuntimeConnectivity
import com.typewritermc.services.libs.registrar.RuntimeCreateResult
import com.typewritermc.services.libs.registrar.RuntimeResult
import com.typewritermc.services.libs.registrar.RuntimeSetupProgress
import com.typewritermc.services.libs.registrar.RuntimeSetupProgressSink
import com.typewritermc.services.libs.registrar.ServiceIdentity
import com.typewritermc.services.libs.registrar.ServiceRole
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.launch
import java.util.concurrent.atomic.AtomicInteger
import kotlin.time.Duration

sealed interface RegistrarAction {
    data object LoadCredentials : RegistrarAction

    data class StoreCredentials(
        val identity: ServiceIdentity,
        val referenceId: Int,
    ) : RegistrarAction

    data class IssueIdentity(
        val roles: List<ServiceRole>,
    ) : RegistrarAction

    data class CreateRuntime(
        val identity: ServiceIdentity,
        val credentialReferenceId: Int,
    ) : RegistrarAction

    data class SetupProgress(
        val progress: RuntimeSetupProgress,
    ) : RegistrarAction

    data class Connect(
        val invocation: Int = 0,
    ) : RegistrarAction

    data class WatchBinding(
        val collection: Int = 0,
    ) : RegistrarAction

    data class CancelBindingWatch(
        val collection: Int,
    ) : RegistrarAction

    data object Reconnect : RegistrarAction

    data object QueryBinding : RegistrarAction

    data object Heartbeat : RegistrarAction

    data object Shutdown : RegistrarAction

    data object Close : RegistrarAction

    data class Delay(
        val duration: Duration,
    ) : RegistrarAction

    data object RandomSample : RegistrarAction
}

class RegistrarActionLedger {
    private val lock = Any()
    private val recorded = mutableListOf<RegistrarAction>()
    val actions: List<RegistrarAction> get() = synchronized(lock) { recorded.toList() }

    fun record(action: RegistrarAction) = synchronized(lock) { recorded += action }
}

class FakeCredentialStorage(
    initial: CredentialLoadResult = CredentialLoadResult.Missing,
    val ledger: RegistrarActionLedger = RegistrarActionLedger(),
) : CredentialStorage {
    private val loads = ArrayDeque<CredentialLoadResult>().apply { add(initial) }
    private val stores = ArrayDeque<CredentialStoreResult>()
    val actions get() = ledger.actions

    @Synchronized fun enqueueLoad(result: CredentialLoadResult) {
        loads += result
    }

    @Synchronized fun enqueueStore(result: CredentialStoreResult) {
        stores += result
    }

    override suspend fun load(): CredentialLoadResult =
        synchronized(this) {
            ledger.record(RegistrarAction.LoadCredentials)
            if (loads.size > 1) loads.removeFirst() else loads.first()
        }

    override suspend fun store(credentials: IdentityCredentials): CredentialStoreResult =
        synchronized(this) {
            ledger.record(RegistrarAction.StoreCredentials(credentials.identity, System.identityHashCode(credentials)))
            stores.removeFirstOrNull() ?: CredentialStoreResult.Success
        }
}

class FakeIdentityIssuer(
    val ledger: RegistrarActionLedger = RegistrarActionLedger(),
) : IdentityIssuer {
    private val results = ArrayDeque<IdentityIssueResult>()
    val actions get() = ledger.actions

    @Synchronized fun enqueue(result: IdentityIssueResult) {
        results += result
    }

    override suspend fun issue(roles: List<ServiceRole>): IdentityIssueResult =
        synchronized(this) {
            ledger.record(RegistrarAction.IssueIdentity(roles.toList()))
            checkNotNull(results.removeFirstOrNull()) { "No identity result scripted" }
        }
}

class FakeRegistrarRuntime(
    override val communicator: Communicator,
    val ledger: RegistrarActionLedger = RegistrarActionLedger(),
) : RegistrarRuntime {
    private val connectionResults = ArrayDeque<RuntimeResult<Unit>>()
    private val reconnectResults = ArrayDeque<RuntimeResult<Unit>>()
    private val queryResults = ArrayDeque<RuntimeResult<BindingStatus>>()
    private val heartbeatResults = ArrayDeque<RuntimeResult<Unit>>()
    private val shutdownResults = ArrayDeque<RuntimeResult<Unit>>()
    private val watchScripts = ArrayDeque<List<RuntimeResult<BindingObservation>>>()
    private val liveWatches = mutableMapOf<Int, Channel<RuntimeResult<BindingObservation>>>()
    private val watchCounter = AtomicInteger()
    private val connectCounter = AtomicInteger()
    private val mutableConnectivity = MutableStateFlow(RuntimeConnectivity.DISCONNECTED)
    override val connectivity: Flow<RuntimeConnectivity> = mutableConnectivity
    override val currentConnectivity: RuntimeConnectivity
        get() = mutableConnectivity.value

    @Volatile var closeResult: RuntimeCloseResult = RuntimeCloseResult.Success

    @Volatile var closeFailure: Throwable? = null

    @Volatile var shutdownFailure: Throwable? = null
    var beforeShutdown: suspend () -> Unit = {}
    var beforeClose: suspend () -> Unit = {}
    val actions get() = ledger.actions
    val activeWatchCount get() = synchronized(this) { liveWatches.size }

    @Synchronized fun enqueueConnect(result: RuntimeResult<Unit>) {
        connectionResults += result
    }

    @Synchronized fun enqueueReconnect(result: RuntimeResult<Unit>) {
        reconnectResults += result
    }

    @Synchronized fun enqueueQuery(result: RuntimeResult<BindingStatus>) {
        queryResults += result
    }

    @Synchronized fun enqueueHeartbeat(result: RuntimeResult<Unit>) {
        heartbeatResults += result
    }

    @Synchronized fun enqueueShutdown(result: RuntimeResult<Unit>) {
        shutdownResults += result
    }

    @Synchronized fun enqueueWatch(vararg values: RuntimeResult<BindingObservation>) {
        watchScripts += values.toList()
    }

    suspend fun emitBinding(value: RuntimeResult<BindingObservation>) {
        val targets = synchronized(this) { liveWatches.values.toList() }
        targets.forEach { it.send(value) }
    }

    fun setConnectivity(value: RuntimeConnectivity) {
        mutableConnectivity.value = value
    }

    override suspend fun connect(): RuntimeResult<Unit> =
        synchronized(this) {
            ledger.record(RegistrarAction.Connect(connectCounter.incrementAndGet()))
            connectionResults.removeFirstOrNull() ?: RuntimeResult.Success(Unit)
        }

    override fun watchBinding(): Flow<RuntimeResult<BindingObservation>> =
        channelFlow {
            val id = watchCounter.incrementAndGet()
            val channel = Channel<RuntimeResult<BindingObservation>>(Channel.UNLIMITED)
            val script =
                synchronized(this@FakeRegistrarRuntime) {
                    liveWatches[id] = channel
                    watchScripts.removeFirstOrNull().orEmpty()
                }
            ledger.record(RegistrarAction.WatchBinding(id))
            script.forEach { send(it) }
            val relay = launch { for (value in channel) send(value) }
            awaitClose {
                relay.cancel()
                synchronized(this@FakeRegistrarRuntime) { liveWatches.remove(id) }
                ledger.record(RegistrarAction.CancelBindingWatch(id))
            }
        }

    override suspend fun reconnectForBoundPermissions(): RuntimeResult<Unit> =
        synchronized(this) {
            ledger.record(RegistrarAction.Reconnect)
            reconnectResults.removeFirstOrNull()
                ?: RuntimeResult.Success(Unit)
        }

    override suspend fun queryBinding(): RuntimeResult<BindingStatus> =
        synchronized(this) {
            ledger.record(RegistrarAction.QueryBinding)
            checkNotNull(queryResults.removeFirstOrNull()) { "No binding query scripted" }
        }

    override suspend fun sendHeartbeat(): RuntimeResult<Unit> =
        synchronized(this) {
            ledger.record(RegistrarAction.Heartbeat)
            heartbeatResults.removeFirstOrNull()
                ?: RuntimeResult.Success(Unit)
        }

    override suspend fun sendShutdown(): RuntimeResult<Unit> {
        ledger.record(RegistrarAction.Shutdown)
        beforeShutdown()
        shutdownFailure?.let { throw it }
        return synchronized(this) {
            shutdownResults.removeFirstOrNull()
                ?: RuntimeResult.Success(Unit)
        }
    }

    override suspend fun close(): RuntimeCloseResult {
        ledger.record(RegistrarAction.Close)
        beforeClose()
        closeFailure?.let { throw it }
        return closeResult
    }
}

class FakeRegistrarRuntimeFactory(
    val ledger: RegistrarActionLedger = RegistrarActionLedger(),
) : RegistrarRuntimeFactory {
    private val results = ArrayDeque<RuntimeCreateResult>()
    private val progress = ArrayDeque<List<RuntimeSetupProgress>>()
    val actions get() = ledger.actions

    @Synchronized fun enqueue(
        result: RuntimeCreateResult,
        setup: List<RuntimeSetupProgress> = emptyList(),
    ) {
        results += result
        progress +=
            setup
    }

    override suspend fun create(
        credentials: IdentityCredentials,
        progress: RuntimeSetupProgressSink,
    ): RuntimeCreateResult =
        synchronized(this) {
            ledger.record(RegistrarAction.CreateRuntime(credentials.identity, System.identityHashCode(credentials)))
            this.progress.removeFirstOrNull().orEmpty().forEach {
                progress.report(it)
                ledger.record(RegistrarAction.SetupProgress(it))
            }
            checkNotNull(results.removeFirstOrNull()) { "No runtime result scripted" }
        }
}

class FakeRetryRandom(
    samples: Iterable<Double> = listOf(.5),
    val ledger: RegistrarActionLedger = RegistrarActionLedger(),
) : RetryRandom {
    private val values = ArrayDeque(samples.toList())
    val actions get() = ledger.actions

    @Synchronized override fun normalizedSample(): Double {
        ledger.record(RegistrarAction.RandomSample)
        return if (values.size >
            1
        ) {
            values.removeFirst()
        } else {
            values.first()
        }
    }
}

class FakeRegistrarDelay(
    private val delegate: suspend (Duration) -> Unit = {},
    val ledger: RegistrarActionLedger = RegistrarActionLedger(),
) : RegistrarDelay {
    val actions get() = ledger.actions

    override suspend fun delay(duration: Duration) {
        ledger.record(RegistrarAction.Delay(duration))
        delegate(duration)
    }
}
