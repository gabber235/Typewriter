package com.typewritermc.services.libs.http.core

import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.types.shouldBeSameInstanceAs
import io.opentelemetry.api.baggage.Baggage
import io.opentelemetry.api.baggage.propagation.W3CBaggagePropagator
import io.opentelemetry.api.trace.SpanKind
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator
import io.opentelemetry.context.Context
import io.opentelemetry.context.propagation.ContextPropagators
import io.opentelemetry.context.propagation.TextMapPropagator
import kotlinx.coroutines.CancellationException
import java.net.URI
import kotlin.time.Duration.Companion.seconds

val ServiceHttpClientTest by testSuite {
    test("replaces stale W3C propagation fields with the active context") {
        TelemetryTestHarness.create().use { harness ->
            var seen: HttpRequest? = null
            val transport =
                HttpTransport { request ->
                    seen = request
                    HttpResult.Success(HttpResponse(200, HttpHeaders.Empty, byteArrayOf()))
                }
            val propagator = TextMapPropagator.composite(W3CTraceContextPropagator.getInstance(), W3CBaggagePropagator.getInstance())
            val client = ServiceHttpClient(transport, harness.telemetry, ContextPropagators.create(propagator))
            val parent =
                harness.openTelemetry.tracerProvider
                    .get("caller")
                    .spanBuilder("caller")
                    .startSpan()
            val baggage = Baggage.builder().put("tenant", "active").build()
            Context.root().with(parent).with(baggage).makeCurrent().use {
                client.execute(
                    httpRequest(
                        headers =
                            HttpHeaders.of(
                                "traceparent" to "00-00000000000000000000000000000001-0000000000000001-01",
                                "tracestate" to "stale=value",
                                "baggage" to "tenant=stale,secret=token",
                            ),
                    ),
                )
            }
            parent.end()
            val traceparent = seen!!.headers.first("traceparent")!!
            traceparent.matches(Regex("00-[0-9a-f]{32}-[0-9a-f]{16}-[0-9a-f]{2}")) shouldBe true
            traceparent.contains("00000000000000000000000000000001") shouldBe false
            seen.headers.first("tracestate") shouldBe null
            seen.headers.first("baggage") shouldBe "tenant=active"
            harness.assertNoActiveSpans()
        }
    }

    test("oversized request skips transport and closes a safely attributed failure span") {
        TelemetryTestHarness.create().use { harness ->
            var calls = 0
            val client =
                httpClient(harness) {
                    calls++
                    error("not called")
                }
            client.execute(httpRequest(body = byteArrayOf(1, 2), maximumRequestBytes = 1, timeout = 2.seconds)) shouldBe
                HttpResult.Failure(HttpError.RequestTooLarge(1, 2))
            calls shouldBe 0
            harness.assertNoActiveSpans()
            harness.spans {
                span("http.test") {
                    kind(SpanKind.CLIENT)
                    attribute("operation.outcome", "failure")
                    attribute("error.type", "request_too_large")
                    attribute("http.request.body.size", 2L)
                    attribute("http.request.timeout_ms", 2000L)
                    noSensitiveAttributes("secret", "authorization", "query")
                }
            }
        }
    }

    test("all HTTP statuses are successes with response telemetry") {
        for (status in listOf(200, 404, 500)) {
            TelemetryTestHarness.create().use { harness ->
                val client = httpClient(harness) { HttpResult.Success(HttpResponse(status, HttpHeaders.Empty, byteArrayOf(1, 2, 3))) }
                val result = client.execute(httpRequest(uri = URI("https://example.test/path?token=secret")))
                (result as HttpResult.Success).response.statusCode shouldBe status
                harness.spans {
                    span("http.test") {
                        attribute("operation.outcome", "success")
                        attribute("http.response.status_code", status.toLong())
                        attribute("http.response.body.size", 3L)
                        noSensitiveAttributes("secret", "token", "authorization")
                    }
                }
            }
        }
    }

    test("every HTTP error has a stable failure category") {
        val cases =
            listOf(
                HttpError.RequestTooLarge(1, 2) to "request_too_large",
                HttpError.ResponseTooLarge(1) to "response_too_large",
                HttpError.Timeout to "timeout",
                HttpError.Unavailable to "unavailable",
                HttpError.Transport("secret.Type") to "transport",
                HttpError.Invalid("secret body") to "invalid",
            )
        for ((error, category) in cases) {
            TelemetryTestHarness.create().use { harness ->
                httpClient(harness) { HttpResult.Failure(error) }.execute(httpRequest()) shouldBe HttpResult.Failure(error)
                harness.spans {
                    span("http.test") {
                        attribute("error.type", category)
                        noSensitiveAttributes("secret", "token")
                    }
                }
                harness.assertNoActiveSpans()
            }
        }
    }

    test("cancellation escapes as cancellation and closes the span") {
        TelemetryTestHarness.create().use { harness ->
            shouldThrow<CancellationException> {
                httpClient(harness) { throw CancellationException("cancel") }.execute(httpRequest())
            }.message shouldBe "cancel"
            harness.assertNoActiveSpans()
        }
    }

    test("a fatal failure escapes unchanged and closes the span") {
        val fatal = object : LinkageError("fatal") {}
        TelemetryTestHarness.create().use { harness ->
            shouldThrow<LinkageError> { httpClient(harness) { throw fatal }.execute(httpRequest()) } shouldBeSameInstanceAs fatal
            harness.assertNoActiveSpans()
        }
    }
}
