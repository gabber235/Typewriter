package com.typewritermc.services.libs.telemetry.testing

import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainAttributes
import com.typewritermc.services.libs.telemetry.SluggedException
import com.typewritermc.services.libs.telemetry.childSpanBlocking
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.kotest.matchers.shouldNotBe
import io.opentelemetry.api.GlobalOpenTelemetry
import io.opentelemetry.api.trace.Span
import io.opentelemetry.api.trace.StatusCode
import java.time.Duration

val HarnessTest by testSuite {
    test("main ownership child hierarchy and active lifecycle are inspectable") {
        TelemetryTestHarness.create().use { harness ->
            harness.telemetry.mainSpanBlocking("main", ErrorSlug.of("main-failed")) { main ->
                harness.activeSpanCount() shouldBe 1
                val mainId = Span.current().spanContext.spanId
                childSpanBlocking("child") { child ->
                    harness.activeSpanCount() shouldBe 2
                    Span.current().spanContext.spanId shouldNotBe mainId
                    main.annotate { attribute("main.value", "stable") }
                    child.annotate { attribute("child.value", 2) }
                }
                harness.activeSpanCount() shouldBe 1
            }
            harness.assertNoActiveSpans()
            harness.spans {
                count(2)
                roots(1)
                main("main") {
                    isRoot()
                    status(StatusCode.UNSET)
                    durationAtLeast(Duration.ZERO)
                    attribute("main.value", "stable")
                    childCount(1)
                    child("child") { attribute("child.value", 2L) }
                }
            }
        }
    }

    test("event and exception assertions inspect attributes") {
        TelemetryTestHarness.create().use { harness ->
            shouldThrow<SluggedException> {
                harness.telemetry.mainSpanBlocking("main", ErrorSlug.of("main-failed")) { main ->
                    main.recordDegraded(ErrorSlug.of("cache-failed"), IllegalStateException("cache unavailable"))
                    throw IllegalArgumentException("request secret")
                }
            }
            harness.spans {
                main("main") {
                    status(StatusCode.ERROR)
                    exceptionSlug("main-failed")
                    event("exception.degraded") {
                        attribute("exception.slug", "cache-failed")
                        attribute("exception.type", IllegalStateException::class.java.name)
                    }
                    recordedException { attribute("exception.type", IllegalArgumentException::class.java.name) }
                    noSensitiveAttributes("request secret")
                }
            }
        }
    }

    test("assertions fail for malformed expectations") {
        TelemetryTestHarness.create().use { harness ->
            harness.telemetry.mainSpanBlocking("main", ErrorSlug.of("main-failed")) { main ->
                main.annotate { attribute("token.value", "top-secret") }
            }
            harness.spans {
                shouldThrow<AssertionError> { count(2) }
                shouldThrow<AssertionError> { main("missing") }
                main("main") {
                    shouldThrow<AssertionError> { child("missing") }
                    shouldThrow<AssertionError> { event("missing") }
                    shouldThrow<AssertionError> { attribute("token.value", "wrong") }
                    shouldThrow<AssertionError> { noSensitiveAttributes("token") }
                    shouldThrow<AssertionError> { noSensitiveAttributes("top-secret") }
                }
            }
        }
    }

    test("consumer-owned attribute extensions remain typed and testable") {
        TelemetryTestHarness.create().use { harness ->
            harness.telemetry.mainSpanBlocking("identity.issue", ErrorSlug.of("identity-issue-failed")) { main ->
                main.annotate { identityOutcome(IdentityOutcome.Created) }
            }
            harness.spans { main("identity.issue") { attribute("identity.outcome", "created") } }
        }
    }

    test("harnesses are isolated and do not mutate global telemetry") {
        val globalBefore = GlobalOpenTelemetry.get()
        TelemetryTestHarness.create().use { first ->
            TelemetryTestHarness.create().use { second ->
                first.telemetry.mainSpanBlocking("first", ErrorSlug.of("first-failed")) { _ -> }
                second.telemetry.mainSpanBlocking("second", ErrorSlug.of("second-failed")) { _ -> }
                first.finishedSpans().map { it.name } shouldBe listOf("first")
                second.finishedSpans().map { it.name } shouldBe listOf("second")
                GlobalOpenTelemetry.get() shouldBe globalBefore
            }
        }
    }

    test("clear and repeated close are deterministic") {
        val harness = TelemetryTestHarness.create()
        harness.telemetry.mainSpanBlocking("main", ErrorSlug.of("main-failed")) { _ -> }
        harness.finishedSpans().size shouldBe 1
        harness.clear()
        harness.finishedSpans().size shouldBe 0
        harness.close()
        harness.close()
    }
}

private enum class IdentityOutcome(val wireValue: String) { Created("created") }

private fun MainAttributes.identityOutcome(outcome: IdentityOutcome) {
    attribute("identity.outcome", outcome.wireValue)
}
