package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.findExceptionalThrowable
import io.opentelemetry.api.common.Attributes
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.merge
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.random.Random
import kotlin.time.TimeSource

/** Structured service bootstrap and registration supervisor. */
class ServiceRegistrar(
    private val configuration: RegistrarConfiguration,
    private val scope: CoroutineScope,
    private val credentialStorage: CredentialStorage,
    private val identityIssuer: IdentityIssuer,
    private val runtimeFactory: RegistrarRuntimeFactory,
    private val telemetry: ServiceTelemetry,
    private val retryRandom: RetryRandom = RetryRandom { Random.nextDouble() },
    private val registrarDelay: RegistrarDelay = RegistrarDelay { delay(it) },
) {
    private val lifecycle = Mutex()
    private val mutableStates = MutableStateFlow(RegistrarSnapshot(0, 0, RegistrarState.Idle))
    private var coordinator: Job? = null
    private var runtime: RegistrarRuntime? = null
    private var retainedIssuedCredentials: IdentityCredentials? = null
    private var activeCredentials: IdentityCredentials? = null
    private var stopResult: RegistrarStopResult? = null
    @Volatile private var lifecycleState = LifecycleState.IDLE
    private var attempt = 0L

    val states: StateFlow<RegistrarSnapshot> = mutableStates

    suspend fun start(): RegistrarResult<Unit> = lifecycle.withLock {
        when (lifecycleState) {
            LifecycleState.IDLE -> {
                lifecycleState = LifecycleState.ACTIVE
                coordinator = scope.launch { coordinate() }
                RegistrarResult.Success(Unit)
            }
            LifecycleState.STOPPED -> RegistrarResult.Failure(RegistrarFailure.Internal("registrar_stopped"))
            LifecycleState.ACTIVE, LifecycleState.RETRY_RESERVED -> RegistrarResult.Success(Unit)
        }
    }

    suspend fun retry(): RegistrarResult<Unit> {
        val previous = lifecycle.withLock {
            if (lifecycleState == LifecycleState.STOPPED) {
                return RegistrarResult.Failure(RegistrarFailure.Internal("registrar_stopped"))
            }
            if (lifecycleState != LifecycleState.ACTIVE || mutableStates.value.state !is RegistrarState.Failed) {
                return RegistrarResult.Failure(RegistrarFailure.Internal("retry_not_failed"))
            }
            lifecycleState = LifecycleState.RETRY_RESERVED
            coordinator
        }
        previous?.join()
        return lifecycle.withLock {
            if (lifecycleState == LifecycleState.STOPPED) {
                return@withLock RegistrarResult.Failure(RegistrarFailure.Internal("registrar_stopped"))
            }
            if (lifecycleState != LifecycleState.RETRY_RESERVED || mutableStates.value.state !is RegistrarState.Failed) {
                return@withLock RegistrarResult.Failure(RegistrarFailure.Internal("retry_not_failed"))
            }
            lifecycleState = LifecycleState.ACTIVE
            attempt = saturatingIncrement(attempt)
            coordinator = scope.launch { coordinate() }
            RegistrarResult.Success(Unit)
        }
    }

    suspend fun awaitReady(): RegistrarResult<ReadySession> {
        val terminal = states.first {
            it.state is RegistrarState.Ready || it.state is RegistrarState.Failed || it.state is RegistrarState.Stopped
        }.state
        return when (terminal) {
            is RegistrarState.Ready -> RegistrarResult.Success(terminal.session)
            is RegistrarState.Failed -> RegistrarResult.Failure(terminal.failure)
            is RegistrarState.Stopped -> RegistrarResult.Failure(RegistrarFailure.Internal("registrar_stopped"))
            else -> error("terminal predicate violated")
        }
    }

    suspend fun stop(): RegistrarStopResult = lifecycle.withLock {
        stopResult?.let { return@withLock it }
        lifecycleState = LifecycleState.STOPPED
        coordinator?.cancel()
        withContext(NonCancellable) {
            transition(RegistrarState.Stopping)
            val deadline = TimeSource.Monotonic.markNow() + configuration.shutdownTimeout
            val failures = mutableListOf<RegistrarStopFailure>()
            if (!withinBudget(deadline) { coordinator?.join() }) failures += RegistrarStopFailure.Runtime(RuntimeStopOperation.COORDINATOR_TIMEOUT)
            coordinator = null
            try {
                failures += cleanup(runtime, sendShutdown = true, deadline = deadline)
            } finally {
                runtime = null
                retainedIssuedCredentials = null
                activeCredentials = null
            }
            val result = failures.toStopResult()
            stopResult = result
            transition(RegistrarState.Stopped(result))
            result
        }
    }

    private suspend fun coordinate() {
        try {
            telemetry.mainSpan(
                "registrar.attempt",
                ErrorSlug.of("registrar-attempt-failed"),
                attributes = Attributes.builder().put("registrar.attempt", attempt).build(),
            ) { runAttempt() }
            if (mutableStates.value.state is RegistrarState.Failed) {
                withContext(NonCancellable) { cleanupCurrentAttempt() }
            }
        } catch (failure: Throwable) {
            var cleanupFailure: Throwable? = null
            withContext(NonCancellable) {
                if (lifecycleState != LifecycleState.STOPPED) {
                    try {
                        cleanupCurrentAttempt()
                    } catch (thrown: Throwable) {
                        cleanupFailure = thrown
                    }
                    if (findExceptionalThrowable(failure) == null) {
                        terminal(RegistrarFailure.Internal("unexpected_failure"))
                    }
                }
            }
            val originalExceptional = findExceptionalThrowable(failure)
            if (originalExceptional != null && lifecycleState != LifecycleState.STOPPED) {
                withContext(NonCancellable) {
                    lifecycle.withLock {
                        lifecycleState = LifecycleState.STOPPED
                        coordinator = null
                        runtime = null
                        retainedIssuedCredentials = null
                        activeCredentials = null
                        val result = RegistrarStopResult.Success
                        stopResult = result
                        transition(RegistrarState.Stopped(result))
                    }
                }
            }
            val cleanupExceptional = cleanupFailure?.let(::findExceptionalThrowable)
            val primary = originalExceptional ?: cleanupExceptional ?: failure
            sequenceOf(originalExceptional, cleanupExceptional)
                .filterNotNull()
                .filter { it !== primary }
                .forEach(primary::addSuppressed)
            throw primary
        }
    }

    private suspend fun runAttempt() {
        val acquired = acquireCredentials() ?: return
        activeCredentials = acquired
        var setupStage = RegistrarStage.CONNECTING
        val created = retryPhase({ failure -> failure.runtimeCreateStage(setupStage) }) {
            runtimeFactory.create(acquired, RuntimeSetupProgressSink {
                setupProgress(it)
                setupStage = it.stage
            }).asRuntimeResult()
        } ?: return
        runtime = created
        if (retryPhase(RegistrarStage.CONNECTING) { created.connect() } == null) return
        awaitConnected(created)
        while (true) {
            val binding = superviseBinding(created, acquired.identity) ?: return
            transition(RegistrarState.Reauthorizing(binding))
            if (retryPhase(RegistrarStage.REAUTHORIZING) { created.reconnectForBoundPermissions() } == null) return
            when (val confirmed = retryPhase(RegistrarStage.BINDING) { created.queryBinding() } ?: return) {
                is BindingStatus.Bound -> {
                    superviseReady(created, acquired.identity, confirmed.binding)
                    return
                }
                is BindingStatus.Unbound -> transition(RegistrarState.AwaitingBinding(acquired.identity, confirmed.token))
            }
        }
    }

    private fun setupProgress(progress: RuntimeSetupProgress) {
        when (progress) {
            RuntimeSetupProgress.ACQUIRING_ACCESS_TOKEN -> activeCredentials?.identity?.let {
                transition(RegistrarState.AcquiringAccessToken(it))
            }
            RuntimeSetupProgress.ACQUIRING_SENTINEL_CREDENTIALS -> transition(RegistrarState.AcquiringSentinelCredentials)
            RuntimeSetupProgress.CONNECTING -> transition(RegistrarState.Connecting(attempt))
        }
    }

    private suspend fun acquireCredentials(): IdentityCredentials? {
        retainedIssuedCredentials?.let { return persist(it) }
        transition(RegistrarState.LoadingIdentity)
        var backoffIndex = 0L
        while (true) {
            when (val loaded = credentialStorage.load()) {
                CredentialLoadResult.Missing -> break
                is CredentialLoadResult.Loaded -> return loaded.credentials
                is CredentialLoadResult.Failure -> {
                    val failure = RegistrarFailure.CredentialStorage(loaded.error)
                    if (!loaded.error.recoverable) {
                        terminal(failure)
                        return null
                    }
                    retryDelay(RegistrarStage.STORAGE, failure, backoffIndex = backoffIndex.also { backoffIndex = saturatingIncrement(backoffIndex) })
                }
            }
        }
        transition(RegistrarState.IssuingIdentity)
        return when (val issued = identityIssuer.issue(configuration.roles)) {
            is IdentityIssueResult.Failure -> {
                transition(RegistrarState.Failed(RegistrarFailure.IdentityIssuance(issued.error), issued.error.outcomeMayBeAmbiguous))
                null
            }
            is IdentityIssueResult.Success -> {
                retainedIssuedCredentials = issued.credentials
                persist(issued.credentials)
            }
        }
    }

    private suspend fun persist(value: IdentityCredentials): IdentityCredentials? {
        transition(RegistrarState.PersistingIdentity(value.identity))
        var backoffIndex = 0L
        while (true) {
            when (val stored = credentialStorage.store(value)) {
                CredentialStoreResult.Success -> {
                    retainedIssuedCredentials = null
                    return value
                }
                is CredentialStoreResult.Failure -> {
                    val failure = RegistrarFailure.CredentialStorage(stored.error)
                    if (!stored.error.recoverable) {
                        terminal(failure)
                        return null
                    }
                    retryDelay(RegistrarStage.STORAGE, failure, backoffIndex = backoffIndex.also { backoffIndex = saturatingIncrement(backoffIndex) })
                }
            }
        }
    }

    private suspend fun superviseBinding(active: RegistrarRuntime, identity: ServiceIdentity): OrganizationBinding? {
        var bindingBackoffIndex = 0L
        while (true) {
            awaitConnected(active)
            val event = withTimeoutOrNull(configuration.bindingRefreshInterval) {
                merge(
                    active.watchBinding().map { BindingEvent.Observation(it) },
                    active.connectivity.map { BindingEvent.Connectivity(it) },
                ).first { it !is BindingEvent.Connectivity || it.value != RuntimeConnectivity.CONNECTED }
            }
            when (event) {
                null -> when (val queried = active.queryBinding()) {
                    is RuntimeResult.Success -> when (val status = queried.value) {
                        is BindingStatus.Bound -> return status.binding
                        is BindingStatus.Unbound -> {
                            bindingBackoffIndex = 0L
                            transition(RegistrarState.AwaitingBinding(identity, status.token))
                        }
                    }
                    is RuntimeResult.Failure -> if (!handleFailure(RegistrarStage.BINDING, queried.failure, bindingBackoffIndex.also { bindingBackoffIndex = saturatingIncrement(bindingBackoffIndex) })) return null
                }
                is BindingEvent.Connectivity -> awaitConnected(active)
                is BindingEvent.Observation -> when (val result = event.value) {
                    is RuntimeResult.Failure -> if (!handleFailure(RegistrarStage.BINDING, result.failure, bindingBackoffIndex.also { bindingBackoffIndex = saturatingIncrement(bindingBackoffIndex) })) return null
                    is RuntimeResult.Success -> when (val observation = result.value) {
                        is BindingObservation.Bound -> return observation.binding
                        is BindingObservation.Initial -> when (val status = observation.status) {
                            is BindingStatus.Bound -> return status.binding
                            is BindingStatus.Unbound -> {
                                bindingBackoffIndex = 0L
                                transition(RegistrarState.AwaitingBinding(identity, status.token))
                            }
                        }
                    }
                }
            }
        }
    }

    private suspend fun superviseReady(active: RegistrarRuntime, identity: ServiceIdentity, binding: OrganizationBinding) {
        val session = ReadySession(identity, binding, active.communicator)
        var generation = 1L
        while (true) {
            when (restoreHeartbeat(active, session)) {
                HeartbeatResult.TERMINAL -> return
                HeartbeatResult.RECONNECTED -> generation++
                HeartbeatResult.HEALTHY -> Unit
            }
            transition(RegistrarState.Ready(session, generation))
            val degraded = withTimeoutOrNull(configuration.heartbeatInterval) {
                active.connectivity.first { it != RuntimeConnectivity.CONNECTED }
            }
            if (degraded == null) continue
            awaitConnected(active, session)
            when (restoreHeartbeat(active, session)) {
                HeartbeatResult.TERMINAL -> return
                HeartbeatResult.RECONNECTED -> generation++
                HeartbeatResult.HEALTHY -> Unit
            }
            generation++
        }
    }

    private suspend fun restoreHeartbeat(active: RegistrarRuntime, session: ReadySession): HeartbeatResult {
        var backoffIndex = 0L
        var reconnected = false
        while (true) when (val heartbeat = active.sendHeartbeat()) {
            is RuntimeResult.Success -> return if (reconnected) HeartbeatResult.RECONNECTED else HeartbeatResult.HEALTHY
            is RuntimeResult.Failure -> {
                if (!heartbeat.failure.recoverable()) {
                    terminal(heartbeat.failure)
                    return HeartbeatResult.TERMINAL
                }
                retryDelay(RegistrarStage.HEARTBEAT, heartbeat.failure, session, backoffIndex.also { backoffIndex = saturatingIncrement(backoffIndex) })
                if (retryPhase(RegistrarStage.REAUTHORIZING) { active.reconnectForBoundPermissions() } == null) {
                    return HeartbeatResult.TERMINAL
                }
                awaitConnected(active, session)
                reconnected = true
            }
        }
    }

    private suspend fun awaitConnected(
        active: RegistrarRuntime,
        session: ReadySession? = null,
    ) {
        if (active.currentConnectivity == RuntimeConnectivity.CONNECTED) return
        retryDelay(
            RegistrarStage.CONNECTING,
            RegistrarFailure.Messaging(MessagingOperation.CONNECTIVITY),
            session,
            0,
        )
        active.connectivity.first { it == RuntimeConnectivity.CONNECTED }
    }

    private suspend fun <V> retryPhase(stage: RegistrarStage, operation: suspend () -> RuntimeResult<V>): V? = retryPhase({ stage }, operation)

    private suspend fun <V> retryPhase(stage: (RegistrarFailure) -> RegistrarStage, operation: suspend () -> RuntimeResult<V>): V? {
        var backoffIndex = 0L
        while (true) when (val result = operation()) {
            is RuntimeResult.Success -> return result.value
            is RuntimeResult.Failure -> if (!handleFailure(stage(result.failure), result.failure, backoffIndex.also { backoffIndex = saturatingIncrement(backoffIndex) })) return null
        }
    }

    private suspend fun handleFailure(stage: RegistrarStage, failure: RegistrarFailure, backoffIndex: Long): Boolean {
        if (!failure.recoverable()) {
            terminal(failure)
            return false
        }
        retryDelay(stage, failure, backoffIndex = backoffIndex)
        return true
    }

    private suspend fun retryDelay(
        stage: RegistrarStage,
        failure: RegistrarFailure,
        session: ReadySession? = null,
        backoffIndex: Long,
    ) {
        attempt = saturatingIncrement(attempt)
        val duration = configuration.retryPolicy.delayFor(backoffIndex, retryRandom.normalizedSample())
        transition(RegistrarState.Degraded(session, stage, failure, RetrySchedule(attempt, duration)))
        registrarDelay.delay(duration)
    }

    private suspend fun cleanupCurrentAttempt() {
        try {
            cleanup(runtime, sendShutdown = false, deadline = null)
        } finally {
            runtime = null
            activeCredentials = null
        }
    }

    private suspend fun cleanup(active: RegistrarRuntime?, sendShutdown: Boolean, deadline: TimeSource.Monotonic.ValueTimeMark?): List<RegistrarStopFailure> {
        if (active == null) return emptyList()
        val failures = mutableListOf<RegistrarStopFailure>()
        var exceptional: Throwable? = null
        if (sendShutdown && active.currentConnectivity == RuntimeConnectivity.CONNECTED) {
            try {
                var shutdown: RuntimeResult<Unit>? = null
                if (!withinBudget(deadline) { shutdown = active.sendShutdown() }) failures += RegistrarStopFailure.Runtime(RuntimeStopOperation.SHUTDOWN_TIMEOUT)
                else when (shutdown) {
                    is RuntimeResult.Failure -> failures += RegistrarStopFailure.Runtime(RuntimeStopOperation.SHUTDOWN_FAILED)
                    is RuntimeResult.Success -> Unit
                    null -> error("completed shutdown has no result")
                }
            } catch (thrown: Throwable) {
                val found = findExceptionalThrowable(thrown)
                if (found == null) failures += RegistrarStopFailure.Runtime(RuntimeStopOperation.SHUTDOWN_THROWN)
                else exceptional = combineExceptional(exceptional, found)
            }
        }
        try {
            var close: RuntimeCloseResult? = null
            if (!withinBudget(deadline) { close = active.close() }) failures += RegistrarStopFailure.Runtime(RuntimeStopOperation.CLOSE_TIMEOUT)
            else when (val result = close) {
                is RuntimeCloseResult.Failure -> failures += result.failures
                RuntimeCloseResult.Success -> Unit
                null -> error("completed close has no result")
            }
        } catch (thrown: Throwable) {
            val found = findExceptionalThrowable(thrown)
            if (found == null) failures += RegistrarStopFailure.Runtime(RuntimeStopOperation.CLOSE_THROWN)
            else exceptional = combineExceptional(exceptional, found)
        }
        exceptional?.let { throw it }
        return failures
    }

    private fun terminal(failure: RegistrarFailure) = transition(RegistrarState.Failed(failure, false))
    private fun transition(state: RegistrarState) = mutableStates.update { RegistrarSnapshot(it.sequence + 1, attempt, state) }
}

private enum class LifecycleState { IDLE, ACTIVE, RETRY_RESERVED, STOPPED }

private fun saturatingIncrement(value: Long): Long = if (value == Long.MAX_VALUE) value else value + 1

private fun combineExceptional(primary: Throwable?, additional: Throwable): Throwable {
    if (primary == null) return additional
    if (primary !== additional) primary.addSuppressed(additional)
    return primary
}

private sealed interface BindingEvent {
    data class Observation(val value: RuntimeResult<BindingObservation>) : BindingEvent
    data class Connectivity(val value: RuntimeConnectivity) : BindingEvent
}

private fun List<RegistrarStopFailure>.toStopResult(): RegistrarStopResult =
    if (isEmpty()) RegistrarStopResult.Success else RegistrarStopResult.Failure(toList())

private fun RegistrarFailure.recoverable(): Boolean = when (this) {
    is RegistrarFailure.CredentialStorage -> error.recoverable
    is RegistrarFailure.AccessToken -> recoverable
    is RegistrarFailure.Sentinel -> recoverable
    is RegistrarFailure.Messaging -> recoverable
    else -> false
}

private fun RuntimeCreateResult.asRuntimeResult(): RuntimeResult<RegistrarRuntime> = when (this) {
    is RuntimeCreateResult.Success -> RuntimeResult.Success(runtime)
    is RuntimeCreateResult.Failure -> RuntimeResult.Failure(failure)
}

private enum class HeartbeatResult { HEALTHY, RECONNECTED, TERMINAL }

private val RuntimeSetupProgress.stage: RegistrarStage get() = when (this) {
    RuntimeSetupProgress.ACQUIRING_ACCESS_TOKEN -> RegistrarStage.ACCESS_TOKEN
    RuntimeSetupProgress.ACQUIRING_SENTINEL_CREDENTIALS -> RegistrarStage.SENTINEL
    RuntimeSetupProgress.CONNECTING -> RegistrarStage.CONNECTING
}

private fun RegistrarFailure.runtimeCreateStage(fallback: RegistrarStage): RegistrarStage = when (this) {
    is RegistrarFailure.AccessToken -> RegistrarStage.ACCESS_TOKEN
    is RegistrarFailure.Sentinel -> RegistrarStage.SENTINEL
    else -> fallback
}

private suspend fun withinBudget(deadline: TimeSource.Monotonic.ValueTimeMark?, block: suspend () -> Unit): Boolean {
    if (deadline == null) { block(); return true }
    val remaining = -deadline.elapsedNow()
    if (remaining.isNegative() || remaining == kotlin.time.Duration.ZERO) return false
    return withTimeoutOrNull(remaining) { block(); true } ?: false
}
