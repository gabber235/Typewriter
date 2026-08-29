package com.typewritermc.services.libs.telemetry.testing

import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.EventProjection
import com.typewritermc.services.libs.telemetry.LogSeverity
import com.typewritermc.services.libs.telemetry.SpanPresentation
import com.typewritermc.services.libs.telemetry.childSpanBlocking
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.sdk.trace.samplers.Sampler
import kotlinx.coroutines.CancellationException

val ProjectedEventsTest by testSuite {
    test("projected main event is recorded in trace and logs") {
        TelemetryTestHarness.create().use { harness ->
            harness.telemetry.mainSpanBlocking("test.main", ErrorSlug.of("test-main-failed")) { main ->
                main.event(
                    "workflow.stage.started",
                    EventProjection.log(LogSeverity.INFO, "Starting test stage"),
                ) {
                    attribute("workflow.stage", "test")
                }
            }

            val span = harness.finishedSpans().single()
            val event = span.events.single()
            val log = harness.finishedLogs().single()

            event.name shouldBe log.eventName
            event.epochNanos shouldBe log.timestampEpochNanos
            event.attributes shouldBe log.attributes
            span.traceId shouldBe log.spanContext.traceId
            span.spanId shouldBe log.spanContext.spanId
            log.bodyValue?.asString() shouldBe "Starting test stage"
        }
    }

    test("trace only event is not projected") {
        TelemetryTestHarness.create().use { harness ->
            harness.telemetry.mainSpanBlocking("test.main", ErrorSlug.of("test-main-failed")) { main ->
                main.event("test.detail") { attribute("detail.count", 2) }
            }

            harness
                .finishedSpans()
                .single()
                .events
                .single()
                .name shouldBe "test.detail"
            harness.finishedLogs() shouldHaveSize 0
        }
    }

    test("projected child event is correlated with its owning child span") {
        TelemetryTestHarness.create().use { harness ->
            harness.telemetry.mainSpanBlocking("test.main", ErrorSlug.of("test-main-failed")) {
                childSpanBlocking("test.child") { child ->
                    child.event(
                        "dependency.connected",
                        EventProjection.log(LogSeverity.INFO, "Dependency connected"),
                    )
                }
            }

            val childSpan = harness.finishedSpans().single { it.name == "test.child" }
            val log = harness.finishedLogs().single()
            childSpan.events.single().attributes shouldBe log.attributes
            childSpan.traceId shouldBe log.spanContext.traceId
            childSpan.spanId shouldBe log.spanContext.spanId
        }
    }

    test("projected event survives disabled trace sampling") {
        TelemetryTestHarness.create(sampler = Sampler.alwaysOff()).use { harness ->
            harness.telemetry.mainSpanBlocking("test.main", ErrorSlug.of("test-main-failed")) { main ->
                main.event(
                    "workflow.stage.started",
                    EventProjection.log(LogSeverity.INFO, "Starting test stage"),
                )
            }

            harness.finishedSpans() shouldHaveSize 0
            val log = harness.finishedLogs().single()
            log.bodyValue?.asString() shouldBe "Starting test stage"
            log.spanContext.isValid shouldBe true
            log.spanContext.traceFlags.isSampled shouldBe false
        }
    }

    test("presented main span projects lifecycle") {
        TelemetryTestHarness.create().use { harness ->
            harness.telemetry.mainSpanBlocking(
                name = "test.main",
                unhandledFailureSlug = ErrorSlug.of("test-main-failed"),
                presentation = SpanPresentation("Test operation"),
            ) {}

            harness
                .finishedSpans()
                .single()
                .events
                .map { it.name } shouldBe
                listOf("operation.started", "operation.completed")
            harness.finishedLogs().map { it.bodyValue?.asString() } shouldBe
                listOf("Test operation started", "Test operation completed")
        }
    }

    test("presented failure projects classified details") {
        TelemetryTestHarness.create().use { harness ->
            runCatching {
                harness.telemetry.mainSpanBlocking(
                    name = "test.main",
                    unhandledFailureSlug = ErrorSlug.of("test-main-failed"),
                    presentation = SpanPresentation("Test operation"),
                ) {
                    error("broken")
                }
            }

            val failure = harness.finishedLogs().last()
            val event =
                harness
                    .finishedSpans()
                    .single()
                    .events
                    .last()
            failure.eventName shouldBe "operation.failed"
            failure.bodyValue?.asString() shouldBe "Test operation failed"
            event.attributes shouldBe failure.attributes
            failure.attributes[AttributeKey.stringKey("exception.slug")] shouldBe "test-main-failed"
            failure.attributes[AttributeKey.stringKey("exception.message")] shouldBe "broken"
            failure.attributes[AttributeKey.stringKey("exception.stacktrace")]!!.contains("IllegalStateException") shouldBe true
        }
    }

    test("presented cancellation is projected exactly once without failure") {
        TelemetryTestHarness.create().use { harness ->
            runCatching {
                harness.telemetry.mainSpanBlocking(
                    name = "test.main",
                    unhandledFailureSlug = ErrorSlug.of("test-main-failed"),
                    presentation = SpanPresentation("Test operation"),
                ) {
                    throw CancellationException("cancelled")
                }
            }

            harness
                .finishedSpans()
                .single()
                .events
                .map { it.name } shouldBe
                listOf("operation.started", "operation.cancelled")
            harness.finishedLogs().map { it.eventName } shouldBe
                listOf("operation.started", "operation.cancelled")
        }
    }
}
