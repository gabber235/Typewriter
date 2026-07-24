@file:OptIn(kotlinx.coroutines.ExperimentalCoroutinesApi::class)

package com.typewritermc.services.libs.communicator

import com.typewritermc.services.libs.communicator.address.MessageAddress
import com.typewritermc.services.libs.communicator.address.addressTemplate
import com.typewritermc.services.libs.communicator.address.addressValuesOf
import com.typewritermc.services.libs.communicator.client.Communicator
import com.typewritermc.services.libs.communicator.contract.*
import com.typewritermc.services.libs.communicator.router.*
import com.typewritermc.services.libs.communicator.testing.FakeMessageTransport
import com.typewritermc.services.libs.communicator.transport.InboundMessage
import com.typewritermc.services.libs.communicator.transport.MessageHeaders
import com.typewritermc.services.libs.communicator.transport.TransportDelivery
import com.typewritermc.services.libs.communicator.transport.TransportError
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator
import io.opentelemetry.context.propagation.ContextPropagators
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.async
import kotlinx.coroutines.delay
import kotlinx.coroutines.test.advanceTimeBy
import kotlinx.coroutines.test.runCurrent
import kotlinx.coroutines.test.runTest
import kotlin.time.Duration.Companion.milliseconds

private data class RouterTarget(val id: String)

private val routerAddress =
    addressTemplate("router.{id}.get", { addressValuesOf("id" to it.id) }, { RouterTarget(it.require("id")) })
private val routerCodec = object : PayloadCodec<String> {
    override fun encode(value: String) = value.encodeToByteArray()
    override fun decode(payload: ByteArray) = payload.decodeToString()
}
private val routerPolicy = ResponsePolicy("internal") {
    ResponseClassification(
        if (it == "internal") ResponseOutcome.INTERNAL_ERROR else ResponseOutcome.SUCCESS,
        ResponseVariant.of(if (it == "internal") "internal" else "success"),
    )
}
private val routerUnary = UnaryContract(
    OperationName.of("router.get"),
    routerAddress,
    routerCodec,
    routerCodec,
    routerPolicy,
    failureSlug = ErrorSlug.of("router-get-failed")
)
private val routerEvent = EventContract(
    OperationName.of("router.event"),
    routerAddress,
    routerCodec,
    ErrorSlug.of("router-event-failed"),
)

val CommunicatorRouterTest by testSuite {
    test("DSL validates parallelism and duplicate patterns before subscribing") {
        runTest {
            shouldThrow<IllegalArgumentException> { communicatorRoutes { unary(routerUnary, parallelism = 0) { "x" } } }
            val routes = communicatorRoutes { unary(routerUnary) { "a" }; unary(routerUnary) { "b" } }
            val fake = FakeMessageTransport()
            val harness = TelemetryTestHarness.create()
            val propagators = ContextPropagators.create(W3CTraceContextPropagator.getInstance())
            shouldThrow<IllegalArgumentException> {
                CommunicatorRouter(
                    fake,
                    routes,
                    Communicator(fake, harness.telemetry, propagators),
                    harness.telemetry,
                    propagators,
                    this
                )
            }
            fake.actions shouldBe emptyList()
            fake.close()
            harness.close()
        }
    }

    test("overlapping route patterns are rejected before subscribing") {
        runTest {
            val wildcardMiddle = EventContract(
                OperationName.of("service.middle.get"),
                addressTemplate(
                    "service.{id}.get",
                    { addressValuesOf("id" to it.id) },
                    { RouterTarget(it.require("id")) }),
                routerCodec,
                ErrorSlug.of("service-middle-failed"),
            )
            val wildcardEnd = EventContract(
                OperationName.of("service.alpha.any"),
                addressTemplate(
                    "service.alpha.{id}",
                    { addressValuesOf("id" to it.id) },
                    { RouterTarget(it.require("id")) }),
                routerCodec,
                ErrorSlug.of("service-alpha-failed"),
            )
            val routes = communicatorRoutes {
                event(wildcardMiddle) { }
                event(wildcardEnd) { }
            }
            val fake = FakeMessageTransport()
            val harness = TelemetryTestHarness.create()
            val propagators = ContextPropagators.create(W3CTraceContextPropagator.getInstance())
            try {
                shouldThrow<IllegalArgumentException> {
                    CommunicatorRouter(
                        fake,
                        routes,
                        Communicator(fake, harness.telemetry, propagators),
                        harness.telemetry,
                        propagators,
                        this,
                    )
                }
                fake.actions shouldBe emptyList()
            } finally {
                fake.close()
                harness.close()
            }
        }
    }

    test("typed call is processed, startup is ready, and stop is idempotent") {
        runTest {
            var observed: IncomingUnaryCall<RouterTarget, String, String>? = null
            val routes = communicatorRoutes { unary(routerUnary, parallelism = 1) { call -> observed = call; "ok" } }
            val fixture = routerFixture(routes, this)
            fixture.router.start() shouldBe RouterResult.Success
            fixture.router.state shouldBe RouterState.RUNNING
            fixture.fake.deliver(
                TransportDelivery.Message(
                    InboundMessage(
                        MessageAddress.of("router.alpha.get"),
                        "request".encodeToByteArray(),
                        MessageAddress.of("reply.alpha")
                    )
                )
            )
            runCurrent()
            observed?.address shouldBe RouterTarget("alpha")
            observed?.request shouldBe "request"
            fixture.fake.actions.filterIsInstance<FakeMessageTransport.Action.Publish>()
                .single().message.address shouldBe MessageAddress.of("reply.alpha")
            fixture.router.stop() shouldBe RouterResult.Success
            fixture.router.stop() shouldBe RouterResult.Success
            fixture.fake.actions.count { it is FakeMessageTransport.Action.SubscriptionClose } shouldBe 1
            fixture.harness.assertNoActiveSpans()
            fixture.close()
        }
    }

    test("double start and restart after stop fail fast") {
        runTest {
            val fixture = routerFixture(communicatorRoutes {
                event(
                    EventContract(
                        OperationName.of("router.event"),
                        routerAddress,
                        routerCodec,
                        ErrorSlug.of("router-event-failed")
                    )
                ) { }
            }, this)
            fixture.router.start()
            shouldThrow<IllegalStateException> { fixture.router.start() }
            fixture.router.stop()
            shouldThrow<IllegalStateException> { fixture.router.start() }
            fixture.close()
        }
    }

    test("partial startup failure closes every acquired subscription and ends stopped") {
        runTest {
            val routes = twoEventRoutes()
            val fixture = routerFixture(routes, this)
            fixture.use { fixture ->
                fixture.fake.failSubscribeAt(2, TransportError.Unavailable())
                (fixture.router.start() is RouterResult.Failure) shouldBe true
                fixture.router.state shouldBe RouterState.STOPPED
                fixture.fake.activeSubscriptionCount shouldBe 0
            }
        }
    }

    test("global and route limits bound accepted and executing messages") {
        runTest {
            val gate = kotlinx.coroutines.CompletableDeferred<Unit>()
            val active = java.util.concurrent.atomic.AtomicInteger()
            val entered = java.util.concurrent.atomic.AtomicInteger()
            val processed = java.util.concurrent.atomic.AtomicInteger()
            val maximum = java.util.concurrent.atomic.AtomicInteger()
            val routes = communicatorRoutes {
                event(routerEvent, parallelism = 2) {
                    entered.incrementAndGet()
                    val now = active.incrementAndGet()
                    maximum.updateAndGet { maxOf(it, now) }
                    gate.await()
                    active.decrementAndGet()
                    processed.incrementAndGet()
                }
            }
            val fixture = routerFixture(routes, this, RouterOptions(maxInFlight = 2, defaultRouteParallelism = 2))
            fixture.use { fixture ->
                fixture.router.start()
                repeat(4) { fixture.fake.deliver(message("router.$it.get")) }
                runCurrent()
                active.get() shouldBe 2
                entered.get() shouldBe 2
                maximum.get() shouldBe 2
                gate.complete(Unit)
                runCurrent()
                processed.get() shouldBe 4
                fixture.router.stop() shouldBe RouterResult.Success
            }
        }
    }

    test("parallelism one preserves message order and ordinary handler failure does not stop later messages") {
        runTest {
            val observed = mutableListOf<String>()
            val routes = communicatorRoutes {
                event(routerEvent, parallelism = 1) { call ->
                    observed += call.event
                    if (call.event == "first") error("ordinary")
                }
            }
            val fixture = routerFixture(routes, this)
            fixture.use { fixture ->
                fixture.router.start()
                fixture.fake.deliver(message("router.a.get", "first"))
                fixture.fake.deliver(message("router.b.get", "second"))
                runCurrent()
                observed shouldBe listOf("first", "second")
                fixture.router.state shouldBe RouterState.RUNNING
                fixture.router.stop()
            }
        }
    }

    test("missing reply creates error consumer span and publishes nothing") {
        runTest {
            val fixture = routerFixture(communicatorRoutes { unary(routerUnary) { "ok" } }, this)
            fixture.use { fixture ->
                fixture.router.start()
                fixture.fake.deliver(message("router.a.get"))
                runCurrent()
                fixture.fake.actions.filterIsInstance<FakeMessageTransport.Action.Publish>() shouldBe emptyList()
                fixture.harness.finishedSpans()
                    .single { it.name == "router.get receive" }.status.statusCode.name shouldBe "ERROR"
                fixture.router.stop()
            }
        }
    }

    test("domain and handler-returned internal responses annotate consumer correctly and internal publishes once") {
        runTest {
            val policy = ResponsePolicy(
                "internal",
            ) {
                ResponseClassification(
                    if (it == "internal") ResponseOutcome.INTERNAL_ERROR else ResponseOutcome.DOMAIN_ERROR,
                    ResponseVariant.of(it)
                )
            }
            val contract = UnaryContract(
                OperationName.of("router.classified"),
                routerAddress,
                routerCodec,
                routerCodec,
                policy,
                failureSlug = ErrorSlug.of("router-classified-failed")
            )
            val fixture = routerFixture(communicatorRoutes { unary(contract) { it.request } }, this)
            fixture.use { fixture ->
                fixture.router.start()
                fixture.fake.deliver(message("router.a.get", "domain", "reply.one"))
                fixture.fake.deliver(message("router.b.get", "internal", "reply.two"))
                runCurrent()
                fixture.fake.actions.filterIsInstance<FakeMessageTransport.Action.Publish>().size shouldBe 2
                val spans = fixture.harness.finishedSpans().filter { it.name == "router.classified receive" }
                spans.map { it.attributes.get(io.opentelemetry.api.common.AttributeKey.stringKey("domain.outcome")) } shouldBe listOf(
                    "domain",
                    "internal"
                )
                spans.map { it.status.statusCode.name } shouldBe listOf("UNSET", "ERROR")
                fixture.router.stop()
            }
        }
    }

    test("terminal transport failure records error and stops router with subscriptions closed") {
        runTest {
            val fixture = routerFixture(twoEventRoutes(), this)
            fixture.use { fixture ->
                fixture.router.start()
                fixture.fake.deliver(TransportDelivery.Failure(TransportError.Unavailable()))
                runCurrent()
                fixture.router.state shouldBe RouterState.STOPPED
                fixture.fake.activeSubscriptionCount shouldBe 0
                fixture.harness.finishedSpans()
                    .any { it.name == "route receive" && it.status.statusCode.name == "ERROR" } shouldBe true
            }
        }
    }

    test("graceful stop drains accepted work while timeout stop returns promptly and cancels blocked work") {
        runTest {
            var drained = false
            val drainGate = kotlinx.coroutines.CompletableDeferred<Unit>()
            val draining = routerFixture(
                communicatorRoutes { event(routerEvent, parallelism = 1) { drainGate.await(); drained = true } },
                this,
            )
            draining.use { draining ->
                draining.router.start()
                draining.fake.deliver(message("router.drain.get"))
                runCurrent()
                val graceful = async { draining.router.stop() }
                runCurrent()
                graceful.isCompleted shouldBe false
                drainGate.complete(Unit)
                runCurrent()
                graceful.await() shouldBe RouterResult.Success
                drained shouldBe true
            }

            val gate = kotlinx.coroutines.CompletableDeferred<Unit>()
            val fixture = routerFixture(
                communicatorRoutes { event(routerEvent, parallelism = 1) { gate.await() } },
                this,
                RouterOptions(shutdownTimeout = kotlin.time.Duration.parse("1s")),
            )
            fixture.use { fixture ->
                fixture.router.start()
                fixture.fake.deliver(message("router.a.get"))
                runCurrent()
                val stopped = async { fixture.router.stop() }
                advanceTimeBy(1_001.milliseconds)
                runCurrent()
                (stopped.await() is RouterResult.Failure) shouldBe true
                fixture.router.state shouldBe RouterState.STOPPED
            }
        }
    }

    test("cancelled stop owner finalizes shared shutdown") {
        runTest {
            val fixture = routerFixture(communicatorRoutes { event(routerEvent) { } }, this)
            fixture.use { fixture ->
                fixture.fake.closeSubscriptionWith(1) { delay(1_000.milliseconds) }
                fixture.router.start()
                val owner = async { fixture.router.stop() }
                runCurrent()
                owner.cancel()
                advanceTimeBy(1_000.milliseconds)
                runCurrent()
                owner.join()
                fixture.router.state shouldBe RouterState.STOPPED
                fixture.router.stop() shouldBe RouterResult.Success
            }
        }
    }

    @Suppress("DEPRECATION")
    test("exceptional subscription close still attempts every close and stops") {
        runTest {
            listOf(
                CancellationException("close cancelled"),
                LinkageError("fatal close"),
                ThreadDeath(),
            ).forEach { failure ->
                val fixture = routerFixture(twoEventRoutes(), this)
                var secondCloseAttempted = false
                fixture.use { fixture ->
                    fixture.fake.closeSubscriptionWith(1) { throw failure }
                    fixture.fake.closeSubscriptionWith(2) { secondCloseAttempted = true }
                    fixture.router.start()
                    shouldThrow<Throwable> { fixture.router.stop() } shouldBe failure
                    secondCloseAttempted shouldBe true
                    fixture.router.state shouldBe RouterState.STOPPED
                    shouldThrow<Throwable> { fixture.router.stop() } shouldBe failure
                }
            }
        }
    }

    test("suppressed exceptional subscription close escapes exactly") {
        runTest {
            val cancellation = CancellationException("suppressed cancellation")
            val closeFailure = IllegalStateException("close").apply { addSuppressed(cancellation) }
            val fixture = routerFixture(communicatorRoutes { event(routerEvent) { } }, this)
            fixture.use { fixture ->
                fixture.fake.closeSubscriptionWith(1) { throw closeFailure }
                fixture.router.start()
                shouldThrow<Throwable> { fixture.router.stop() } shouldBe cancellation
                fixture.router.state shouldBe RouterState.STOPPED
            }
        }
    }

    test("shutdown timeout uses one absolute deadline") {
        runTest {
            val fixture = routerFixture(
                communicatorRoutes { event(routerEvent, parallelism = 1) { delay(Long.MAX_VALUE.milliseconds) } },
                this,
                RouterOptions(shutdownTimeout = kotlin.time.Duration.parse("1s")),
            )
            fixture.use { fixture ->
                fixture.fake.closeSubscriptionWith(1) { delay(Long.MAX_VALUE.milliseconds) }
                fixture.router.start()
                fixture.fake.deliver(message("router.a.get"))
                runCurrent()
                val startedAt = testScheduler.currentTime
                val stopped = async { fixture.router.stop() }
                advanceTimeBy(1_000.milliseconds)
                runCurrent()
                (stopped.await() is RouterResult.Failure) shouldBe true
                testScheduler.currentTime - startedAt shouldBe 1_000
            }
        }
    }

    test("reply traceparent is child of extracted remote context") {
        runTest {
            val fixture = routerFixture(communicatorRoutes { unary(routerUnary) { "ok" } }, this)
            fixture.use { fixture ->
                fixture.router.start()
                val headers =
                    MessageHeaders.of("traceparent" to "00-11111111111111111111111111111111-2222222222222222-01")
                fixture.fake.deliver(
                    TransportDelivery.Message(
                        InboundMessage(
                            MessageAddress.of("router.a.get"),
                            byteArrayOf(),
                            MessageAddress.of("reply.a"),
                            headers
                        )
                    )
                )
                runCurrent()
                val consumer = fixture.harness.finishedSpans().single { it.name == "router.get receive" }
                val producer = fixture.harness.finishedSpans().single { it.name == "router.get publish" }
                consumer.parentSpanId shouldBe "2222222222222222"
                producer.parentSpanId shouldBe consumer.spanId
                producer.attributes.get(io.opentelemetry.api.common.AttributeKey.stringKey("messaging.destination.template")) shouldBe null
                fixture.router.stop()
            }
        }
    }
}

private class RouterFixture(
    val router: CommunicatorRouter,
    val fake: FakeMessageTransport,
    val harness: TelemetryTestHarness,
) : AutoCloseable {
    override fun close() {
        fake.close()
        harness.close()
    }
}

private fun twoEventRoutes() = communicatorRoutes {
    event(routerEvent) { }
    event(
        EventContract(
            OperationName.of("router.other"),
            addressTemplate("other.{id}.get", { addressValuesOf("id" to it.id) }, { RouterTarget(it.require("id")) }),
            routerCodec,
            ErrorSlug.of("router-other-failed"),
        ),
    ) { }
}

private fun message(address: String, payload: String = "message", replyTo: String? = null) = TransportDelivery.Message(
    InboundMessage(
        MessageAddress.of(address),
        payload.encodeToByteArray(),
        replyTo?.let(MessageAddress::of),
    ),
)

private fun routerFixture(
    routes: CommunicatorRoutes,
    scope: kotlinx.coroutines.CoroutineScope,
    options: RouterOptions = RouterOptions(),
): RouterFixture {
    val fake = FakeMessageTransport()
    val harness = TelemetryTestHarness.create()
    val propagators = ContextPropagators.create(W3CTraceContextPropagator.getInstance())
    val communicator = Communicator(fake, harness.telemetry, propagators)
    return RouterFixture(
        CommunicatorRouter(fake, routes, communicator, harness.telemetry, propagators, scope, options),
        fake,
        harness,
    )
}
