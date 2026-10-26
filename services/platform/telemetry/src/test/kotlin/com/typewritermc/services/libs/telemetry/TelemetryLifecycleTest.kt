package com.typewritermc.services.libs.telemetry

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.types.shouldBeSameInstanceAs
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.trace.Span
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.context.Context
import io.opentelemetry.sdk.OpenTelemetrySdk
import io.opentelemetry.sdk.common.CompletableResultCode
import io.opentelemetry.sdk.testing.exporter.InMemorySpanExporter
import io.opentelemetry.sdk.trace.SdkTracerProvider
import io.opentelemetry.sdk.trace.data.SpanData
import io.opentelemetry.sdk.trace.export.SimpleSpanProcessor
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.coroutines.yield
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit

val TelemetryLifecycleTest by testSuite {
    test("blocking context is current and restored") {
        TestTelemetry().use { test ->
            val outer =
                test.openTelemetry
                    .getTracer("outer")
                    .spanBuilder("outer")
                    .startSpan()
            try {
                outer.makeCurrent().use {
                    test.telemetry.mainSpanBlocking("main", slug("main-failed")) { _ ->
                        Span.current().spanContext.traceId shouldBe outer.spanContext.traceId
                        Span.current().spanContext.spanId shouldNotBe outer.spanContext.spanId
                        Context.current().mainSpanScope() shouldNotBe null
                    }
                    Span.current().spanContext.spanId shouldBe outer.spanContext.spanId
                }
            } finally {
                outer.end()
            }
            Span.current().spanContext.isValid shouldBe false
        }
    }

    test("suspend context survives dispatchers and structured children") {
        TestTelemetry().use { test ->
            test.telemetry.mainSpan("main", slug("main-failed")) { main ->
                val mainSpanId = Span.current().spanContext.spanId
                yield()
                withContext(Dispatchers.Default) {
                    Span.current().spanContext.spanId shouldBe mainSpanId
                    Context.current().mainSpanScope() shouldBeSameInstanceAs main
                }
                withContext(Dispatchers.IO) {
                    Span.current().spanContext.spanId shouldBe mainSpanId
                }
                coroutineScope {
                    val launched = launch { Span.current().spanContext.spanId shouldBe mainSpanId }
                    val deferred = async { Span.current().spanContext.spanId }
                    launched.join()
                    deferred.await() shouldBe mainSpanId
                }
            }
            Span.current().spanContext.isValid shouldBe false
            test.spans().size shouldBe 1
        }
    }

    test("main annotations stay on main while nested children form a tree") {
        TestTelemetry().use { test ->
            test.telemetry.mainSpanBlocking("main", slug("main-failed")) { main ->
                main.annotate { attribute("main.only", true) }
                childSpanBlocking("child") { child ->
                    child.annotate { attribute("child.only", true) }
                    childSpanBlocking("grandchild") { grandchild ->
                        grandchild.annotate { attribute("grandchild.only", true) }
                        main.annotate { attribute("main.late", true) }
                    }
                }
            }

            val main = test.span("main")
            val child = test.span("child")
            val grandchild = test.span("grandchild")
            child.parentSpanId shouldBe main.spanId
            grandchild.parentSpanId shouldBe child.spanId
            child.traceId shouldBe main.traceId
            grandchild.traceId shouldBe main.traceId
            main.attributes[AttributeKey.booleanKey("main.only")] shouldBe true
            main.attributes[AttributeKey.booleanKey("main.late")] shouldBe true
            main.attributes[AttributeKey.booleanKey("child.only")] shouldBe null
            child.attributes[AttributeKey.booleanKey("child.only")] shouldBe true
        }
    }

    test("captured scopes and attribute writers reject use after close") {
        TestTelemetry().use { test ->
            lateinit var mainScope: MainSpanScope
            lateinit var childScope: ChildSpanScope
            lateinit var mainAttributes: MainAttributes
            lateinit var childAttributes: ChildAttributes

            test.telemetry.mainSpanBlocking("main", slug("main-failed")) { main ->
                mainScope = main
                main.annotate { mainAttributes = this }
                childSpanBlocking("child") { child ->
                    childScope = child
                    child.annotate { childAttributes = this }
                }
            }

            shouldThrow<IllegalStateException> { mainScope.annotate { attribute("late", true) } }
            shouldThrow<IllegalStateException> { childScope.annotate { attribute("late", true) } }
            shouldThrow<IllegalStateException> { mainAttributes.attribute("late", true) }
            shouldThrow<IllegalStateException> { childAttributes.attribute("late", true) }
            context(mainScope) {
                shouldThrow<IllegalStateException> { childSpanBlocking("late-child") { _ -> } }
            }
            test.spans().size shouldBe 2
        }
    }

    Boundary.entries.forEach { boundary ->
        test("cancellation at a ${boundary.label} boundary is unwrapped, not an error, and always ends the span") {
            TestTelemetry().use { test ->
                val cancellation = CancellationException("shutdown")

                val thrown = shouldThrow<CancellationException> { boundary.failMain(test.telemetry, slug("main-failed"), cancellation) }

                // Coroutine stack trace recovery may rethrow a copy across a suspension, so the message identifies it.
                thrown.message shouldBe cancellation.message
                val span = test.span("main")
                span.status.statusCode shouldBe StatusCode.UNSET
                span.attributes[AttributeKey.booleanKey("operation.cancelled")] shouldBe true
                span.events.any { it.name == "exception" } shouldBe false
            }
        }

        test("a source slug at a ${boundary.label} boundary reaches child and main without double wrapping") {
            TestTelemetry().use { test ->
                val cause = IllegalArgumentException("private details")

                val thrown =
                    shouldThrow<SluggedException> {
                        boundary.failChild(test.telemetry, slug("main-fallback"), slug("repository-load-failed"), cause)
                    }

                thrown.cause shouldBeSameInstanceAs cause
                thrown.slug.value shouldBe "repository-load-failed"
                listOf(test.span("main"), test.span("child")).forEach { span ->
                    span.status.statusCode shouldBe StatusCode.ERROR
                    span.attributes[AttributeKey.stringKey("exception.slug")] shouldBe "repository-load-failed"
                    span.attributes[AttributeKey.stringKey("error.type")] shouldBe IllegalArgumentException::class.java.name
                    span.status.description shouldBe "repository-load-failed"
                }
            }
        }
    }

    test("plain child failure receives fallback only at main boundary") {
        TestTelemetry().use { test ->
            val cause = IllegalStateException("secret response body")
            val thrown =
                shouldThrow<SluggedException> {
                    test.telemetry.mainSpanBlocking("main", slug("main-unhandled")) { _ ->
                        childSpanBlocking("child") { _ -> throw cause }
                    }
                }
            thrown.cause shouldBeSameInstanceAs cause
            val child = test.span("child")
            val main = test.span("main")
            child.attributes[AttributeKey.stringKey("exception.slug")] shouldBe null
            child.status.description shouldBe IllegalStateException::class.java.name
            main.attributes[AttributeKey.stringKey("exception.slug")] shouldBe "main-unhandled"
            main.status.description shouldBe "main-unhandled"
            main.status.description.contains("secret") shouldBe false
        }
    }

    test("suppressed slugged cleanup failure becomes additional event") {
        TestTelemetry().use { test ->
            val cause = IllegalStateException("primary")
            cause.addSuppressed(SluggedException.wrap(slug("cleanup-failed"), IllegalArgumentException("cleanup")))
            val primary = SluggedException.wrap(slug("primary-failed"), cause)
            shouldThrow<SluggedException> {
                test.telemetry.mainSpanBlocking("main", slug("main-fallback")) { _ -> throw primary }
            } shouldBeSameInstanceAs primary
            val span = test.span("main")
            span.attributes[AttributeKey.stringKey("exception.slug")] shouldBe "primary-failed"
            val additional = span.events.single { it.name == "exception.additional" }
            additional.attributes[AttributeKey.stringKey("exception.slug")] shouldBe "cleanup-failed"
            additional.attributes[AttributeKey.stringKey("exception.stacktrace")]!!
                .contains("IllegalArgumentException") shouldBe true
        }
    }

    test("degraded and domain outcomes remain non-error") {
        TestTelemetry().use { test ->
            test.telemetry.mainSpanBlocking("main", slug("main-failed")) { main ->
                main.annotate { domainOutcome("not-found") }
                main.recordDegraded(slug("cache-read-failed"), IllegalStateException("cache"))
            }
            val span = test.span("main")
            span.status.statusCode shouldBe StatusCode.UNSET
            span.attributes[AttributeKey.stringKey("domain.outcome")] shouldBe "not-found"
            span.attributes[AttributeKey.booleanKey("operation.degraded")] shouldBe true
            span.events.any { it.name == "exception.degraded" } shouldBe true
        }
    }

    test("normal teardown never overwrites explicit error status") {
        TestTelemetry().use { test ->
            test.telemetry.mainSpanBlocking("main", slug("main-failed")) { _ ->
                Span.current().setStatus(StatusCode.ERROR, "explicit")
            }
            test.span("main").status.statusCode shouldBe StatusCode.ERROR
        }
    }

    test("typed universal helpers emit semantic keys and correlation") {
        TestTelemetry().use { test ->
            test.telemetry.mainSpanBlocking("main", slug("main-failed")) { main ->
                main.annotate {
                    httpRequestMethod("POST")
                    httpRoute("/services/{id}")
                    httpResponseStatusCode(202)
                    messagingSystem("nats")
                    messagingDestinationName("services.status")
                    featureFlag("new_flow", true)
                    attribute("ratio", 0.5)
                }
                childSpanBlocking("db") { child ->
                    child.annotate {
                        dbOperationName("select")
                        dbResponseStatusCode("ok")
                        serverPort(8000)
                    }
                }
            }
            val main = test.span("main")
            main.attributes[AttributeKey.stringKey("trace_id")] shouldBe main.traceId
            main.attributes[AttributeKey.stringKey("span_id")] shouldBe main.spanId
            main.attributes[AttributeKey.stringKey("http.request.method")] shouldBe "POST"
            main.attributes[AttributeKey.longKey("http.response.status_code")] shouldBe 202L
            main.attributes[AttributeKey.booleanKey("feature_flag.new_flow")] shouldBe true
            main.attributes[AttributeKey.doubleKey("ratio")] shouldBe 0.5
            val child = test.span("db")
            child.attributes[AttributeKey.stringKey("db.operation.name")] shouldBe "select"
            child.attributes[AttributeKey.longKey("server.port")] shouldBe 8000L
        }
    }

    test("concurrent counter exports exact final value") {
        TestTelemetry().use { test ->
            val counter = CounterKey("stats.db_query_count")
            test.telemetry.mainSpan("main", slug("main-failed")) { main ->
                coroutineScope {
                    repeat(500) { launch(Dispatchers.Default) { main.annotate { increment(counter) } } }
                }
            }
            test.span("main").attributes[AttributeKey.longKey(counter.value)] shouldBe 500L
        }
    }

    test("annotation blocks do not lock out concurrent attribute writers") {
        TestTelemetry().use { test ->
            val executor = Executors.newSingleThreadExecutor()
            try {
                test.telemetry.mainSpanBlocking("main", slug("main-failed")) { main ->
                    main.annotate {
                        val attributes = this
                        executor
                            .submit { attributes.attribute("concurrent.value", true) }
                            .get(2, TimeUnit.SECONDS)
                    }
                }
            } finally {
                executor.shutdownNow()
                executor.awaitTermination(2, TimeUnit.SECONDS) shouldBe true
            }
            test.span("main").attributes[AttributeKey.booleanKey("concurrent.value")] shouldBe true
        }
    }

    test("fatal failures escape main boundaries unchanged without error telemetry") {
        TestTelemetry().use { test ->
            val fatal = TestVirtualMachineError()
            shouldThrow<TestVirtualMachineError> {
                test.telemetry.mainSpanBlocking("fatal-main", slug("fallback")) { _ -> throw fatal }
            } shouldBeSameInstanceAs fatal
            val span = test.span("fatal-main")
            span.status.statusCode shouldBe StatusCode.UNSET
            span.events.any { it.name == "exception" } shouldBe false
            test.spans().size shouldBe 1
        }
    }

    test("cause-wrapped fatal failures escape child boundaries unchanged without error telemetry") {
        TestTelemetry().use { test ->
            val fatal = TestVirtualMachineError()
            shouldThrow<TestVirtualMachineError> {
                test.telemetry.mainSpanBlocking("fatal-parent", slug("fallback")) { _ ->
                    childSpanBlocking("fatal-child") { _ -> throw IllegalStateException("wrapper", fatal) }
                }
            } shouldBeSameInstanceAs fatal
            listOf(test.span("fatal-parent"), test.span("fatal-child")).forEach { span ->
                span.status.statusCode shouldBe StatusCode.UNSET
                span.events.any { it.name == "exception" } shouldBe false
            }
            test.spans().size shouldBe 2
        }
    }
}

private fun slug(value: String) = ErrorSlug.of(value)

/** The blocking and the suspending span boundaries, which follow one failure policy. */
private enum class Boundary(
    val label: String,
) {
    BLOCKING("blocking") {
        override suspend fun failMain(
            telemetry: ServiceTelemetry,
            fallback: ErrorSlug,
            failure: Throwable,
        ) {
            telemetry.mainSpanBlocking<Unit>("main", fallback) { _ -> throw failure }
        }

        override suspend fun failChild(
            telemetry: ServiceTelemetry,
            fallback: ErrorSlug,
            source: ErrorSlug,
            failure: Throwable,
        ) {
            telemetry.mainSpanBlocking<Unit>("main", fallback) { _ ->
                childSpanBlocking("child") { _ -> withErrorSlug(source) { throw failure } }
            }
        }
    },
    SUSPENDING("suspending") {
        override suspend fun failMain(
            telemetry: ServiceTelemetry,
            fallback: ErrorSlug,
            failure: Throwable,
        ) {
            telemetry.mainSpan<Unit>("main", fallback) { _ -> throw failure }
        }

        override suspend fun failChild(
            telemetry: ServiceTelemetry,
            fallback: ErrorSlug,
            source: ErrorSlug,
            failure: Throwable,
        ) {
            telemetry.mainSpan<Unit>("main", fallback) { _ ->
                childSpan("child") { _ -> withErrorSlugSuspending(source) { throw failure } }
            }
        }
    },
    ;

    /** Runs a main span named `main` whose work throws [failure]. */
    abstract suspend fun failMain(
        telemetry: ServiceTelemetry,
        fallback: ErrorSlug,
        failure: Throwable,
    )

    /** Runs a main span `main` with a child span `child` whose work throws [failure] under [source]. */
    abstract suspend fun failChild(
        telemetry: ServiceTelemetry,
        fallback: ErrorSlug,
        source: ErrorSlug,
        failure: Throwable,
    )
}

private class TestVirtualMachineError : VirtualMachineError("test fatal")

private class TestTelemetry : AutoCloseable {
    private val exporter = InMemorySpanExporter.create()
    private val provider =
        SdkTracerProvider
            .builder()
            .addSpanProcessor(SimpleSpanProcessor.create(exporter))
            .build()
    val openTelemetry: OpenTelemetrySdk = OpenTelemetrySdk.builder().setTracerProvider(provider).build()
    val telemetry = ServiceTelemetry(openTelemetry, InstrumentationScope("test", "1.2.3"))

    fun spans(): List<SpanData> = exporter.finishedSpanItems

    fun span(name: String): SpanData = spans().single { it.name == name }

    override fun close() {
        await("force flush", provider.forceFlush())
        await("shutdown", provider.shutdown())
        exporter.close()
    }

    private fun await(
        operation: String,
        result: CompletableResultCode,
    ) {
        result.join(10, TimeUnit.SECONDS)
        check(result.isDone) { "Telemetry $operation timed out" }
        check(result.isSuccess) { "Telemetry $operation failed" }
    }
}
