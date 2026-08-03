package com.typewritermc.realm.shell

import com.github.ajalt.clikt.core.CliktError
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.booleans.shouldBeTrue
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.mockk.every
import io.mockk.mockk
import io.mockk.verify
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.trace.SpanId
import kotlinx.coroutines.flow.MutableStateFlow
import org.jline.reader.EndOfFileException
import org.jline.reader.LineReader
import java.time.Instant

val RealmShellTest by testSuite {
    test("tokenization preserves quoted arguments") {
        tokenizeRealmCommand("help 'status details'") shouldContainExactly listOf("help", "status details")
    }

    test("malformed input is reported without preventing the next command") {
        val context =
            RealmShellContext(
                startTime = Instant.parse("2026-08-02T12:00:00Z"),
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Idle)),
            )
        val reader = mockk<LineReader>(relaxed = true)

        TelemetryTestHarness.create().use { harness ->
            val shell = RealmShell(context, harness.telemetry)

            shell.executeCommand("help 'status", reader)
            shell.executeCommand("stop", reader)
        }

        context.isStopRequested().shouldBeTrue()
        verify(atLeast = 2) { reader.printAbove(any<String>()) }
    }

    test("tokenization rejects an unclosed quote") {
        shouldThrow<CliktError> {
            tokenizeRealmCommand("help 'status")
        }
    }

    test("shell command is a bounded root span") {
        val context =
            RealmShellContext(
                startTime = Instant.parse("2026-08-02T12:00:00Z"),
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Idle)),
            )
        val reader = mockk<LineReader>(relaxed = true)

        TelemetryTestHarness.create().use { harness ->
            val shell = RealmShell(context, harness.telemetry)
            harness.telemetry.mainSpanBlocking("test.parent", ErrorSlug.of("test-parent-failed")) { _ ->
                shell.executeCommand("stop", reader)
            }

            val command = harness.finishedSpans().single { it.name == "realm.shell.command" }
            command.parentSpanId shouldBe SpanId.getInvalid()
            harness.finishedSpans().none { it.name == "realm.shell" } shouldBe true
            harness.assertNoActiveSpans()
        }
    }

    test("shell exit is a bounded root span with its outcome") {
        val context =
            RealmShellContext(
                startTime = Instant.parse("2026-08-02T12:00:00Z"),
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Idle)),
            )

        TelemetryTestHarness.create().use { harness ->
            val shell = RealmShell(context, harness.telemetry)
            shell.recordShellExit(ShellExitReason.END_OF_INPUT)

            val exit = harness.finishedSpans().single { it.name == "realm.shell.exit" }
            exit.parentSpanId shouldBe SpanId.getInvalid()
            exit.attributes[AttributeKey.stringKey("operation.outcome")] shouldBe "end_of_input"
            harness.assertNoActiveSpans()
        }
    }

    test("end of input returns a bounded shell exit reason") {
        val context =
            RealmShellContext(
                startTime = Instant.parse("2026-08-02T12:00:00Z"),
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Idle)),
            )
        val reader = mockk<LineReader>(relaxed = true)
        every { reader.readLine("realm> ") } throws EndOfFileException()

        TelemetryTestHarness.create().use { harness ->
            RealmShell(context, harness.telemetry).runLoop(reader) shouldBe ShellExitReason.END_OF_INPUT
        }
    }
}
