package com.typewritermc.services.libs.registrar

import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpan
import com.typewritermc.services.libs.utils.DelayScheduler
import com.typewritermc.services.libs.utils.RetryPolicy
import com.typewritermc.services.libs.utils.findExceptionalThrowable
import io.opentelemetry.api.common.Attributes
import io.opentelemetry.context.Context
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.async
import kotlinx.coroutines.cancelAndJoin
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.channels.awaitClose
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.channelFlow
import kotlinx.coroutines.flow.collect
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.flow.mapNotNull
import kotlinx.coroutines.flow.merge
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.launch
import kotlinx.coroutines.selects.select
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.random.Random
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/**
 * Supervises durable identity, organization binding, messaging generations, and recovery for one service.
 *
 * A command loop owns lifecycle state while the coordinator performs setup and ready supervision. Ambiguous
 * identity issuance is surfaced explicitly. The supplied scope must remain active while callers issue commands;
 * stop before cancelling it. Shutdown uses one bounded budget and reports cleanup failures.
 */
class ServiceRegistrar(
    private val configuration: RegistrarConfiguration,
    private val scope: CoroutineScope,
    private val credentialStorage: CredentialStorage,
    private val identityIssuer: IdentityIssuer,
    private val runtimeFactory: RegistrarRuntimeFactory,
    private val telemetry: ServiceTelemetry,
    private val retryPolicy: RetryPolicy,
    private val delayScheduler: DelayScheduler,
    private val timeSource: TimeSource,
    private val retryRandom: RetryRandom = RetryRandom { Random.nextDouble() },
) {
    private val commands = Channel<RegistrarCommand>(Channel.UNLIMITED)
    private val reauthorizationRequests = Channel<ReauthorizationRequest>(Channel.UNLIMITED)
    private val mutableStates = MutableStateFlow(RegistrarSnapshot(0, 0, RegistrarState.Idle))
    private var coordinator: Job? = null
    private var runtime: RegistrarRuntime? = null
    private var retainedIssuedCredentials: IdentityCredentials? = null
    private var activeCredentials: IdentityCredentials? = null
    private var stopResult: RegistrarStopResult? = null
    private val retiredRuntimes = mutableMapOf<Long, RegistrarRuntime>()

    private var lifecycleState = LifecycleState.IDLE
    private var attempt = 0L

    init {
        scope.launch { commandLoop() }
    }

    val states: StateFlow<RegistrarSnapshot> = mutableStates

    /**
     * Requests startup without waiting for organization readiness.
     *
     * Use [awaitReady] for the ready session or an explicit failure. A stopped registrar cannot be restarted.
     */
    suspend fun start(): RegistrarResult<Unit> = request { RegistrarCommand.Start(Context.current(), it) }

    suspend fun retry(): RegistrarResult<Unit> = request { RegistrarCommand.Retry(Context.current(), it) }

    /**
     * Waits for Ready, explicit failure, ambiguous identity outcome, or Stopped.
     *
     * There is no local deadline; callers may cancel or provide a timeout. A successful result does not pin the
     * connection generation.
     */
    suspend fun awaitReady(): RegistrarResult<ReadySession> {
        val terminal =
            states
                .first {
                    it.state is RegistrarState.Ready || it.state.isExplicitFailure() || it.state is RegistrarState.Stopped
                }.state
        return when (terminal) {
            is RegistrarState.Ready -> RegistrarResult.Success(terminal.session)
            is RegistrarState.Failed -> RegistrarResult.Failure(terminal.failure)
            is RegistrarState.IdentityOutcomeUnknown -> RegistrarResult.Failure(terminal.failure)
            is RegistrarState.Stopped -> RegistrarResult.Failure(RegistrarFailure.Internal("registrar_stopped"))
            else -> error("terminal predicate violated")
        }
    }

    /**
     * Borrows a communicator only when the requested generation is currently ready.
     *
     * Use the generation observed in [RegistrarState.Ready] to avoid accidentally binding work to a replacement
     * session.
     */
    suspend fun communicatorFor(connectionGeneration: Long): RegistrarResult<Communicator> =
        request { RegistrarCommand.CommunicatorFor(connectionGeneration, it) }

    /**
     * Requests a fresh authorized runtime while retaining prior runtime resources for handover.
     *
     * After dependent routes switch to the returned generation, release the retained runtime through
     * [releaseAuthorizationRotation].
     */
    suspend fun rotateAuthorization(): RegistrarResult<Long> {
        val response = CompletableDeferred<RegistrarResult<Long>>()
        reauthorizationRequests.send(ReauthorizationRequest(Context.current(), response))
        return response.await()
    }

    /**
     * Closes the runtime retained for the completed authorization handover.
     *
     * Repeated release of an already absent retained generation succeeds. Release only after consumers have
     * replaced old routes and subscriptions.
     */
    suspend fun releaseAuthorizationRotation(connectionGeneration: Long): RegistrarResult<Unit> =
        request { RegistrarCommand.ReleaseAuthorizationRotation(connectionGeneration, it) }

    suspend fun stop(): RegistrarStopResult = request { RegistrarCommand.Stop(it) }

    private suspend fun commandLoop() {
        for (command in commands) {
            when (command) {
                is RegistrarCommand.Start -> {
                    command.response.complete(startOwned(command.parent))
                }

                is RegistrarCommand.Retry -> {
                    command.response.complete(retryOwned(command.parent))
                }

                is RegistrarCommand.Stop -> {
                    command.response.complete(stopOwned())
                }

                is RegistrarCommand.CommunicatorFor -> {
                    command.response.complete(communicatorForOwned(command.connectionGeneration))
                }

                is RegistrarCommand.ReleaseAuthorizationRotation -> {
                    command.response.complete(releaseAuthorizationRotationOwned(command.connectionGeneration))
                }

                is RegistrarCommand.Transition -> {
                    transitionOwned(command.state, command.events)
                    command.response?.complete(Unit)
                }

                is RegistrarCommand.NextAttempt -> {
                    attempt = saturatingIncrement(attempt)
                    command.response.complete(attempt)
                }

                is RegistrarCommand.CurrentAttempt -> {
                    command.response.complete(attempt)
                }
            }
        }
    }

    private fun startOwned(parent: Context): RegistrarResult<Unit> =
        when (lifecycleState) {
            LifecycleState.IDLE -> {
                lifecycleState = LifecycleState.ACTIVE
                coordinator = scope.launch { coordinate(parent) }
                RegistrarResult.Success(Unit)
            }

            LifecycleState.STOPPED -> {
                RegistrarResult.Failure(RegistrarFailure.Internal("registrar_stopped"))
            }

            LifecycleState.ACTIVE -> {
                RegistrarResult.Success(Unit)
            }
        }

    private suspend fun retryOwned(parent: Context): RegistrarResult<Unit> {
        if (lifecycleState == LifecycleState.STOPPED) {
            return RegistrarResult.Failure(RegistrarFailure.Internal("registrar_stopped"))
        }
        if (lifecycleState != LifecycleState.ACTIVE || !mutableStates.value.state.isExplicitFailure()) {
            return RegistrarResult.Failure(RegistrarFailure.Internal("retry_not_failed"))
        }
        coordinator?.join()
        if (lifecycleState == LifecycleState.STOPPED || !mutableStates.value.state.isExplicitFailure()) {
            return RegistrarResult.Failure(RegistrarFailure.Internal("retry_not_failed"))
        }
        attempt = saturatingIncrement(attempt)
        coordinator = scope.launch { coordinate(parent) }
        return RegistrarResult.Success(Unit)
    }

    private fun communicatorForOwned(connectionGeneration: Long): RegistrarResult<Communicator> {
        val ready = mutableStates.value.state as? RegistrarState.Ready
        if (ready?.connectionGeneration != connectionGeneration) {
            return RegistrarResult.Failure(RegistrarFailure.Internal("ready_generation_changed"))
        }
        val communicator =
            runtime?.communicator
                ?: return RegistrarResult.Failure(RegistrarFailure.Internal("ready_runtime_unavailable"))
        return RegistrarResult.Success(communicator)
    }

    private suspend fun releaseAuthorizationRotationOwned(connectionGeneration: Long): RegistrarResult<Unit> {
        val retired = retiredRuntimes[connectionGeneration] ?: return RegistrarResult.Success(Unit)
        return when (val result = retired.close()) {
            RuntimeCloseResult.Success -> {
                retiredRuntimes.remove(connectionGeneration)
                RegistrarResult.Success(Unit)
            }

            is RuntimeCloseResult.Failure -> {
                RegistrarResult.Failure(RegistrarFailure.Internal("authorization_rotation_cleanup_failed"))
            }
        }
    }

    private suspend fun stopOwned(): RegistrarStopResult =
        telemetry.mainSpan(
            "registrar.stop",
            ErrorSlug.of("registrar-stop-failed"),
            parent = Context.root(),
        ) { main ->
            stopResult?.let { return@mainSpan it }
            lifecycleState = LifecycleState.STOPPED
            coordinator?.cancel()
            withContext(NonCancellable) {
                transitionOwned(RegistrarState.Stopping, main)
                val deadline = timeSource.markNow() + configuration.shutdownTimeout
                val failures = mutableListOf<RegistrarStopFailure>()
                if (!withinBudget(deadline) { coordinator?.join() }) {
                    failures += RegistrarStopFailure.Runtime(RuntimeStopOperation.COORDINATOR_TIMEOUT)
                }
                coordinator = null
                try {
                    failures += cleanup(runtime, sendShutdown = true, deadline = deadline)
                    retiredRuntimes.values.forEach { retired ->
                        failures += cleanup(retired, sendShutdown = false, deadline = deadline)
                    }
                } finally {
                    runtime = null
                    retiredRuntimes.clear()
                    retainedIssuedCredentials = null
                    activeCredentials = null
                }
                val result = failures.toStopResult()
                stopResult = result
                transitionOwned(RegistrarState.Stopped(result), main)
                result
            }
        }

    private suspend fun <Value> request(command: (CompletableDeferred<Value>) -> RegistrarCommand): Value {
        val response = CompletableDeferred<Value>()
        commands.send(command(response))
        return response.await()
    }

    private suspend fun coordinate(parent: Context) {
        try {
            runAttempt(parent)
            if (mutableStates.value.state.isExplicitFailure()) {
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
            val cleanupExceptional = cleanupFailure?.let(::findExceptionalThrowable)
            val primary = originalExceptional ?: cleanupExceptional ?: failure
            sequenceOf(originalExceptional, cleanupExceptional)
                .filterNotNull()
                .filter { it !== primary }
                .forEach(primary::addSuppressed)
            throw primary
        }
    }

    private suspend fun runAttempt(parent: Context) {
        val currentAttempt = currentAttempt()
        val ready =
            telemetry.mainSpan(
                "registrar.attempt",
                ErrorSlug.of("registrar-attempt-failed"),
                parent = parent,
                attributes = Attributes.builder().put("registrar.attempt", currentAttempt).build(),
            ) { main ->
                val result = establishReady(main)
                main.annotate {
                    domainOutcome(if (result == null) mutableStates.value.state.attemptOutcome() else "ready")
                }
                result
            } ?: return
        superviseReady(ready)
    }

    private suspend fun establishReady(events: MainSpanScope): ReadySupervision? {
        val acquired = acquireCredentials(events) ?: return null
        activeCredentials = acquired
        var setupStage = RegistrarStage.CONNECTING
        val created =
            retryPhase({ failure -> failure.runtimeCreateStage(setupStage) }, events) {
                runtimeFactory
                    .create(
                        acquired,
                        RuntimeSetupProgressSink {
                            setupProgress(it, events)
                            setupStage = it.stage
                        },
                    ).asRuntimeResult()
            } ?: return null
        runtime = created
        if (retryPhase(RegistrarStage.CONNECTING, events = events) { created.connect() } == null) return null
        awaitConnected(created, events = events)
        while (true) {
            val binding = superviseBinding(created, acquired.identity, events) ?: return null
            transition(RegistrarState.Reauthorizing(binding), events)
            val reauthorized =
                retryPhase(RegistrarStage.REAUTHORIZING, events = events) {
                    created.reconnectForBoundPermissions()
                }
            if (reauthorized == null) return null
            when (val confirmed = retryPhase(RegistrarStage.BINDING, events = events) { created.queryBinding() } ?: return null) {
                is BindingStatus.Bound -> {
                    return beginReadySupervision(created, acquired.identity, confirmed.binding, events)
                }

                is BindingStatus.Unbound -> {
                    transition(RegistrarState.AwaitingBinding(acquired.identity, confirmed.token), events)
                }
            }
        }
    }

    private suspend fun beginReadySupervision(
        active: RegistrarRuntime,
        identity: ServiceIdentity,
        binding: OrganizationBinding,
        events: MainSpanScope,
    ): ReadySupervision? {
        val session = ReadySession(identity, binding)
        val generation =
            when (restoreHeartbeat(active, session, events)) {
                HeartbeatResult.TERMINAL -> return null
                HeartbeatResult.RECONNECTED -> 2L
                HeartbeatResult.HEALTHY -> 1L
            }
        transition(RegistrarState.Ready(session, generation), events)
        return ReadySupervision(active, session, generation)
    }

    private fun setupProgress(
        progress: RuntimeSetupProgress,
        events: MainSpanScope,
    ) {
        when (progress) {
            RuntimeSetupProgress.ACQUIRING_ACCESS_TOKEN -> {
                activeCredentials?.identity?.let {
                    queueTransition(RegistrarState.AcquiringAccessToken(it), events)
                }
            }

            RuntimeSetupProgress.ACQUIRING_SENTINEL_CREDENTIALS -> {
                queueTransition(RegistrarState.AcquiringSentinelCredentials, events)
            }

            RuntimeSetupProgress.CONNECTING -> {
                queueTransition(RegistrarState.Connecting(mutableStates.value.attempt), events)
            }
        }
    }

    private suspend fun acquireCredentials(events: MainSpanScope): IdentityCredentials? {
        retainedIssuedCredentials?.let { return persist(it, events) }
        transition(RegistrarState.LoadingIdentity, events)
        var backoffIndex = 0L
        while (true) {
            when (val loaded = credentialStorage.load()) {
                CredentialLoadResult.Missing -> {
                    break
                }

                is CredentialLoadResult.Loaded -> {
                    return loaded.credentials
                }

                is CredentialLoadResult.Failure -> {
                    val failure = RegistrarFailure.CredentialStorage(loaded.error)
                    if (!loaded.error.recoverable) {
                        terminal(failure, events)
                        return null
                    }
                    retryDelay(
                        RegistrarStage.STORAGE,
                        failure,
                        backoffIndex =
                            backoffIndex.also {
                                backoffIndex =
                                    saturatingIncrement(backoffIndex)
                            },
                        events = events,
                    )
                }
            }
        }
        transition(RegistrarState.IssuingIdentity, events)
        return when (val issued = identityIssuer.issue(configuration.role)) {
            is IdentityIssueResult.Failure -> {
                val failure = RegistrarFailure.IdentityIssuance(issued.error)
                val state =
                    if (issued.error.outcomeMayBeAmbiguous) {
                        RegistrarState.IdentityOutcomeUnknown(failure)
                    } else {
                        RegistrarState.Failed(failure)
                    }
                transition(state, events)
                null
            }

            is IdentityIssueResult.Success -> {
                retainedIssuedCredentials = issued.credentials
                persist(issued.credentials, events)
            }
        }
    }

    private suspend fun persist(
        value: IdentityCredentials,
        events: MainSpanScope,
    ): IdentityCredentials? {
        transition(RegistrarState.PersistingIdentity(value.identity), events)
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
                        terminal(failure, events)
                        return null
                    }
                    retryDelay(
                        RegistrarStage.STORAGE,
                        failure,
                        backoffIndex =
                            backoffIndex.also {
                                backoffIndex =
                                    saturatingIncrement(backoffIndex)
                            },
                        events = events,
                    )
                }
            }
        }
    }

    private suspend fun superviseBinding(
        active: RegistrarRuntime,
        identity: ServiceIdentity,
        events: MainSpanScope,
    ): OrganizationBinding? {
        var bindingBackoffIndex = 0L
        while (true) {
            awaitConnected(active, events = events)
            val event =
                awaitBindingEvent(active) { status ->
                    bindingBackoffIndex = 0L
                    transition(RegistrarState.AwaitingBinding(identity, status.token), events)
                }
            when (event) {
                null -> {
                    when (val queried = active.queryBinding()) {
                        is RuntimeResult.Success -> {
                            when (val status = queried.value) {
                                is BindingStatus.Bound -> {
                                    return status.binding
                                }

                                is BindingStatus.Unbound -> {
                                    bindingBackoffIndex = 0L
                                    transition(RegistrarState.AwaitingBinding(identity, status.token), events)
                                }
                            }
                        }

                        is RuntimeResult.Failure -> {
                            if (!handleFailure(
                                    RegistrarStage.BINDING,
                                    queried.failure,
                                    bindingBackoffIndex.also {
                                        bindingBackoffIndex =
                                            saturatingIncrement(bindingBackoffIndex)
                                    },
                                    events,
                                )
                            ) {
                                return null
                            }
                        }
                    }
                }

                is BindingEvent.Connectivity -> {
                    awaitConnected(active, events = events)
                }

                is BindingEvent.Observation -> {
                    when (val result = event.value) {
                        is RuntimeResult.Failure -> {
                            if (!handleFailure(
                                    RegistrarStage.BINDING,
                                    result.failure,
                                    bindingBackoffIndex.also {
                                        bindingBackoffIndex =
                                            saturatingIncrement(bindingBackoffIndex)
                                    },
                                    events,
                                )
                            ) {
                                return null
                            }
                        }

                        is RuntimeResult.Success -> {
                            when (val observation = result.value) {
                                is BindingObservation.Bound -> {
                                    return observation.binding
                                }

                                is BindingObservation.Initial -> {
                                    when (val status = observation.status) {
                                        is BindingStatus.Bound -> {
                                            return status.binding
                                        }

                                        is BindingStatus.Unbound -> {
                                            bindingBackoffIndex = 0L
                                            transition(RegistrarState.AwaitingBinding(identity, status.token), events)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    private suspend fun awaitBindingEvent(
        active: RegistrarRuntime,
        onInitialUnbound: suspend (BindingStatus.Unbound) -> Unit,
    ): BindingEvent? =
        withTimeoutOrNull(configuration.bindingRefreshInterval) {
            merge(
                active.watchBinding().map { BindingEvent.Observation(it) },
                active.connectivity.map { BindingEvent.Connectivity(it) },
            ).mapNotNull { event ->
                when (event) {
                    is BindingEvent.Connectivity -> {
                        event.takeIf { it.value != RuntimeConnectivity.CONNECTED }
                    }

                    is BindingEvent.Observation -> {
                        when (val result = event.value) {
                            is RuntimeResult.Failure -> {
                                event
                            }

                            is RuntimeResult.Success -> {
                                when (val observation = result.value) {
                                    is BindingObservation.Bound -> {
                                        event
                                    }

                                    is BindingObservation.Initial -> {
                                        when (val status = observation.status) {
                                            is BindingStatus.Bound -> {
                                                event
                                            }

                                            is BindingStatus.Unbound -> {
                                                onInitialUnbound(status)
                                                null
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }.first()
        }

    private suspend fun superviseReady(supervision: ReadySupervision) {
        var current = supervision
        while (true) {
            val event = awaitReadyEvent(current.runtime)
            when (event) {
                ReadyEvent.Heartbeat -> {
                    val generation = heartbeat(current.runtime, current.session, current.connectionGeneration) ?: return
                    current = current.copy(connectionGeneration = generation)
                }

                ReadyEvent.Degraded -> {
                    val generation = recoverReady(current.runtime, current.session, current.connectionGeneration) ?: return
                    current = current.copy(connectionGeneration = generation)
                }

                is ReadyEvent.Reauthorize -> {
                    current = rotateReadyRuntime(current, event.request) ?: current
                }
            }
        }
    }

    private suspend fun awaitReadyEvent(active: RegistrarRuntime): ReadyEvent =
        coroutineScope {
            val degraded = async { active.connectivity.first { it != RuntimeConnectivity.CONNECTED } }
            val requested = async { reauthorizationRequests.receive() }
            val event: ReadyEvent =
                withTimeoutOrNull<ReadyEvent>(configuration.heartbeatInterval) {
                    select<ReadyEvent> {
                        degraded.onAwait { ReadyEvent.Degraded }
                        requested.onAwait { ReadyEvent.Reauthorize(it) }
                    }
                } ?: ReadyEvent.Heartbeat
            degraded.cancel()
            requested.cancel()
            event
        }

    private suspend fun rotateReadyRuntime(
        current: ReadySupervision,
        request: ReauthorizationRequest,
    ): ReadySupervision? =
        telemetry.mainSpan(
            "artifact.authorization.rotate",
            ErrorSlug.of("registrar-authorization-rotate-failed"),
            parent = request.parent,
            attributes = readyAttributes(current.session, current.connectionGeneration),
        ) { main ->
            transition(RegistrarState.Reauthorizing(current.session.binding), main)
            val credentials = activeCredentials
            if (credentials == null) {
                transition(RegistrarState.Ready(current.session, current.connectionGeneration), main)
                request.response.complete(RegistrarResult.Failure(RegistrarFailure.Internal("active_credentials_unavailable")))
                return@mainSpan null
            }
            val created =
                when (val result = runtimeFactory.create(credentials, RuntimeSetupProgressSink {})) {
                    is RuntimeCreateResult.Success -> {
                        result.runtime
                    }

                    is RuntimeCreateResult.Failure -> {
                        transition(RegistrarState.Ready(current.session, current.connectionGeneration), main)
                        request.response.complete(RegistrarResult.Failure(result.failure))
                        return@mainSpan null
                    }
                }
            val failure = establishReplacement(created, current.session)
            if (failure != null) {
                created.close()
                transition(RegistrarState.Ready(current.session, current.connectionGeneration), main)
                request.response.complete(RegistrarResult.Failure(failure))
                return@mainSpan null
            }
            val nextGeneration = saturatingIncrement(current.connectionGeneration)
            retiredRuntimes[nextGeneration] = current.runtime
            runtime = created
            transition(RegistrarState.Ready(current.session, nextGeneration), main)
            request.response.complete(RegistrarResult.Success(nextGeneration))
            ReadySupervision(created, current.session, nextGeneration)
        }

    private suspend fun establishReplacement(
        replacement: RegistrarRuntime,
        expectedSession: ReadySession,
    ): RegistrarFailure? {
        when (val connected = replacement.connect()) {
            is RuntimeResult.Failure -> return connected.failure
            is RuntimeResult.Success -> Unit
        }
        replacement.connectivity.first { it == RuntimeConnectivity.CONNECTED }
        when (val binding = replacement.queryBinding()) {
            is RuntimeResult.Failure -> {
                return binding.failure
            }

            is RuntimeResult.Success -> {
                val actual =
                    binding.value as? BindingStatus.Bound
                        ?: return RegistrarFailure.Internal("authorization_rotation_unbound")
                if (actual.binding != expectedSession.binding) {
                    return RegistrarFailure.Internal("authorization_rotation_binding_changed")
                }
            }
        }
        return when (val heartbeat = replacement.sendHeartbeat()) {
            is RuntimeResult.Failure -> heartbeat.failure
            is RuntimeResult.Success -> null
        }
    }

    private suspend fun heartbeat(
        active: RegistrarRuntime,
        session: ReadySession,
        generation: Long,
    ): Long? =
        telemetry.mainSpan(
            "registrar.heartbeat",
            ErrorSlug.of("registrar-heartbeat-failed"),
            parent = Context.root(),
            attributes = readyAttributes(session, generation),
        ) { main ->
            val nextGeneration =
                when (restoreHeartbeat(active, session, main)) {
                    HeartbeatResult.TERMINAL -> {
                        main.annotate { domainOutcome("terminal") }
                        null
                    }

                    HeartbeatResult.RECONNECTED -> {
                        main.annotate { domainOutcome("reconnected") }
                        saturatingIncrement(generation)
                    }

                    HeartbeatResult.HEALTHY -> {
                        main.annotate { domainOutcome("healthy") }
                        generation
                    }
                }
            nextGeneration?.also { transition(RegistrarState.Ready(session, it), main) }
        }

    private suspend fun recoverReady(
        active: RegistrarRuntime,
        session: ReadySession,
        generation: Long,
    ): Long? =
        telemetry.mainSpan(
            "registrar.recovery",
            ErrorSlug.of("registrar-recovery-failed"),
            parent = Context.root(),
            attributes = readyAttributes(session, generation),
        ) { main ->
            awaitConnected(active, session, main)
            val heartbeatGeneration =
                when (restoreHeartbeat(active, session, main)) {
                    HeartbeatResult.TERMINAL -> {
                        main.annotate { domainOutcome("terminal") }
                        return@mainSpan null
                    }

                    HeartbeatResult.RECONNECTED -> {
                        saturatingIncrement(generation)
                    }

                    HeartbeatResult.HEALTHY -> {
                        generation
                    }
                }
            main.annotate { domainOutcome("recovered") }
            saturatingIncrement(heartbeatGeneration).also {
                transition(RegistrarState.Ready(session, it), main)
            }
        }

    private suspend fun restoreHeartbeat(
        active: RegistrarRuntime,
        session: ReadySession,
        events: MainSpanScope,
    ): HeartbeatResult {
        var backoffIndex = 0L
        var reconnected = false
        while (true) {
            when (val heartbeat = active.sendHeartbeat()) {
                is RuntimeResult.Success -> {
                    return if (reconnected) HeartbeatResult.RECONNECTED else HeartbeatResult.HEALTHY
                }

                is RuntimeResult.Failure -> {
                    if (!heartbeat.failure.recoverable()) {
                        terminal(heartbeat.failure, events)
                        return HeartbeatResult.TERMINAL
                    }
                    retryDelay(
                        RegistrarStage.HEARTBEAT,
                        heartbeat.failure,
                        session,
                        backoffIndex.also {
                            backoffIndex =
                                saturatingIncrement(backoffIndex)
                        },
                        events,
                    )
                    if (retryPhase(RegistrarStage.REAUTHORIZING, events = events) {
                            active.reconnectForBoundPermissions()
                        } == null
                    ) {
                        return HeartbeatResult.TERMINAL
                    }
                    awaitConnected(active, session, events)
                    reconnected = true
                }
            }
        }
    }

    private suspend fun awaitConnected(
        active: RegistrarRuntime,
        session: ReadySession? = null,
        events: MainSpanScope,
    ) {
        if (active.currentConnectivity == RuntimeConnectivity.CONNECTED) return
        retryDelay(
            RegistrarStage.CONNECTING,
            RegistrarFailure.Messaging(MessagingOperation.CONNECTIVITY),
            session,
            0,
            events,
        )
        active.connectivity.first { it == RuntimeConnectivity.CONNECTED }
    }

    private suspend fun <V> retryPhase(
        stage: RegistrarStage,
        events: MainSpanScope,
        operation: suspend () -> RuntimeResult<V>,
    ): V? = retryPhase({ stage }, events, operation)

    private suspend fun <V> retryPhase(
        stage: (RegistrarFailure) -> RegistrarStage,
        events: MainSpanScope,
        operation: suspend () -> RuntimeResult<V>,
    ): V? {
        var backoffIndex = 0L
        while (true) {
            when (val result = operation()) {
                is RuntimeResult.Success -> {
                    return result.value
                }

                is RuntimeResult.Failure -> {
                    if (!handleFailure(
                            stage(result.failure),
                            result.failure,
                            backoffIndex.also {
                                backoffIndex =
                                    saturatingIncrement(backoffIndex)
                            },
                            events,
                        )
                    ) {
                        return null
                    }
                }
            }
        }
    }

    private suspend fun handleFailure(
        stage: RegistrarStage,
        failure: RegistrarFailure,
        backoffIndex: Long,
        events: MainSpanScope,
    ): Boolean {
        if (!failure.recoverable()) {
            terminal(failure, events)
            return false
        }
        retryDelay(stage, failure, backoffIndex = backoffIndex, events = events)
        return true
    }

    private suspend fun retryDelay(
        stage: RegistrarStage,
        failure: RegistrarFailure,
        session: ReadySession? = null,
        backoffIndex: Long,
        events: MainSpanScope,
    ) {
        val retryAttempt = nextAttempt()
        val duration = retryPolicy.delayFor(backoffIndex, retryRandom.normalizedSample())
        val retry = RetrySchedule(retryAttempt, duration)
        val state =
            if (session == null) {
                RegistrarState.DegradedBeforeReady(stage, failure, retry)
            } else {
                RegistrarState.DegradedAfterReady(session, stage, failure, retry)
            }
        transition(state, events)
        delayScheduler.delay(duration)
    }

    private suspend fun cleanupCurrentAttempt() {
        try {
            cleanup(runtime, sendShutdown = false, deadline = null)
        } finally {
            runtime = null
            activeCredentials = null
        }
    }

    private suspend fun cleanup(
        active: RegistrarRuntime?,
        sendShutdown: Boolean,
        deadline: TimeMark?,
    ): List<RegistrarStopFailure> {
        if (active == null) return emptyList()
        val failures = mutableListOf<RegistrarStopFailure>()
        var exceptional: Throwable? = null
        if (sendShutdown && active.currentConnectivity == RuntimeConnectivity.CONNECTED) {
            try {
                var shutdown: RuntimeResult<Unit>? = null
                if (!withinBudget(deadline) { shutdown = active.sendShutdown() }) {
                    failures +=
                        RegistrarStopFailure.Runtime(RuntimeStopOperation.SHUTDOWN_TIMEOUT)
                } else {
                    when (shutdown) {
                        is RuntimeResult.Failure -> failures += RegistrarStopFailure.Runtime(RuntimeStopOperation.SHUTDOWN_FAILED)
                        is RuntimeResult.Success -> Unit
                        null -> error("completed shutdown has no result")
                    }
                }
            } catch (thrown: Throwable) {
                val found = findExceptionalThrowable(thrown)
                if (found == null) {
                    failures += RegistrarStopFailure.Runtime(RuntimeStopOperation.SHUTDOWN_THROWN)
                } else {
                    exceptional = combineExceptional(exceptional, found)
                }
            }
        }
        try {
            var close: RuntimeCloseResult? = null
            if (!withinBudget(deadline) { close = active.close() }) {
                failures +=
                    RegistrarStopFailure.Runtime(RuntimeStopOperation.CLOSE_TIMEOUT)
            } else {
                when (val result = close) {
                    is RuntimeCloseResult.Failure -> failures += result.failures
                    RuntimeCloseResult.Success -> Unit
                    null -> error("completed close has no result")
                }
            }
        } catch (thrown: Throwable) {
            val found = findExceptionalThrowable(thrown)
            if (found == null) {
                failures += RegistrarStopFailure.Runtime(RuntimeStopOperation.CLOSE_THROWN)
            } else {
                exceptional = combineExceptional(exceptional, found)
            }
        }
        exceptional?.let { throw it }
        return failures
    }

    private suspend fun terminal(
        failure: RegistrarFailure,
        events: MainSpanScope? = null,
    ) = transition(RegistrarState.Failed(failure), events)

    private suspend fun transition(
        state: RegistrarState,
        events: MainSpanScope? = null,
    ) = request<Unit> { RegistrarCommand.Transition(state, events, it) }

    private fun queueTransition(
        state: RegistrarState,
        events: MainSpanScope,
    ) {
        check(commands.trySend(RegistrarCommand.Transition(state, events, null)).isSuccess)
    }

    private fun transitionOwned(
        state: RegistrarState,
        events: MainSpanScope? = null,
    ) {
        var previousState: RegistrarState? = null
        var currentSnapshot: RegistrarSnapshot? = null
        mutableStates.update { previous ->
            previousState = previous.state
            RegistrarSnapshot(previous.sequence + 1, attempt, state).also { currentSnapshot = it }
        }
        events?.recordRegistrarStateChanged(checkNotNull(previousState), checkNotNull(currentSnapshot))
    }

    private suspend fun nextAttempt(): Long = request { RegistrarCommand.NextAttempt(it) }

    private suspend fun currentAttempt(): Long = request { RegistrarCommand.CurrentAttempt(it) }
}

private enum class LifecycleState { IDLE, ACTIVE, STOPPED }

private sealed interface RegistrarCommand {
    data class Start(
        val parent: Context,
        val response: CompletableDeferred<RegistrarResult<Unit>>,
    ) : RegistrarCommand

    data class Retry(
        val parent: Context,
        val response: CompletableDeferred<RegistrarResult<Unit>>,
    ) : RegistrarCommand

    data class Stop(
        val response: CompletableDeferred<RegistrarStopResult>,
    ) : RegistrarCommand

    data class CommunicatorFor(
        val connectionGeneration: Long,
        val response: CompletableDeferred<RegistrarResult<Communicator>>,
    ) : RegistrarCommand

    data class ReleaseAuthorizationRotation(
        val connectionGeneration: Long,
        val response: CompletableDeferred<RegistrarResult<Unit>>,
    ) : RegistrarCommand

    data class Transition(
        val state: RegistrarState,
        val events: MainSpanScope?,
        val response: CompletableDeferred<Unit>?,
    ) : RegistrarCommand

    data class NextAttempt(
        val response: CompletableDeferred<Long>,
    ) : RegistrarCommand

    data class CurrentAttempt(
        val response: CompletableDeferred<Long>,
    ) : RegistrarCommand
}

private data class ReauthorizationRequest(
    val parent: Context,
    val response: CompletableDeferred<RegistrarResult<Long>>,
)

private sealed interface ReadyEvent {
    data object Heartbeat : ReadyEvent

    data object Degraded : ReadyEvent

    data class Reauthorize(
        val request: ReauthorizationRequest,
    ) : ReadyEvent
}

private data class ReadySupervision(
    val runtime: RegistrarRuntime,
    val session: ReadySession,
    val connectionGeneration: Long,
)

private fun RegistrarState.attemptOutcome(): String =
    when (this) {
        is RegistrarState.Failed -> "failed"
        is RegistrarState.IdentityOutcomeUnknown -> "identity_outcome_unknown"
        is RegistrarState.Stopped -> "stopped"
        else -> "incomplete"
    }

private fun RegistrarState.isExplicitFailure(): Boolean = this is RegistrarState.Failed || this is RegistrarState.IdentityOutcomeUnknown

private fun readyAttributes(
    session: ReadySession,
    generation: Long,
): Attributes =
    Attributes
        .builder()
        .put("service.id", session.identity.serviceId)
        .put("user.org.id", session.binding.organizationId)
        .put("registrar.connection.generation", generation)
        .build()

private fun saturatingIncrement(value: Long): Long = if (value == Long.MAX_VALUE) value else value + 1

private fun combineExceptional(
    primary: Throwable?,
    additional: Throwable,
): Throwable {
    if (primary == null) return additional
    if (primary !== additional) primary.addSuppressed(additional)
    return primary
}

private sealed interface BindingEvent {
    data class Observation(
        val value: RuntimeResult<BindingObservation>,
    ) : BindingEvent

    data class Connectivity(
        val value: RuntimeConnectivity,
    ) : BindingEvent
}

private fun List<RegistrarStopFailure>.toStopResult(): RegistrarStopResult =
    if (isEmpty()) RegistrarStopResult.Success else RegistrarStopResult.Failure(toList())

private fun RegistrarFailure.recoverable(): Boolean =
    when (this) {
        is RegistrarFailure.CredentialStorage -> error.recoverable
        is RegistrarFailure.AccessToken -> recoverable
        is RegistrarFailure.Sentinel -> recoverable
        is RegistrarFailure.Messaging -> recoverable
        else -> false
    }

private fun RuntimeCreateResult.asRuntimeResult(): RuntimeResult<RegistrarRuntime> =
    when (this) {
        is RuntimeCreateResult.Success -> RuntimeResult.Success(runtime)
        is RuntimeCreateResult.Failure -> RuntimeResult.Failure(failure)
    }

private enum class HeartbeatResult { HEALTHY, RECONNECTED, TERMINAL }

private val RuntimeSetupProgress.stage: RegistrarStage get() =
    when (this) {
        RuntimeSetupProgress.ACQUIRING_ACCESS_TOKEN -> RegistrarStage.ACCESS_TOKEN
        RuntimeSetupProgress.ACQUIRING_SENTINEL_CREDENTIALS -> RegistrarStage.SENTINEL
        RuntimeSetupProgress.CONNECTING -> RegistrarStage.CONNECTING
    }

private fun RegistrarFailure.runtimeCreateStage(fallback: RegistrarStage): RegistrarStage =
    when (this) {
        is RegistrarFailure.AccessToken -> RegistrarStage.ACCESS_TOKEN
        is RegistrarFailure.Sentinel -> RegistrarStage.SENTINEL
        else -> fallback
    }

private suspend fun withinBudget(
    deadline: TimeMark?,
    block: suspend () -> Unit,
): Boolean {
    if (deadline == null) {
        block()
        return true
    }
    val remaining = -deadline.elapsedNow()
    if (remaining.isNegative() || remaining == kotlin.time.Duration.ZERO) return false
    return withTimeoutOrNull(remaining) {
        block()
        true
    } ?: false
}
