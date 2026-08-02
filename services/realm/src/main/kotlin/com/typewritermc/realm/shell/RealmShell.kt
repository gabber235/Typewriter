package com.typewritermc.realm.shell

import ch.qos.logback.classic.Logger
import ch.qos.logback.classic.LoggerContext
import ch.qos.logback.core.ConsoleAppender
import com.github.ajalt.clikt.core.CliktError
import com.github.ajalt.clikt.core.parse
import com.typewritermc.realm.shell.commands.RealmRootCommand
import com.typewritermc.services.libs.telemetry.ErrorSlug
import com.typewritermc.services.libs.telemetry.MainSpanScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.mainSpanBlocking
import org.jline.reader.EndOfFileException
import org.jline.reader.LineReaderBuilder
import org.jline.reader.UserInterruptException
import org.jline.terminal.TerminalBuilder
import org.slf4j.LoggerFactory

class RealmShell(
    private val context: RealmShellContext,
    private val telemetry: ServiceTelemetry,
) {
    private val rootCommand = RealmRootCommand(context)

    fun run() {
        val terminal = TerminalBuilder.builder()
            .system(true)
            .build()

        val completer = RealmShellCompleter(rootCommand)

        val reader = LineReaderBuilder.builder()
            .terminal(terminal)
            .completer(completer)
            .build()

        val appender = setupLogbackAppender(reader)

        telemetry.mainSpanBlocking(
            name = "realm.shell",
            unhandledFailureSlug = ErrorSlug.of("realm-shell-failed"),
        ) { main ->
            reader.printAbove("Realm shell started. Type 'help' for available commands.")
            try {
                runLoop(reader, main)
            } finally {
                removeLogbackAppender(appender)
                terminal.close()
            }
        }
    }

    private fun runLoop(
        reader: org.jline.reader.LineReader,
        main: MainSpanScope,
    ) {
        while (!context.isStopRequested()) {
            val line = try {
                reader.readLine("realm> ")
            } catch (_: UserInterruptException) {
                main.annotate { operationOutcome("interrupted") }
                reader.printAbove("Interrupted by user (Ctrl+C)")
                break
            } catch (_: EndOfFileException) {
                main.annotate { operationOutcome("end_of_input") }
                reader.printAbove("End of input (Ctrl+D)")
                break
            }

            if (line.isBlank()) continue

            executeCommand(line, reader)
        }
    }

    private fun executeCommand(line: String, reader: org.jline.reader.LineReader) {
        val argv = line.trim().split(Regex("\\s+"))

        try {
            telemetry.mainSpanBlocking(
                name = "realm.shell.command",
                unhandledFailureSlug = ErrorSlug.of("realm-shell-command-failed"),
            ) { main ->
                main.annotate { attribute("realm.shell.command.name", argv.first()) }
                try {
                    rootCommand.parse(argv)
                    main.annotate { operationOutcome("completed") }
                } catch (failure: CliktError) {
                    main.annotate { operationOutcome("invalid") }
                    rootCommand.echoFormattedHelp(failure)
                }
            }
        } catch (failure: Exception) {
            val message = failure.cause?.message ?: failure.message ?: failure.javaClass.simpleName
            reader.printAbove("Command execution failed: $message")
        }
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
