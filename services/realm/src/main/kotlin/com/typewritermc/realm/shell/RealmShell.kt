package com.typewritermc.realm.shell

import ch.qos.logback.classic.Logger
import ch.qos.logback.classic.LoggerContext
import ch.qos.logback.core.ConsoleAppender
import com.github.ajalt.clikt.core.CliktError
import com.github.ajalt.clikt.core.parse
import com.github.ajalt.clikt.parsers.CommandLineParser
import com.github.ajalt.mordant.rendering.AnsiLevel
import com.github.ajalt.mordant.terminal.PrintRequest
import com.github.ajalt.mordant.terminal.Terminal
import com.github.ajalt.mordant.terminal.TerminalInfo
import com.github.ajalt.mordant.terminal.TerminalInterface
import com.typewritermc.realm.shell.commands.RealmRootCommand
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import io.opentelemetry.context.Context
import org.jline.reader.EndOfFileException
import org.jline.reader.LineReaderBuilder
import org.jline.reader.UserInterruptException
import org.jline.terminal.TerminalBuilder
import org.slf4j.LoggerFactory

class RealmShell(
    private val context: RealmShellContext,
    private val telemetry: ServiceTelemetry,
) {
    fun run() {
        val terminal = TerminalBuilder.builder()
            .system(true)
            .build()

        val completer = RealmShellCompleter(RealmRootCommand(context))

        val reader = LineReaderBuilder.builder()
            .terminal(terminal)
            .completer(completer)
            .build()

        val appender = setupLogbackAppender(reader)

        try {
            reader.printAbove("Realm shell started. Type 'help' for available commands.")
            recordShellExit(runLoop(reader))
        } catch (failure: Throwable) {
            recordShellFailure(failure)
        } finally {
            removeLogbackAppender(appender)
            terminal.close()
        }
    }

    internal fun runLoop(reader: org.jline.reader.LineReader): ShellExitReason {
        while (!context.isStopRequested()) {
            val line = try {
                reader.readLine("realm> ")
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

    internal fun executeCommand(line: String, reader: org.jline.reader.LineReader) {
        try {
            telemetry.mainSpanBlocking(
                name = "realm.shell.command",
                unhandledFailureSlug = ErrorSlug.of("realm-shell-command-failed"),
                parent = Context.root(),
            ) { main ->
                val rootCommand = RealmRootCommand(context, reader.asCliktTerminal())
                try {
                    val argv = tokenizeRealmCommand(line)
                    main.annotate { attribute("realm.shell.command.name", argv.firstOrNull() ?: "empty") }
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
            name = "realm.shell.exit",
            unhandledFailureSlug = ErrorSlug.of("realm-shell-exit-failed"),
            parent = Context.root(),
        ) { main ->
            main.annotate { operationOutcome(reason.attributeValue) }
        }
    }

    private fun recordShellFailure(failure: Throwable): Nothing = telemetry.mainSpanBlocking(
        name = "realm.shell.exit",
        unhandledFailureSlug = ErrorSlug.of("realm-shell-failed"),
        parent = Context.root(),
    ) { main ->
        main.annotate { operationOutcome("failed") }
        throw failure
    }

    private fun setupLogbackAppender(reader: org.jline.reader.LineReader): RealmShellLogbackAppender {
        val loggerContext = LoggerFactory.getILoggerFactory() as LoggerContext
        val rootLogger = loggerContext.getLogger(Logger.ROOT_LOGGER_NAME)

        val consoleAppender = rootLogger.getAppender("CONSOLE") as? ConsoleAppender
            ?: error("CONSOLE appender not found in logback configuration")

        rootLogger.detachAppender(consoleAppender)

        val appender = RealmShellLogbackAppender(consoleAppender).apply {
            context = loggerContext
            name = "REALM_SHELL"
            attach(reader)
            start()
        }

        rootLogger.addAppender(appender)
        return appender
    }

    private fun removeLogbackAppender(appender: RealmShellLogbackAppender) {
        appender.detach()
        appender.stop()

        val loggerContext = LoggerFactory.getILoggerFactory() as LoggerContext
        val rootLogger = loggerContext.getLogger(Logger.ROOT_LOGGER_NAME)
        rootLogger.detachAppender(appender)
    }
}

internal enum class ShellExitReason(val attributeValue: String) {
    STOP_REQUESTED("stop_requested"),
    INTERRUPTED("interrupted"),
    END_OF_INPUT("end_of_input"),
}

internal fun tokenizeRealmCommand(line: String): List<String> = CommandLineParser.tokenize(line.trim())

private fun org.jline.reader.LineReader.asCliktTerminal(): Terminal = Terminal(
    terminalInterface = object : TerminalInterface {
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
