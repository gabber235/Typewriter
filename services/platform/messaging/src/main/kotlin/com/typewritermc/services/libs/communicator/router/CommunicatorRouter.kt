package com.typewritermc.services.libs.communicator.router

import com.typewritermc.services.libs.communicator.address.AddressPattern
import com.typewritermc.services.libs.communicator.address.AddressTemplate
import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.EventContract
import com.typewritermc.services.libs.communicator.contract.OperationName
import com.typewritermc.services.libs.communicator.contract.PayloadCodec
import com.typewritermc.services.libs.communicator.contract.ReplyAddressRule
import com.typewritermc.services.libs.communicator.contract.ResponseClassification
import com.typewritermc.services.libs.communicator.contract.ResponsePolicy
import com.typewritermc.services.libs.communicator.contract.ScatterContract
import com.typewritermc.services.libs.communicator.contract.UnaryContract
import com.typewritermc.services.libs.communicator.contract.WatchContract
import com.typewritermc.services.libs.communicator.contract.operationOutcome
import com.typewritermc.services.libs.communicator.result.CommunicationResult
import com.typewritermc.services.libs.communicator.telemetry.MessageHeadersGetter
import com.typewritermc.services.libs.communicator.transfer.Assembly
import com.typewritermc.services.libs.communicator.transfer.PayloadAssembler
import com.typewritermc.services.libs.communicator.transfer.PayloadHeaders
import com.typewritermc.services.libs.communicator.transfer.TransferRejected
import com.typewritermc.services.libs.communicator.transfer.TransportLimits
import com.typewritermc.services.libs.communicator.transfer.failureHeaders
import com.typewritermc.services.libs.communicator.transport.ConsumerGroup
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.MessageTransport
import com.typewritermc.services.libs.communicator.transport.OutboundMessage
import com.typewritermc.services.libs.communicator.transport.Payload
import com.typewritermc.services.libs.communicator.transport.SubscriptionOptions
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.communicator.transport.TransportResult
import com.typewritermc.services.libs.communicator.transport.TransportSubscription
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.EventProjection
import com.typewritermc.services.libs.telemetry.LogSeverity
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.MessagingAttributeKeys
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.SluggedException
import com.typewritermc.services.libs.telemetry.consumerSpan
import com.typewritermc.services.libs.utils.findExceptional
import com.typewritermc.services.libs.utils.rethrowExceptional
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
import kotlinx.coroutines.delay
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
import kotlin.time.TimeMark
import kotlin.time.TimeSource

/** Marks the typed communicator routes DSL. */
@DslMarker
annotation class CommunicatorRoutesDsl

/** Handles a typed unary call. */
fun interface UnaryHandler<Address : Any, Request : Any, Response : Any> {
    context(main: MainSpanScope)
    suspend fun handle(call: IncomingUnaryCall<Address, Request, Response>): Response
}

/** Handles a scatter call and may ignore it without replying. */
fun interface ScatterHandler<Address : Any, Request : Any, Response : Any> {
    context(main: MainSpanScope)
    suspend fun handle(call: IncomingUnaryCall<Address, Request, Response>): Response?
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

/**
 * Bounds global in flight work, per route worker concurrency, buffering, and shutdown draining.
 *
 * Parallel workers can complete messages out of arrival order. Use route parallelism one where handler ordering is
 * part of the application contract. [maxAssemblingBytes] bounds the framed requests one route assembles at once, and
 * an assembly without a new frame for its route's frame inactivity is dropped.
 */
data class RouterOptions(
    val maxInFlight: Int = 16,
    val defaultRouteParallelism: Int = 16,
    val shutdownTimeout: Duration = 30.seconds,
    val maxAssemblingBytes: Long = 192L * 1024L * 1024L,
) {
    init {
        require(maxInFlight > 0) { "maxInFlight must be positive" }
        require(maxAssemblingBytes > 0) { "maxAssemblingBytes must be positive" }
        require(defaultRouteParallelism > 0) { "defaultRouteParallelism must be positive" }
        require(shutdownTimeout.isPositive() && shutdownTimeout.isFinite()) {
            "shutdownTimeout must be positive and finite"
        }
    }
}

/** Lifecycle state of a communicator router. */
enum class RouterState { NEW, STARTING, RUNNING, STOPPING, STOPPED }

/** Result of a router lifecycle operation; startup and shutdown failures remain typed values when ordinary. */
sealed interface RouterResult {
    data object Success : RouterResult

    data class Failure(
        val error: RouterError,
    ) : RouterResult
}

/** Typed router lifecycle failure with the cause that callers can use for diagnostics or recovery. */
sealed interface RouterError {
    val cause: Throwable?

    data class Startup(
        override val cause: Throwable?,
    ) : RouterError

    data class Shutdown(
        override val cause: Throwable,
    ) : RouterError
}

/** Validated collection of typed routes, held by a router until its single start attempt. */
class CommunicatorRoutes internal constructor(
    internal val routes: List<Route>,
)

/**
 * Collects typed handlers and their subscription and concurrency settings.
 *
 * Unqualified registrations use the contract pattern; the At variants bind one concrete address. Building
 * definitions does not start transport subscriptions.
 */
@CommunicatorRoutesDsl
class CommunicatorRoutesBuilder internal constructor() {
    private val routes = mutableListOf<Route>()

    /** Registers a unary route using the contract's subscription pattern and optional consumer group. */
    fun <A : Any, Q : Any, R : Any> unary(
        contract: UnaryContract<A, Q, R>,
        parallelism: Int? = null,
        consumerGroup: ConsumerGroup? = null,
        handler: UnaryHandler<A, Q, R>,
    ) = add(
        parallelism,
        contract.requestAddress.subscriptionPattern,
        consumerGroup,
        contract.replies(),
        contract.framing(consumerGroup),
    ) { router, message, received ->
        router.unary(contract, handler, message, received)
    }

    /** Registers a unary route restricted to the concrete address rendered from [address]. */
    fun <A : Any, Q : Any, R : Any> unaryAt(
        contract: UnaryContract<A, Q, R>,
        address: A,
        parallelism: Int? = null,
        consumerGroup: ConsumerGroup? = null,
        handler: UnaryHandler<A, Q, R>,
    ) = add(
        parallelism,
        contract.requestAddress.subscribedAt(address).subscriptionPattern,
        consumerGroup,
        contract.replies(),
        contract.framing(consumerGroup),
    ) { router, message, received ->
        router.unary(contract, handler, message, received)
    }

    /** Registers a fanout request route without a consumer group, allowing every matching listener to receive it. */
    fun <A : Any, Q : Any, R : Any> scatter(
        contract: ScatterContract<A, Q, R>,
        parallelism: Int? = null,
        handler: ScatterHandler<A, Q, R>,
    ) = add(parallelism, contract.requestAddress.subscriptionPattern, null, contract.replies()) { router, message, received ->
        router.scatter(contract, handler, message, received)
    }

    /** Registers a scatter route subscribed at one concrete address. */
    fun <A : Any, Q : Any, R : Any> scatterAt(
        contract: ScatterContract<A, Q, R>,
        address: A,
        parallelism: Int? = null,
        handler: ScatterHandler<A, Q, R>,
    ) = add(
        parallelism,
        contract.requestAddress.subscribedAt(address).subscriptionPattern,
        null,
        contract.replies(),
    ) { router, message, received ->
        router.scatter(contract, handler, message, received)
    }

    /** Registers an event route using the contract's publication pattern. */
    fun <A : Any, E : Any> event(
        contract: EventContract<A, E>,
        parallelism: Int? = null,
        consumerGroup: ConsumerGroup? = null,
        handler: EventHandler<A, E>,
    ) = add(parallelism, contract.address.subscriptionPattern, consumerGroup, null) { router, message, _ ->
        router.event(contract, handler, message)
    }

    /** Registers an event route restricted to the concrete address rendered from [address]. */
    fun <A : Any, E : Any> eventAt(
        contract: EventContract<A, E>,
        address: A,
        parallelism: Int? = null,
        consumerGroup: ConsumerGroup? = null,
        handler: EventHandler<A, E>,
    ) = add(parallelism, contract.address.subscribedAt(address).subscriptionPattern, consumerGroup, null) { router, message, _ ->
        router.event(contract, handler, message)
    }

    /** Registers a watch request route; update publications are handled by the watch owner, not this route. */
    fun <A : Any, Q : Any, I : Any, U : Any> watch(
        contract: WatchContract<A, Q, I, U>,
        parallelism: Int? = null,
        consumerGroup: ConsumerGroup? = null,
        handler: WatchHandler<A, Q, I, U>,
    ) = add(parallelism, contract.requestAddress.subscriptionPattern, consumerGroup, contract.replies()) { router, message, received ->
        router.watch(contract, handler, message, received)
    }

    /** Registers a watch request route restricted to the concrete request address rendered from [address]. */
    fun <A : Any, Q : Any, I : Any, U : Any> watchAt(
        contract: WatchContract<A, Q, I, U>,
        address: A,
        parallelism: Int? = null,
        consumerGroup: ConsumerGroup? = null,
        handler: WatchHandler<A, Q, I, U>,
    ) = add(
        parallelism,
        contract.requestAddress.subscribedAt(address).subscriptionPattern,
        consumerGroup,
        contract.replies(),
    ) { router, message, received ->
        router.watch(contract, handler, message, received)
    }

    private fun add(
        parallelism: Int?,
        pattern: AddressPattern,
        group: ConsumerGroup?,
        replies: ReplyCheck<*>?,
        framing: TransportLimits? = null,
        process: suspend (CommunicatorRouter, InboundMessage, TimeMark) -> Unit,
    ) {
        if (parallelism != null) require(parallelism > 0) { "Route parallelism must be positive" }
        routes += Route(pattern, parallelism, group, replies, framing, process)
    }

    private fun <A : Any> UnaryContract<A, *, *>.replies() = ReplyCheck(name, failureSlug, requestAddress, replyAddresses)

    private fun <A : Any> ScatterContract<A, *, *>.replies() = ReplyCheck(name, failureSlug, requestAddress, replyAddresses)

    private fun <A : Any> WatchContract<A, *, *, *>.replies() = ReplyCheck(name, failureSlug, requestAddress, replyAddresses)

    /**
     * The limits a route assembles framed requests by, or null for routes whose requests are single messages. Frames
     * of one request must reach one subscriber, so such a route cannot share a consumer group.
     */
    private fun UnaryContract<*, *, *>.framing(group: ConsumerGroup?): TransportLimits? {
        val framing = limits?.takeIf { it.framesRequests } ?: return null
        require(group == null) { "${name.value} frames requests, so it cannot use a consumer group: frames would scatter across members" }
        return framing
    }

    internal fun build() = CommunicatorRoutes(routes.toList())
}

/** Builds a validated collection of typed communicator routes. */
fun communicatorRoutes(block: CommunicatorRoutesBuilder.() -> Unit): CommunicatorRoutes = CommunicatorRoutesBuilder().apply(block).build()

internal data class Route(
    val pattern: AddressPattern,
    val parallelism: Int?,
    val group: ConsumerGroup?,
    /** Set for a request route: the reply addresses its server answers, checked before any frame or handler. */
    val replies: ReplyCheck<*>?,
    /** Set for a route whose requests may arrive in frames; its runtime assembles them before dispatch. */
    val framing: TransportLimits?,
    /** Handles one complete message, received at the mark that starts its reply time to live. */
    val process: suspend (CommunicatorRouter, InboundMessage, TimeMark) -> Unit,
)

/**
 * The reply addresses one request route answers, by its contract's [rule] over the parsed request address. A message
 * without a reply address is admitted, since it asks for no answer.
 */
internal class ReplyCheck<Address : Any>(
    val name: OperationName,
    val failureSlug: ErrorSlug,
    val template: AddressTemplate<Address>,
    private val rule: ReplyAddressRule<Address>,
) {
    fun admits(message: InboundMessage): Boolean {
        val reply = message.replyTo ?: return true
        val address = template.match(message.address) ?: return false
        return rule.admits(address, reply)
    }
}

/** A complete message queued for a route worker, with the mark of the moment it arrived. */
internal class Received(
    val message: InboundMessage,
    val at: TimeMark,
)

/** How a route sends the reply to one request: by the route's [limits], or the transport's when null, timed from [received]. */
private class Replying(
    val limits: TransportLimits?,
    val received: TimeMark,
)

/**
 * Owns route subscriptions and bounded handler workers beneath the supplied parent scope.
 *
 * Overlapping patterns are rejected. Start is allowed once and releases acquired subscriptions on failure. Stop
 * closes subscriptions and drains accepted work within its timeout, then cancels remaining workers. Recreate the
 * router for a replacement transport session.
 */
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
    private val pendingSubscriptions = mutableMapOf<TransportSubscription, Route>()
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
                    is TransportResult.Success -> {
                        acquired += route to result.value
                        lifecycle.withLock { pendingSubscriptions[result.value] = route }
                    }

                    is TransportResult.Failure -> {
                        throw StartupFailure(transportException(result.error))
                    }
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
                                lifecycle.withLock { pendingSubscriptions.remove(subscription) }
                                null
                            } catch (cleanup: Throwable) {
                                cleanup
                            }
                        }
                    lifecycle.withLock { mutableState.value = RouterState.STOPPED }
                    job.cancel()
                    failures
                }
            val exceptional =
                (listOf(failure) + closeFailures)
                    .firstNotNullOfOrNull { it.findExceptional() }
            if (exceptional != null) {
                (listOf(startupFailure) + closeFailures).forEach { if (it !== exceptional) exceptional.addSuppressed(it) }
                throw exceptional
            }
            closeFailures.forEach { if (it !== startupFailure) startupFailure.addSuppressed(it) }
            RouterResult.Failure(RouterError.Startup(startupFailure))
        }
    }

    /**
     * Closes subscriptions and drains accepted messages within the configured timeout.
     * Ordinary cleanup failures retain subscriptions for a later stop attempt. Successful stop remains idempotent.
     */
    suspend fun stop(): RouterResult {
        val (owned, result) = beginShutdown()
        if (owned) performShutdown(result, drain = true)
        return result.await()
    }

    private suspend fun beginShutdown(): Pair<Boolean, CompletableDeferred<RouterResult>> =
        lifecycle.withLock {
            completion?.let { return@withLock false to it }
            check(state != RouterState.STARTING) { "Router is starting" }
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
                val subscriptions = lifecycle.withLock { pendingSubscriptions.toList() }
                val closeFailures = java.util.Collections.synchronizedList(mutableListOf<Pair<Route, Throwable>>())
                val drained =
                    withTimeoutOrNull(options.shutdownTimeout) {
                        coroutineScope {
                            subscriptions
                                .map { (subscription, route) ->
                                    async {
                                        try {
                                            subscription.close()
                                            lifecycle.withLock { pendingSubscriptions.remove(subscription) }
                                        } catch (failure: Throwable) {
                                            if (currentCoroutineContext().isActive) closeFailures += route to failure
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
                        snapshot.forEach { it.sweeper?.cancel() }
                        true
                    } == true
                if (!drained) snapshot.forEach(Runtime::cancel)

                exceptional = closeFailures.firstNotNullOfOrNull { it.second.findExceptional() }
                val ordinaryCloseFailures =
                    closeFailures
                        .filter { it.second.findExceptional() == null }
                        .map { (route, failure) -> sluggedClose(route, failure) }
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
                lifecycle.withLock {
                    mutableState.value = RouterState.STOPPED
                    if (exceptional == null && final is RouterResult.Failure) completion = null
                }
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
        val assembler =
            route.framing?.let { PayloadAssembler(it, it.requestMaxBytes, options.maxAssemblingBytes) }
        val channel =
            Channel<Received>(parallelism, onUndeliveredElement = {
                permits.release()
                routePermits.release()
            })
        val workers =
            List(parallelism) {
                scope.launch {
                    for (received in channel) {
                        try {
                            route.process(this@CommunicatorRouter, received.message, received.at)
                        } catch (failure: Throwable) {
                            val exceptional = failure.findExceptional()
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
                                // Checked before any frame is assembled or answered, so a refused reply address
                                // receives no credit, failure answer or reply.
                                val replies = route.replies
                                if (replies != null && !replies.admits(delivery.message)) {
                                    refuseReply(replies, delivery.message)
                                    return@collect
                                }
                                // Frames are assembled here, in arrival order, so parallel workers never reorder them.
                                val request =
                                    if (assembler == null) delivery.message else assembled(assembler, delivery.message) ?: return@collect
                                routePermits.acquire()
                                try {
                                    permits.acquire()
                                    try {
                                        channel.send(Received(request, TimeSource.Monotonic.markNow()))
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
                                if (state == RouterState.RUNNING) {
                                    terminalRouteShutdown(route, RouteCompleted(route.pattern.value))
                                }
                                return@collect
                            }
                        }
                    }
                } finally {
                    channel.close()
                }
            }
        // An upload whose sender vanished receives no further frame, so only a timer frees its assembly.
        val sweeper =
            assembler?.let {
                scope.launch {
                    while (true) {
                        delay(requireNotNull(route.framing).frameInactivity / 2)
                        it.sweep()
                    }
                }
            }
        return Runtime(route, subscription, channel, collector, workers, sweeper)
    }

    /**
     * Assembles one message of a route whose requests may be framed and returns the complete request, or null while
     * frames are missing. A window end is answered with its credit or failure on its reply address. A rejected frame
     * drops its assembly; when it ends a window it is answered rejected, so the sender fails at once, and otherwise
     * the sender learns it at its next window end.
     */
    private suspend fun assembled(
        assembler: PayloadAssembler,
        message: InboundMessage,
    ): InboundMessage? =
        when (
            val assembly =
                try {
                    assembler.accept(message)
                } catch (_: TransferRejected) {
                    val replyTo = message.replyTo ?: return null
                    val payloadId = message.headers.first(PayloadHeaders.PAYLOAD) ?: return null
                    transport.publish(OutboundMessage(replyTo, Payload.Empty, headers = failureHeaders(payloadId, PayloadHeaders.REJECTED)))
                    return null
                }
        ) {
            is Assembly.Complete -> {
                assembly.message
            }

            is Assembly.Answer -> {
                transport.publish(OutboundMessage(requireNotNull(message.replyTo), Payload.Empty, headers = assembly.headers))
                null
            }

            Assembly.Waiting, is Assembly.Failed -> {
                null
            }
        }

    /**
     * Drops a request whose reply address its route does not answer, recording a warning with the route and the refused
     * address. Nothing is published and no handler runs.
     */
    private suspend fun refuseReply(
        replies: ReplyCheck<*>,
        message: InboundMessage,
    ) {
        try {
            consume(replies.name, replies.template.template, replies.failureSlug, message) { main ->
                main.event(
                    REPLY_REFUSED_EVENT,
                    EventProjection.log(LogSeverity.WARN, "Dropped a ${replies.name.value} request whose reply address is no caller inbox"),
                ) {
                    attribute(MessagingAttributeKeys.OperationName, replies.name.value)
                    attribute(MessagingAttributeKeys.DestinationName, message.address.value)
                    attribute(REPLY_ADDRESS_ATTRIBUTE, requireNotNull(message.replyTo).value)
                }
            }
        } catch (failure: Throwable) {
            failure.rethrowExceptional()
        }
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
            failure.rethrowExceptional()
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
        received: TimeMark,
    ) = replying(contract, message, received) { main, address, request ->
        context(main) {
            handler.handle(
                IncomingUnaryCall(address, request, message.headers, message.address, contract, communicator),
            )
        }
    }

    internal suspend fun <A : Any, Q : Any, R : Any> scatter(
        contract: ScatterContract<A, Q, R>,
        handler: ScatterHandler<A, Q, R>,
        message: InboundMessage,
        received: TimeMark,
    ) = scatterReplying(contract, message, received) { main, address, request ->
        context(main) {
            handler.handle(
                IncomingUnaryCall(
                    address,
                    request,
                    message.headers,
                    message.address,
                    contract.asUnaryContract(),
                    communicator,
                ),
            )
        }
    }

    private suspend fun <A : Any, Q : Any, R : Any> scatterReplying(
        contract: ScatterContract<A, Q, R>,
        message: InboundMessage,
        received: TimeMark,
        handler: suspend (MainSpanScope, A, Q) -> R?,
    ) = consume(contract.name, contract.requestAddress.template, contract.failureSlug, message) { main ->
        val replyTo =
            message.replyTo ?: throw SluggedException.wrap(
                contract.failureSlug,
                IllegalStateException("Missing reply address"),
            )
        val response =
            try {
                handler(
                    main,
                    requireNotNull(contract.requestAddress.match(message.address)),
                    contract.requestCodec.decode(message.payload),
                )
            } catch (original: Throwable) {
                original.rethrowExceptional()
                sendInternalFailure(
                    main,
                    contract.name,
                    null,
                    contract.responseCodec,
                    contract.responsePolicy,
                    contract.failureSlug,
                    replyTo,
                    original,
                    Replying(contract.limits, received),
                )
                throw original
            }
        if (response == null) return@consume Unit
        val classification = contract.responsePolicy.classify(response)
        annotateResponse(main, classification)
        sendReply(
            contract.name,
            null,
            contract.responseCodec,
            contract.failureSlug,
            replyTo,
            response,
            classification,
            Replying(contract.limits, received),
        )
        classification.operationOutcome(Unit)
    }

    internal suspend fun <A : Any, Q : Any, I : Any, U : Any> watch(
        contract: WatchContract<A, Q, I, U>,
        handler: WatchHandler<A, Q, I, U>,
        message: InboundMessage,
        received: TimeMark,
    ) = replying(contract, message, received) { main, address, request ->
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
        received: TimeMark,
        handler: suspend (MainSpanScope, A, Q) -> R,
    ) = replying(
        contract.name,
        contract.requestAddress,
        null,
        contract.requestCodec,
        contract.responseCodec,
        contract.responsePolicy,
        contract.failureSlug,
        Replying(contract.limits, received),
        message,
        handler,
    )

    private suspend fun <A : Any, Q : Any, R : Any> replying(
        contract: WatchContract<A, Q, R, *>,
        message: InboundMessage,
        received: TimeMark,
        handler: suspend (MainSpanScope, A, Q) -> R,
    ) = replying(
        contract.name,
        contract.requestAddress,
        contract.requestAddress.template,
        contract.requestCodec,
        contract.initialCodec,
        contract.initialPolicy,
        contract.failureSlug,
        Replying(contract.limits, received),
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
        replying: Replying,
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
                original.rethrowExceptional()
                sendInternalFailure(main, name, responseTemplate, responseCodec, policy, slug, replyTo, original, replying)
                throw original
            }
        val classification =
            try {
                policy.classify(response)
            } catch (original: Throwable) {
                original.rethrowExceptional()
                sendInternalFailure(main, name, responseTemplate, responseCodec, policy, slug, replyTo, original, replying)
                throw original
            }
        annotateResponse(main, classification)
        sendReply(name, responseTemplate, responseCodec, slug, replyTo, response, classification, replying)
        classification.operationOutcome(Unit)
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
        replying: Replying,
    ) {
        try {
            val response = policy.internalFailureResponse
            val classification = policy.classify(response)
            annotateResponse(main, classification)
            sendReply(name, template, codec, slug, replyTo, response, classification, replying)
        } catch (secondary: Throwable) {
            secondary.rethrowExceptional()
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
        replying: Replying,
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
                limits = replying.limits,
                received = replying.received,
            )
        if (sent is CommunicationResult.Failure) {
            throw SluggedException.wrap(sent.error.slug, sent.error.cause ?: IllegalStateException("Reply failed"))
        }
    }

    private suspend fun <Value> consume(
        name: OperationName,
        template: String,
        slug: ErrorSlug,
        message: InboundMessage,
        block: suspend (MainSpanScope) -> Value,
    ): Value {
        val parent = propagators.textMapPropagator.extract(Context.current(), message.headers, MessageHeadersGetter)
        return telemetry.consumerSpan(
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

    private class RouteCompleted(
        pattern: String,
    ) : RuntimeException("Required route $pattern completed")

    private class ShutdownTimeout(
        timeout: Duration,
    ) : RuntimeException("Router shutdown timed out after $timeout")

    private data class Runtime(
        val route: Route,
        val subscription: TransportSubscription,
        val channel: Channel<Received>,
        val collector: Job,
        val workers: List<Job>,
        val sweeper: Job?,
    ) {
        fun cancel() {
            collector.cancel()
            channel.cancel()
            workers.forEach(Job::cancel)
            sweeper?.cancel()
        }
    }

    private companion object {
        val ROUTE_TRANSPORT_SLUG: ErrorSlug = ErrorSlug.of("route-transport-failed")

        /** The warning event of a request dropped because its route does not answer its reply address. */
        const val REPLY_REFUSED_EVENT = "messaging.reply.refused"

        /** The refused reply address on [REPLY_REFUSED_EVENT]. */
        const val REPLY_ADDRESS_ATTRIBUTE = "messaging.reply.address"
    }
}

private fun <A : Any, Q : Any, R : Any> ScatterContract<A, Q, R>.asUnaryContract(): UnaryContract<A, Q, R> =
    UnaryContract(
        name = name,
        requestAddress = requestAddress,
        requestCodec = requestCodec,
        responseCodec = responseCodec,
        responsePolicy = responsePolicy,
        replyAddresses = replyAddresses,
        failureSlug = failureSlug,
        limits = limits,
    )

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
