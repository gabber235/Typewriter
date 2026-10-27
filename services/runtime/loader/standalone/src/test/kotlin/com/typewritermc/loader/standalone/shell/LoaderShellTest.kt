package com.typewritermc.loader.standalone.shell

import com.github.ajalt.clikt.core.CliktError
import com.typewritermc.loader.standalone.shell.testing.ShellTerminal
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import com.typewritermc.services.libs.registrar.RegistrarState
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import com.typewritermc.services.libs.telemetry.testing.TelemetryTestHarness
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.collections.shouldContainExactly
import io.kotest.matchers.shouldBe
import io.kotest.matchers.string.shouldContain
import io.kotest.matchers.string.shouldContainInOrder
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.trace.SpanId
import kotlinx.coroutines.flow.MutableStateFlow
import kotlin.time.TestTimeSource

val LoaderShellTest by testSuite {
    test("tokenization preserves quoted arguments") {
        tokenizeLoaderCommand("help 'status details'") shouldContainExactly listOf("help", "status details")
    }

    test("malformed input is reported without preventing the next command") {
        val context =
            LoaderShellContext(
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Idle)),
                timeSource = TestTimeSource(),
            )

        ShellTerminal(input = "help 'status\nstop\n").use { terminal ->
            TelemetryTestHarness.create().use { harness ->
                LoaderShell(context, harness.telemetry).runLoop(terminal.reader) shouldBe ShellExitReason.STOP_REQUESTED
            }

            terminal.printed.shouldContainInOrder(
                "Error: incorrect format in file  line 0: unclosed quote",
                "Stopping the loader",
            )
        }
    }

    test("tokenization rejects an unclosed quote") {
        shouldThrow<CliktError> {
            tokenizeLoaderCommand("help 'status")
        }
    }

    test("shell command is a bounded root span") {
        val context =
            LoaderShellContext(
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Idle)),
                timeSource = TestTimeSource(),
            )

        ShellTerminal().use { terminal ->
            TelemetryTestHarness.create().use { harness ->
                val shell = LoaderShell(context, harness.telemetry)
                harness.telemetry.mainSpanBlocking("test.parent", ErrorSlug.of("test-parent-failed")) { _ ->
                    shell.executeCommand("stop", terminal.reader)
                }

                val command = harness.finishedSpans().single { it.name == "loader.shell.command" }
                command.parentSpanId shouldBe SpanId.getInvalid()
                harness.finishedSpans().none { it.name == "loader.shell" } shouldBe true
                harness.assertNoActiveSpans()
            }
        }
    }

    test("shell exit is a bounded root span with its outcome") {
        val context =
            LoaderShellContext(
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Idle)),
                timeSource = TestTimeSource(),
            )

        TelemetryTestHarness.create().use { harness ->
            val shell = LoaderShell(context, harness.telemetry)
            shell.recordShellExit(ShellExitReason.END_OF_INPUT)

            val exit = harness.finishedSpans().single { it.name == "loader.shell.exit" }
            exit.parentSpanId shouldBe SpanId.getInvalid()
            exit.attributes[AttributeKey.stringKey("operation.outcome")] shouldBe "end_of_input"
            harness.assertNoActiveSpans()
        }
    }

    test("end of input returns a bounded shell exit reason") {
        val context =
            LoaderShellContext(
                registrarStates = MutableStateFlow(RegistrarSnapshot(12, 3, RegistrarState.Idle)),
                timeSource = TestTimeSource(),
            )

        ShellTerminal().use { terminal ->
            TelemetryTestHarness.create().use { harness ->
                LoaderShell(context, harness.telemetry).runLoop(terminal.reader) shouldBe ShellExitReason.END_OF_INPUT
            }

            terminal.printed shouldContain "End of input (Ctrl+D)"
        }
    }
}
