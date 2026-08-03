package com.typewritermc.services.libs.communicator.router

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponseOutcome
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.contract.WatchContract
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.telemetry.MessageHeadersGetter
import com.typewritermc.services.libs.communicator.transport.ConsumerGroup
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.communicator.transport.SubscriptionOptions
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.communicator.transport.TransportSubscription
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.SluggedException
import com.typewritermc.services.libs.telemetry.consumerSpan
import io.opentelemetry.api.common.Attributes
import io.opentelemetry.context.Context
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.async
import kotlinx.coroutines.channels.Channel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.isActive
import kotlinx.coroutines.joinAll
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.Semaphore
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.seconds
import com.typewritermc.services.libs.utils.findExceptionalThrowable as exceptionalCause
import com.typewritermc.services.libs.utils.rethrowExceptionalThrowable as rethrowExceptional

/** Marks the typed communicator routes DSL. */
@DslMarker
annotation class CommunicatorRoutesDsl

/** Handles a typed unary call. */
fun interface UnaryHandler<Address : Any, Request : Any, Response : Any> {
    context(main: MainSpanScope)
    suspend fun handle(call: IncomingUnaryCall<Address, Request, Response>): Response
}

/** Handles a typed event call. */
fun interface EventHandler<Address : Any, Event : Any> {
    context(main: MainSpanScope)
    suspend fun handle(call: IncomingEventCall<Address, Event>)
}

/** Handles a typed watch call. */
fun interface WatchHandler<Address : Any, Request : Any, Initial : Any, Update : Any> {
    context(main: MainSpanScope)
    suspend fun handle(call: IncomingWatchCall<Address, Request, Initial, Update>): Initial
}

/** Immutable input to a unary handler. */
data class IncomingUnaryCall<Address : Any, Request : Any, Response : Any>(
    val address: Address,
    val request: Request,
    val headers: MessageHeaders,
    val concreteAddress: MessageAddress,
    val contract: UnaryContract<Address, Request, Response>,
    val communicator: Communicator,
)

/** Immutable input to an event handler. */
data class IncomingEventCall<Address : Any, Event : Any>(
    val address: Address,
    val event: Event,
    val headers: MessageHeaders,
    val concreteAddress: MessageAddress,
    val contract: EventContract<Address, Event>,
    val communicator: Communicator,
)

/** Immutable input to a watch handler. */
data class IncomingWatchCall<Address : Any, Request : Any, Initial : Any, Update : Any>(
    val address: Address,
    val request: Request,
    val headers: MessageHeaders,
    val concreteAddress: MessageAddress,
    val contract: WatchContract<Address, Request, Initial, Update>,
    val communicator: Communicator,
)

/** Concurrency and shutdown settings for a router. */
data class RouterOptions(
    val maxInFlight: Int = 16,
    val defaultRouteParallelism: Int = 16,
    val shutdownTimeout: Duration = 30.seconds,
) {
    init {
        require(maxInFlight > 0) { "maxInFlight must be positive" }
        require(defaultRouteParallelism > 0) { "defaultRouteParallelism must be positive" }
        require(shutdownTimeout.isPositive() && shutdownTimeout.isFinite()) {
            "shutdownTimeout must be positive and finite"
        }
    }
}

/** Lifecycle state of a communicator router. */
enum class RouterState { NEW, STARTING, RUNNING, STOPPING, STOPPED }

/** Result of a router lifecycle operation. */
sealed interface RouterResult {
    data object Success : RouterResult

    data class Failure(
        val error: RouterError,
    ) : RouterResult
}

/** Typed router lifecycle failure. */
sealed interface RouterError {
    val cause: Throwable?

    data class Startup(
        override val cause: Throwable?,
    ) : RouterError

    data class Shutdown(
        override val cause: Throwable,
    ) : RouterError
}

/** Validated collection of typed routes. */
class CommunicatorRoutes internal constructor(
    internal val routes: List<Route>,
)

/** Builder for typed communicator routes. */
@CommunicatorRoutesDsl
class CommunicatorRoutesBuilder internal constructor() {
    private val routes = mutableListOf<Route>()

    /** Registers a unary route. */
    fun <A : Any, Q : Any, R : Any> unary(
        contract: UnaryContract<A, Q, R>,
        parallelism: Int? = null,
        consumerGroup: ConsumerGroup? = null,
        handler: UnaryHandler<A, Q, R>,
    ) = add(parallelism, contract.requestAddress.subscriptionPattern, consumerGroup) { router, message ->
        router.unary(contract, handler, message)
    }

    /** Registers an event route. */
    fun <A : Any, E : Any> event(
        contract: EventContract<A, E>,
        parallelism: Int? = null,
        consumerGroup: ConsumerGroup? = null,
        handler: EventHandler<A, E>,
    ) = add(parallelism, contract.address.subscriptionPattern, consumerGroup) { router, message ->
        router.event(contract, handler, message)
    }

    /** Registers a watch route. */
    fun <A : Any, Q : Any, I : Any, U : Any> watch(
        contract: WatchContract<A, Q, I, U>,
        parallelism: Int? = null,
        consumerGroup: ConsumerGroup? = null,
        handler: WatchHandler<A, Q, I, U>,
    ) = add(parallelism, contract.requestAddress.subscriptionPattern, consumerGroup) { router, message ->
        router.watch(contract, handler, message)
    }

    private fun add(
        parallelism: Int?,
        pattern: AddressPattern,
        group: ConsumerGroup?,
        process: suspend (CommunicatorRouter, InboundMessage) -> Unit,
    ) {
        if (parallelism != null) require(parallelism > 0) { "Route parallelism must be positive" }
        routes += Route(pattern, parallelism, group, process)
    }

    internal fun build() = CommunicatorRoutes(routes.toList())
}

/** Builds a validated collection of typed communicator routes. */
fun communicatorRoutes(block: CommunicatorRoutesBuilder.() -> Unit): CommunicatorRoutes = CommunicatorRoutesBuilder().apply(block).build()

internal data class Route(
    val pattern: AddressPattern,
    val parallelism: Int?,
    val group: ConsumerGroup?,
    val process: suspend (CommunicatorRouter, InboundMessage) -> Unit,
)

/** Hosts typed message handlers with bounded concurrency and structured lifecycle ownership. */
class CommunicatorRouter internal constructor(
    private val transport: MessageTransport,
    routes: CommunicatorRoutes,
    private val communicator: Communicator,
    private val telemetry: ServiceTelemetry,
    private val propagators: ContextPropagators,
    parentScope: CoroutineScope,
    private val options: RouterOptions = RouterOptions(),
) {
    private val definitions =
        routes.routes.also { all ->
            require(
                all.indices.none { left ->
                    ((left + 1) until all.size).any { right -> all[left].pattern.overlaps(all[right].pattern) }
                },
            ) { "Overlapping route subscription patterns" }
        }
    private val job = Job(parentScope.coroutineContext[Job])
    private val scope = CoroutineScope(parentScope.coroutineContext + job)
    private val permits = Semaphore(options.maxInFlight)
    private val lifecycle = Mutex()
    private val mutableState = MutableStateFlow(RouterState.NEW)
    private var runtimes = emptyList<Runtime>()
    private var completion: CompletableDeferred<RouterResult>? = null

    /** Thread-safe lifecycle state stream. */
    val stateFlow: StateFlow<RouterState> = mutableState.asStateFlow()

    /** Current lifecycle state. */
    val state: RouterState get() = mutableState.value

    /** Subscribes all routes and starts their workers. */
    suspend fun start(): RouterResult {
        lifecycle.withLock {
            check(state == RouterState.NEW) { "Router can only be started once" }
            mutableState.value = RouterState.STARTING
        }
        val acquired = mutableListOf<Pair<Route, TransportSubscription>>()
        return try {
            for (route in definitions) {
                when (val result = transport.subscribe(route.pattern, SubscriptionOptions(route.group))) {
                    is TransportResult.Success -> acquired += route to result.value
                    is TransportResult.Failure -> throw StartupFailure(transportException(result.error))
                }
            }
            lifecycle.withLock {
                runtimes = acquired.map { (route, subscription) -> startRuntime(route, subscription) }
                mutableState.value = RouterState.RUNNING
            }
            RouterResult.Success
        } catch (failure: Throwable) {
            val startupFailure = if (failure is StartupFailure) requireNotNull(failure.cause) else failure
            val closeFailures =
                withContext(NonCancellable) {
                    val failures =
                        acquired.mapNotNull { (_, subscription) ->
                            try {
                                subscription.close()
                                null
                            } catch (cleanup: Throwable) {
                                cleanup
                            }
                        }
                    lifecycle.withLock { mutableState.value = RouterState.STOPPED }
                    job.cancel()
                    failures
                }
            val exceptional = (listOf(failure) + closeFailures).firstNotNullOfOrNull(::exceptionalCause)
            if (exceptional != null) {
                (listOf(startupFailure) + closeFailures).forEach { if (it !== exceptional) exceptional.addSuppressed(it) }
                throw exceptional
            }
            closeFailures.forEach { if (it !== startupFailure) startupFailure.addSuppressed(it) }
            RouterResult.Failure(RouterError.Startup(startupFailure))
        }
    }

    /** Closes subscriptions and drains accepted messages within the configured timeout. */
    suspend fun stop(): RouterResult {
        val (owned, result) = beginShutdown()
        if (owned) performShutdown(result, drain = true)
        return result.await()
    }

    private suspend fun beginShutdown(): Pair<Boolean, CompletableDeferred<RouterResult>> =
        lifecycle.withLock {
            completion?.let { return@withLock false to it }
            check(state == RouterState.RUNNING) { "Router is not running" }
            mutableState.value = RouterState.STOPPING
            val deferred = CompletableDeferred<RouterResult>()
            completion = deferred
            true to deferred
        }

    private suspend fun performShutdown(
        result: CompletableDeferred<RouterResult>,
        drain: Boolean,
    ) {
        var final: RouterResult = RouterResult.Success
        var exceptional: Throwable? = null
        try {
            withContext(NonCancellable) {
                val snapshot = lifecycle.withLock { runtimes }
                val closeFailures = java.util.Collections.synchronizedList(mutableListOf<Pair<Runtime, Throwable>>())
                val drained =
                    withTimeoutOrNull(options.shutdownTimeout) {
                        coroutineScope {
                            snapshot
                                .map { runtime ->
                                    async {
                                        try {
                                            runtime.subscription.close()
                                        } catch (failure: Throwable) {
                                            if (currentCoroutineContext().isActive) closeFailures += runtime to failure
                                        }
                                    }
                                }.joinAll()
                        }
                        if (!drain) {
                            snapshot.forEach(Runtime::cancel)
                            return@withTimeoutOrNull true
                        }
                        snapshot.map { it.collector }.joinAll()
                        snapshot.flatMap { it.workers }.joinAll()
                        true
                    } == true
                if (!drained) snapshot.forEach(Runtime::cancel)

                exceptional = closeFailures.firstNotNullOfOrNull { exceptionalCause(it.second) }
                val ordinaryCloseFailures =
                    closeFailures
                        .filter { exceptionalCause(it.second) == null }
                        .map { (runtime, failure) -> sluggedClose(runtime.route, failure) }
                var closeFailure: Throwable? = null
                ordinaryCloseFailures.forEach { closeFailure = aggregate(closeFailure, it) }
                exceptional?.let { primary ->
                    closeFailures.forEach { (_, failure) -> if (failure !== primary) primary.addSuppressed(failure) }
                }
                final =
                    if (!drained) {
                        val timeout = ShutdownTimeout(options.shutdownTimeout)
                        closeFailure?.let(timeout::addSuppressed)
                        RouterResult.Failure(RouterError.Shutdown(timeout))
                    } else if (closeFailure != null) {
                        RouterResult.Failure(RouterError.Shutdown(requireNotNull(closeFailure)))
                    } else {
                        RouterResult.Success
                    }
            }
        } finally {
            withContext(NonCancellable) {
                job.cancel()
                lifecycle.withLock { mutableState.value = RouterState.STOPPED }
                if (exceptional != null) {
                    result.completeExceptionally(requireNotNull(exceptional))
                } else {
                    result.complete(
                        final,
                    )
                }
            }
        }
        exceptional?.let { throw it }
    }

    private fun startRuntime(
        route: Route,
        subscription: TransportSubscription,
    ): Runtime {
        val parallelism = route.parallelism ?: options.defaultRouteParallelism
        val routePermits = Semaphore(parallelism)
        val channel =
            Channel<InboundMessage>(parallelism, onUndeliveredElement = {
                permits.release()
                routePermits.release()
            })
        val workers =
            List(parallelism) {
                scope.launch {
                    for (message in channel) {
                        try {
                            route.process(this@CommunicatorRouter, message)
                        } catch (failure: Throwable) {
                            val exceptional = exceptionalCause(failure)
                            if (exceptional != null) {
                                shutdownRouter()
                                throw exceptional
                            }
                        } finally {
                            permits.release()
                            routePermits.release()
                        }
                    }
                }
            }
        val collector =
            scope.launch {
                try {
                    subscription.deliveries.collect { delivery ->
                        when (delivery) {
                            is TransportDelivery.Message -> {
                                routePermits.acquire()
                                try {
                                    permits.acquire()
                                    try {
                                        channel.send(delivery.message)
                                    } catch (failure: Throwable) {
                                        permits.release()
                                        throw failure
                                    }
                                } catch (failure: Throwable) {
                                    routePermits.release()
                                    throw failure
                                }
                            }

                            is TransportDelivery.Failure -> {
                                terminalRouteShutdown(route, transportException(delivery.error))
                                return@collect
                            }

                            TransportDelivery.Completed -> {
                                terminalRouteShutdown(route, RouteCompleted(route.pattern.value))
                                return@collect
                            }
                        }
                    }
                } finally {
                    channel.close()
                }
            }
        return Runtime(route, subscription, channel, collector, workers)
    }

    private suspend fun terminalRouteShutdown(
        route: Route,
        cause: Throwable,
    ) {
        try {
            telemetry.consumerSpan<Unit>(
                "route receive",
                ROUTE_TRANSPORT_SLUG,
                attributes = messagingAttributes("route", route.pattern.value),
            ) {
                throw SluggedException.wrap(ROUTE_TRANSPORT_SLUG, cause)
            }
        } catch (failure: Throwable) {
            rethrowExceptional(failure)
        }
        shutdownRouter()
    }

    private suspend fun shutdownRouter() =
        withContext(NonCancellable) {
            val (owned, result) = beginShutdown()
            if (owned) {
                performShutdown(result, drain = false)
            } else {
                result.await()
            }
        }

    internal suspend fun <A : Any, Q : Any, R : Any> unary(
        contract: UnaryContract<A, Q, R>,
        handler: UnaryHandler<A, Q, R>,
        message: InboundMessage,
    ) = replying(contract, message) { main, address, request ->
        context(main) {
            handler.handle(
                IncomingUnaryCall(address, request, message.headers, message.address, contract, communicator),
            )
        }
    }

    internal suspend fun <A : Any, Q : Any, I : Any, U : Any> watch(
        contract: WatchContract<A, Q, I, U>,
        handler: WatchHandler<A, Q, I, U>,
        message: InboundMessage,
    ) = replying(contract, message) { main, address, request ->
        context(main) {
            handler.handle(
                IncomingWatchCall(address, request, message.headers, message.address, contract, communicator),
            )
        }
    }

    internal suspend fun <A : Any, E : Any> event(
        contract: EventContract<A, E>,
        handler: EventHandler<A, E>,
        message: InboundMessage,
    ) = consume(contract.name, contract.address.template, contract.failureSlug, message) { main ->
        val address = requireNotNull(contract.address.match(message.address))
        val event = contract.codec.decode(message.payload)
        context(main) {
            handler.handle(IncomingEventCall(address, event, message.headers, message.address, contract, communicator))
        }
    }

    private suspend fun <A : Any, Q : Any, R : Any> replying(
        contract: UnaryContract<A, Q, R>,
        message: InboundMessage,
        handler: suspend (MainSpanScope, A, Q) -> R,
    ) = replying(
        contract.name,
        contract.requestAddress,
        null,
        contract.requestCodec,
        contract.responseCodec,
        contract.responsePolicy,
        contract.failureSlug,
        message,
        handler,
    )

    private suspend fun <A : Any, Q : Any, R : Any> replying(
        contract: WatchContract<A, Q, R, *>,
        message: InboundMessage,
        handler: suspend (MainSpanScope, A, Q) -> R,
    ) = replying(
        contract.name,
        contract.requestAddress,
        contract.requestAddress.template,
        contract.requestCodec,
        contract.initialCodec,
        contract.initialPolicy,
        contract.failureSlug,
        message,
        handler,
    )

    private suspend fun <A : Any, Q : Any, R : Any> replying(
        name: OperationName,
        template: AddressTemplate<A>,
        responseTemplate: String?,
        requestCodec: PayloadCodec<Q>,
        responseCodec: PayloadCodec<R>,
        policy: ResponsePolicy<R>,
        slug: ErrorSlug,
        message: InboundMessage,
        handler: suspend (MainSpanScope, A, Q) -> R,
    ) = consume(name, template.template, slug, message) { main ->
        val replyTo =
            message.replyTo ?: throw SluggedException.wrap(
                slug,
                IllegalStateException("Missing reply address"),
            )
        val response =
            try {
                handler(main, requireNotNull(template.match(message.address)), requestCodec.decode(message.payload))
            } catch (original: Throwable) {
                rethrowExceptional(original)
                sendInternalFailure(main, name, responseTemplate, responseCodec, policy, slug, replyTo, original)
                throw original
            }
        val classification =
            try {
                policy.classify(response)
            } catch (original: Throwable) {
                rethrowExceptional(original)
                sendInternalFailure(main, name, responseTemplate, responseCodec, policy, slug, replyTo, original)
                throw original
            }
        annotateResponse(main, classification)
        sendReply(name, responseTemplate, responseCodec, slug, replyTo, response, classification)
        if (classification.outcome == ResponseOutcome.INTERNAL_ERROR) {
            throw SluggedException.wrap(slug, ReturnedInternalFailure())
        }
    }

    private suspend fun <R : Any> sendInternalFailure(
        main: MainSpanScope,
        name: OperationName,
        template: String?,
        codec: PayloadCodec<R>,
        policy: ResponsePolicy<R>,
        slug: ErrorSlug,
        replyTo: MessageAddress,
        original: Throwable,
    ) {
        try {
            val response = policy.internalFailureResponse
            val classification = policy.classify(response)
            annotateResponse(main, classification)
            sendReply(name, template, codec, slug, replyTo, response, classification)
        } catch (secondary: Throwable) {
            rethrowExceptional(secondary)
            val wrapped = SluggedException.wrap(slug, secondary)
            if (wrapped !== original) original.addSuppressed(wrapped)
        }
    }

    private fun annotateResponse(
        main: MainSpanScope,
        classification: ResponseClassification,
    ) {
        main.annotate {
            domainOutcome(classification.variant.value)
            operationOutcome(classification.outcome.name.lowercase())
        }
    }

    private suspend fun <R : Any> sendReply(
        name: OperationName,
        template: String?,
        codec: PayloadCodec<R>,
        slug: ErrorSlug,
        replyTo: MessageAddress,
        response: R,
        classification: ResponseClassification,
    ) {
        val sent =
            communicator.sendResponse(
                name.value,
                template,
                replyTo,
                response,
                codec,
                classification,
                slug,
            )
        if (sent is CommunicationResult.Failure) {
            throw SluggedException.wrap(sent.error.slug, sent.error.cause ?: IllegalStateException("Reply failed"))
        }
    }

    private suspend fun consume(
        name: OperationName,
        template: String,
        slug: ErrorSlug,
        message: InboundMessage,
        block: suspend (MainSpanScope) -> Unit,
    ) {
        val parent = propagators.textMapPropagator.extract(Context.current(), message.headers, MessageHeadersGetter)
        telemetry.consumerSpan(
            "${name.value} receive",
            slug,
            parent,
            messagingAttributes(name.value, template)
                .toBuilder()
                .put("messaging.destination.name", message.address.value)
                .build(),
        ) { main -> block(main) }
    }

    private fun messagingAttributes(
        name: String,
        template: String,
    ): Attributes =
        Attributes
            .builder()
            .put("messaging.system", transport.system.value)
            .put("messaging.destination.template", template)
            .put("messaging.operation.name", name)
            .put("messaging.operation.type", "receive")
            .build()

    private class StartupFailure(
        cause: Throwable,
    ) : RuntimeException(cause)

    private class ReturnedInternalFailure : RuntimeException("Handler returned internal error")

    private class RouteCompleted(
        pattern: String,
    ) : RuntimeException("Required route $pattern completed")

    private class ShutdownTimeout(
        timeout: Duration,
    ) : RuntimeException("Router shutdown timed out after $timeout")

    private data class Runtime(
        val route: Route,
        val subscription: TransportSubscription,
        val channel: Channel<InboundMessage>,
        val collector: Job,
        val workers: List<Job>,
    ) {
        fun cancel() {
            collector.cancel()
            channel.cancel()
            workers.forEach(Job::cancel)
        }
    }

    private companion object {
        val ROUTE_TRANSPORT_SLUG: ErrorSlug = ErrorSlug.of("route-transport-failed")
    }
}

private fun sluggedClose(
    route: Route,
    failure: Throwable,
): Throwable =
    SluggedException.wrap(
        ErrorSlug.of("route-close-failed"),
        IllegalStateException("Failed to close ${route.pattern.value}", failure),
    )

private fun transportException(error: TransportError): Throwable =
    error.cause ?: when (error) {
        is TransportError.Timeout -> TransportTimeoutException()
        is TransportError.Unavailable -> TransportUnavailableException()
        is TransportError.NoResponders -> TransportNoRespondersException()
        is TransportError.Failure -> error.cause
    }

private class TransportTimeoutException : RuntimeException("Transport timed out")

private class TransportUnavailableException : RuntimeException("Transport unavailable")

private class TransportNoRespondersException : RuntimeException("Transport has no responders")

private fun aggregate(
    primary: Throwable?,
    next: Throwable,
): Throwable {
    if (primary == null) return next
    if (primary !== next) primary.addSuppressed(next)
    return primary
}

private fun AddressPattern.overlaps(other: AddressPattern): Boolean {
    val segments = value.split('.')
    val otherSegments = other.value.split('.')
    return segments.size == otherSegments.size &&
        segments.zip(otherSegments).all { (left, right) ->
            left == right || left == "*" || right == "*"
        }
}
