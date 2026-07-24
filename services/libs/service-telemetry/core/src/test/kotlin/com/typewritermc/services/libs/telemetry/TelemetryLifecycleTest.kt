package com.typewritermc.services.libs.telemetry

import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.trace.Span
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.context.Context
import io.opentelemetry.sdk.OpenTelemetrySdk
import io.opentelemetry.sdk.testing.exporter.InMemorySpanExporter
import io.opentelemetry.sdk.trace.SdkTracerProvider
import io.opentelemetry.sdk.trace.data.SpanData
import io.opentelemetry.sdk.trace.export.SimpleSpanProcessor
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.launch
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.withContext
import kotlinx.coroutines.yield
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.kotest.matchers.types.shouldBeSameInstanceAs

val TelemetryLifecycleTest by testSuite {
    test("blocking context is current and restored") { TelemetryLifecycleCases.`blocking context is current and restored`() }
    test("suspend context survives dispatchers and structured children") { TelemetryLifecycleCases.`suspend context survives dispatchers and structured children`() }
    test("main annotations stay on main while nested children form a tree") { TelemetryLifecycleCases.`main annotations stay on main while nested children form a tree`() }
    test("captured scopes and attribute writers reject use after close") { TelemetryLifecycleCases.`captured scopes and attribute writers reject use after close`() }
    test("cancellation is unwrapped non-error and always ends") { TelemetryLifecycleCases.`cancellation is unwrapped non-error and always ends`() }
    test("source slug propagates through child and main without double wrapping") { TelemetryLifecycleCases.`source slug propagates through child and main without double wrapping`() }
    test("plain child failure receives fallback only at main boundary") { TelemetryLifecycleCases.`plain child failure receives fallback only at main boundary`() }
    test("suppressed slugged cleanup failure becomes additional event") { TelemetryLifecycleCases.`suppressed slugged cleanup failure becomes additional event`() }
    test("degraded and domain outcomes remain non-error") { TelemetryLifecycleCases.`degraded and domain outcomes remain non-error`() }
    test("normal teardown never overwrites explicit error status") { TelemetryLifecycleCases.`normal teardown never overwrites explicit error status`() }
    test("typed universal helpers emit semantic keys and correlation") { TelemetryLifecycleCases.`typed universal helpers emit semantic keys and correlation`() }
    test("concurrent counter exports exact final value") { TelemetryLifecycleCases.`concurrent counter exports exact final value`() }
    test("annotation blocks do not lock out concurrent attribute writers") { TelemetryLifecycleCases.`annotation blocks do not lock out concurrent attribute writers`() }
    test("suspend failures and cancellation follow boundary policy") { TelemetryLifecycleCases.`suspend failures and cancellation follow boundary policy`() }
}

private object TelemetryLifecycleCases {
    fun `blocking context is current and restored`() = TestTelemetry().use { test ->
        val outer = test.openTelemetry.getTracer("outer").spanBuilder("outer").startSpan()
        outer.makeCurrent().use {
            test.telemetry.mainSpanBlocking("main", slug("main-failed")) { _ ->
                assertEquals(outer.spanContext.traceId, Span.current().spanContext.traceId)
                assertNotEquals(outer.spanContext.spanId, Span.current().spanContext.spanId)
                assertTrue(Context.current().mainSpanScope() != null)
            }
            assertEquals(outer.spanContext.spanId, Span.current().spanContext.spanId)
        }
        outer.end()
        assertFalse(Span.current().spanContext.isValid)
    }

    fun `suspend context survives dispatchers and structured children`() = runTest {
        TestTelemetry().use { test ->
            test.telemetry.mainSpan("main", slug("main-failed")) { main ->
                val mainSpanId = Span.current().spanContext.spanId
                yield()
                withContext(Dispatchers.Default) {
                    assertEquals(mainSpanId, Span.current().spanContext.spanId)
                    assertSame(main, Context.current().mainSpanScope())
                }
                withContext(Dispatchers.IO) {
                    assertEquals(mainSpanId, Span.current().spanContext.spanId)
                }
                coroutineScope {
                    val launched = launch { assertEquals(mainSpanId, Span.current().spanContext.spanId) }
                    val deferred = async { Span.current().spanContext.spanId }
                    launched.join()
                    assertEquals(mainSpanId, deferred.await())
                }
            }
            assertFalse(Span.current().spanContext.isValid)
            assertEquals(1, test.spans().size)
        }
    }

    fun `main annotations stay on main while nested children form a tree`() = TestTelemetry().use { test ->
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
        assertEquals(main.spanId, child.parentSpanId)
        assertEquals(child.spanId, grandchild.parentSpanId)
        assertEquals(main.traceId, child.traceId)
        assertEquals(main.traceId, grandchild.traceId)
        assertEquals(true, main.attributes[AttributeKey.booleanKey("main.only")])
        assertEquals(true, main.attributes[AttributeKey.booleanKey("main.late")])
        assertNull(main.attributes[AttributeKey.booleanKey("child.only")])
        assertEquals(true, child.attributes[AttributeKey.booleanKey("child.only")])
    }

    fun `captured scopes and attribute writers reject use after close`() = TestTelemetry().use { test ->
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

        assertFailsWith<IllegalStateException> { mainScope.annotate { attribute("late", true) } }
        assertFailsWith<IllegalStateException> { childScope.annotate { attribute("late", true) } }
        assertFailsWith<IllegalStateException> { mainAttributes.attribute("late", true) }
        assertFailsWith<IllegalStateException> { childAttributes.attribute("late", true) }
        context(mainScope) {
            assertFailsWith<IllegalStateException> { childSpanBlocking("late-child") { _ -> } }
        }
        assertEquals(2, test.spans().size)
    }

    fun `cancellation is unwrapped non-error and always ends`() = TestTelemetry().use { test ->
        val cancellation = CancellationException("shutdown")
        val thrown = assertFailsWith<CancellationException> {
            test.telemetry.mainSpanBlocking("main", slug("main-failed")) { _ -> throw cancellation }
        }
        assertSame(cancellation, thrown)
        val span = test.span("main")
        assertEquals(StatusCode.UNSET, span.status.statusCode)
        assertEquals(true, span.attributes[AttributeKey.booleanKey("operation.cancelled")])
        assertFalse(span.events.any { it.name == "exception" })
    }

    fun `source slug propagates through child and main without double wrapping`() = TestTelemetry().use { test ->
        val cause = IllegalArgumentException("private details")
        val thrown = assertFailsWith<SluggedException> {
            test.telemetry.mainSpanBlocking("main", slug("main-fallback")) { _ ->
                childSpanBlocking("child") { _ ->
                    withErrorSlug(slug("repository-load-failed")) { throw cause }
                }
            }
        }
        assertSame(cause, thrown.cause)
        assertEquals("repository-load-failed", thrown.slug.value)
        listOf(test.span("main"), test.span("child")).forEach { span ->
            assertEquals(StatusCode.ERROR, span.status.statusCode)
            assertEquals("repository-load-failed", span.attributes[AttributeKey.stringKey("exception.slug")])
            assertEquals(IllegalArgumentException::class.java.name, span.attributes[AttributeKey.stringKey("error.type")])
            assertEquals("repository-load-failed", span.status.description)
        }
    }

    fun `plain child failure receives fallback only at main boundary`() = TestTelemetry().use { test ->
        val cause = IllegalStateException("secret response body")
        val thrown = assertFailsWith<SluggedException> {
            test.telemetry.mainSpanBlocking("main", slug("main-unhandled")) { _ ->
                childSpanBlocking("child") { _ -> throw cause }
            }
        }
        assertSame(cause, thrown.cause)
        val child = test.span("child")
        val main = test.span("main")
        assertNull(child.attributes[AttributeKey.stringKey("exception.slug")])
        assertEquals(IllegalStateException::class.java.name, child.status.description)
        assertEquals("main-unhandled", main.attributes[AttributeKey.stringKey("exception.slug")])
        assertEquals("main-unhandled", main.status.description)
        assertFalse(main.status.description.contains("secret"))
    }

    fun `suppressed slugged cleanup failure becomes additional event`() = TestTelemetry().use { test ->
        val cause = IllegalStateException("primary")
        cause.addSuppressed(SluggedException.wrap(slug("cleanup-failed"), IllegalArgumentException("cleanup")))
        val primary = SluggedException.wrap(slug("primary-failed"), cause)
        assertSame(primary, assertFailsWith<SluggedException> {
            test.telemetry.mainSpanBlocking("main", slug("main-fallback")) { _ -> throw primary }
        })
        val span = test.span("main")
        assertEquals("primary-failed", span.attributes[AttributeKey.stringKey("exception.slug")])
        val additional = span.events.single { it.name == "exception.additional" }
        assertEquals("cleanup-failed", additional.attributes[AttributeKey.stringKey("exception.slug")])
        assertTrue(additional.attributes[AttributeKey.stringKey("exception.stacktrace")]!!.contains("IllegalArgumentException"))
    }

    fun `degraded and domain outcomes remain non-error`() = TestTelemetry().use { test ->
        test.telemetry.mainSpanBlocking("main", slug("main-failed")) { main ->
            main.annotate { domainOutcome("not-found") }
            main.recordDegraded(slug("cache-read-failed"), IllegalStateException("cache"))
        }
        val span = test.span("main")
        assertEquals(StatusCode.UNSET, span.status.statusCode)
        assertEquals("not-found", span.attributes[AttributeKey.stringKey("domain.outcome")])
        assertEquals(true, span.attributes[AttributeKey.booleanKey("operation.degraded")])
        assertTrue(span.events.any { it.name == "exception.degraded" })
    }

    fun `normal teardown never overwrites explicit error status`() = TestTelemetry().use { test ->
        test.telemetry.mainSpanBlocking("main", slug("main-failed")) { _ ->
            Span.current().setStatus(StatusCode.ERROR, "explicit")
        }
        assertEquals(StatusCode.ERROR, test.span("main").status.statusCode)
    }

    fun `typed universal helpers emit semantic keys and correlation`() = TestTelemetry().use { test ->
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
        assertEquals(main.traceId, main.attributes[AttributeKey.stringKey("trace_id")])
        assertEquals(main.spanId, main.attributes[AttributeKey.stringKey("span_id")])
        assertEquals("POST", main.attributes[AttributeKey.stringKey("http.request.method")])
        assertEquals(202L, main.attributes[AttributeKey.longKey("http.response.status_code")])
        assertEquals(true, main.attributes[AttributeKey.booleanKey("feature_flag.new_flow")])
        assertEquals(0.5, main.attributes[AttributeKey.doubleKey("ratio")])
        val child = test.span("db")
        assertEquals("select", child.attributes[AttributeKey.stringKey("db.operation.name")])
        assertEquals(8000L, child.attributes[AttributeKey.longKey("server.port")])
    }

    fun `concurrent counter exports exact final value`() = runTest {
        TestTelemetry().use { test ->
            val counter = CounterKey("stats.db_query_count")
            test.telemetry.mainSpan("main", slug("main-failed")) { main ->
                coroutineScope {
                    repeat(500) { launch(Dispatchers.Default) { main.annotate { increment(counter) } } }
                }
            }
            assertEquals(500L, test.span("main").attributes[AttributeKey.longKey(counter.value)])
        }
    }

    fun `annotation blocks do not lock out concurrent attribute writers`() = TestTelemetry().use { test ->
        val executor = java.util.concurrent.Executors.newSingleThreadExecutor()
        try {
            test.telemetry.mainSpanBlocking("main", slug("main-failed")) { main ->
                main.annotate {
                    val attributes = this
                    executor.submit { attributes.attribute("concurrent.value", true) }
                        .get(2, java.util.concurrent.TimeUnit.SECONDS)
                }
            }
        } finally {
            executor.shutdownNow()
        }
        assertEquals(true, test.span("main").attributes[AttributeKey.booleanKey("concurrent.value")])
    }

    fun `suspend failures and cancellation follow boundary policy`() = runTest {
        TestTelemetry().use { test ->
            val cause = IllegalStateException("failure")
            val classified = shouldThrow<SluggedException> {
                test.telemetry.mainSpan("failed", slug("suspend-fallback")) { _ ->
                    childSpan("child") { _ ->
                        withErrorSlugSuspending(slug("suspend-source-failed")) { throw cause }
                    }
                }
            }
            assertSame(cause, classified.cause)
            assertEquals("suspend-source-failed", test.span("failed").attributes[AttributeKey.stringKey("exception.slug")])
            assertEquals("suspend-source-failed", test.span("child").attributes[AttributeKey.stringKey("exception.slug")])

            shouldThrow<CancellationException> {
                test.telemetry.mainSpan("cancelled", slug("cancelled-fallback")) { _ ->
                    throw CancellationException("shutdown")
                }
            }
            val cancelled = test.span("cancelled")
            assertEquals(StatusCode.UNSET, cancelled.status.statusCode)
            assertEquals(true, cancelled.attributes[AttributeKey.booleanKey("operation.cancelled")])
        }
    }

    private fun slug(value: String) = ErrorSlug.of(value)
}

private fun <T> assertEquals(expected: T, actual: T) { actual shouldBe expected }
private fun <T> assertNotEquals(illegal: T, actual: T) { actual shouldNotBe illegal }
private fun assertTrue(actual: Boolean) { actual shouldBe true }
private fun assertFalse(actual: Boolean) { actual shouldBe false }
private fun assertNull(actual: Any?) { actual shouldBe null }
private fun assertSame(expected: Any?, actual: Any?) { actual shouldBeSameInstanceAs expected }
private inline fun <reified T : Throwable> assertFailsWith(noinline block: () -> Any?): T = shouldThrow(block)

private class TestTelemetry : AutoCloseable {
    private val exporter = InMemorySpanExporter.create()
    private val provider = SdkTracerProvider.builder()
        .addSpanProcessor(SimpleSpanProcessor.create(exporter))
        .build()
    val openTelemetry: OpenTelemetrySdk = OpenTelemetrySdk.builder().setTracerProvider(provider).build()
    val telemetry = ServiceTelemetry(openTelemetry, InstrumentationScope("test", "1.2.3"))

    fun spans(): List<SpanData> = exporter.finishedSpanItems
    fun span(name: String): SpanData = spans().single { it.name == name }

    override fun close() {
        provider.shutdown().join(10, java.util.concurrent.TimeUnit.SECONDS)
    }
}
