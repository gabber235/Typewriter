package com.typewritermc.services.libs.telemetry.testing

import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow

val HarnessTest by testSuite {
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
}
