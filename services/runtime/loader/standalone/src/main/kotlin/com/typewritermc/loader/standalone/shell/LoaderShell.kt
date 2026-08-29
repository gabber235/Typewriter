package com.typewritermc.loader.standalone.shell

import com.github.ajalt.clikt.core.CliktError
import com.github.ajalt.clikt.core.parse
import com.github.ajalt.clikt.parsers.CommandLineParser
import com.github.ajalt.mordant.rendering.AnsiLevel
import com.github.ajalt.mordant.terminal.PrintRequest
import com.github.ajalt.mordant.terminal.Terminal
import com.github.ajalt.mordant.terminal.TerminalInfo
import com.github.ajalt.mordant.terminal.TerminalInterface
import com.typewritermc.loader.standalone.shell.commands.LoaderRootCommand
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.EventProjection
import com.typewritermc.services.libs.telemetry.LogSeverity
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import io.opentelemetry.context.Context
import org.jline.reader.EndOfFileException
import org.jline.reader.LineReaderBuilder
import org.jline.reader.UserInterruptException
import org.jline.terminal.TerminalBuilder

class LoaderShell(
    private val context: LoaderShellContext,
    private val telemetry: ServiceTelemetry,
    private val console: LoaderConsoleLogOutput = LoaderConsoleLogOutput(),
) {
    fun run() {
        val terminal =
            TerminalBuilder
                .builder()
                .system(true)
                .build()

        val completer = LoaderShellCompleter(LoaderRootCommand(context))

        val reader =
            LineReaderBuilder
                .builder()
                .terminal(terminal)
                .completer(completer)
                .build()

        console.attach(reader)

        try {
            reader.printAbove("Loader shell started. Type 'help' for available commands.")
            recordShellExit(runLoop(reader))
        } catch (failure: Throwable) {
            recordShellFailure(failure)
        } finally {
            console.detach()
            terminal.close()
        }
    }

    internal fun runLoop(reader: org.jline.reader.LineReader): ShellExitReason {
        while (!context.isStopRequested()) {
            val line =
                try {
                    reader.readLine("loader> ")
                } catch (_: UserInterruptException) {
                    reader.printAbove("Interrupted by user (Ctrl+C)")
                    return ShellExitReason.INTERRUPTED
                } catch (_: EndOfFileException) {
                    reader.printAbove("End of input (Ctrl+D)")
                    return ShellExitReason.END_OF_INPUT
                }

            if (line.isBlank()) continue

            executeCommand(line, reader)
        }
        return ShellExitReason.STOP_REQUESTED
    }

    internal fun executeCommand(
        line: String,
        reader: org.jline.reader.LineReader,
    ) {
        try {
            telemetry.mainSpanBlocking(
                name = "loader.shell.command",
                unhandledFailureSlug = ErrorSlug.of("loader-shell-command-failed"),
                parent = Context.root(),
            ) { main ->
                val rootCommand = LoaderRootCommand(context, reader.asCliktTerminal())
                try {
                    val argv = tokenizeLoaderCommand(line)
                    main.annotate { attribute("loader.shell.command.name", argv.firstOrNull() ?: "empty") }
                    rootCommand.parse(argv)
                    main.annotate { operationOutcome("completed") }
                } catch (failure: CliktError) {
                    val outcome = if (failure.statusCode == 0) "completed" else "invalid"
                    main.annotate { operationOutcome(outcome) }
                    rootCommand.getFormattedHelp(failure)?.let(reader::printAbove)
                }
            }
        } catch (failure: Exception) {
            val message = failure.cause?.message ?: failure.message ?: failure.javaClass.simpleName
            reader.printAbove("Command execution failed: $message")
        }
    }

    internal fun recordShellExit(reason: ShellExitReason) {
        telemetry.mainSpanBlocking(
            name = "loader.shell.exit",
            unhandledFailureSlug = ErrorSlug.of("loader-shell-exit-failed"),
            parent = Context.root(),
        ) { main ->
            main.annotate { operationOutcome(reason.attributeValue) }
        }
    }

    private fun recordShellFailure(failure: Throwable): Nothing =
        telemetry.mainSpanBlocking(
            name = "loader.shell.exit",
            unhandledFailureSlug = loaderShellFailureSlug,
            parent = Context.root(),
        ) { main ->
            main.annotate { operationOutcome("failed") }
            main.event(
                name = "operation.failed",
                projection = EventProjection.log(LogSeverity.ERROR, "Loader shell failed"),
            ) {
                attribute("exception.slug", loaderShellFailureSlug.value)
                exception(failure)
            }
            throw failure
        }
}

private val loaderShellFailureSlug = ErrorSlug.of("loader-shell-failed")

internal enum class ShellExitReason(
    val attributeValue: String,
) {
    STOP_REQUESTED("stop_requested"),
    INTERRUPTED("interrupted"),
    END_OF_INPUT("end_of_input"),
}

internal fun tokenizeLoaderCommand(line: String): List<String> = CommandLineParser.tokenize(line.trim())

private fun org.jline.reader.LineReader.asCliktTerminal(): Terminal =
    Terminal(
        terminalInterface =
            object : TerminalInterface {
                override fun info(
                    ansiLevel: AnsiLevel?,
                    hyperlinks: Boolean?,
                    outputInteractive: Boolean?,
                    inputInteractive: Boolean?,
                ) = TerminalInfo(
                    ansiLevel = ansiLevel ?: AnsiLevel.NONE,
                    ansiHyperLinks = hyperlinks ?: false,
                    outputInteractive = outputInteractive ?: true,
                    inputInteractive = inputInteractive ?: true,
                    supportsAnsiCursor = false,
                )

                override fun completePrintRequest(request: PrintRequest) {
                    printAbove(request.text)
                }

                override fun readLineOrNull(hideInput: Boolean): String? = null
            },
    )
