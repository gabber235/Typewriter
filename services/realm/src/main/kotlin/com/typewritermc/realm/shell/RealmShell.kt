package com.typewritermc.realm.shell

import ch.qos.logback.classic.Logger
import ch.qos.logback.classic.LoggerContext
import ch.qos.logback.core.ConsoleAppender
import com.github.ajalt.clikt.core.CliktError
import com.github.ajalt.clikt.core.parse
import com.typewritermc.realm.shell.commands.RealmRootCommand
import io.github.oshai.kotlinlogging.KotlinLogging
import org.jline.reader.EndOfFileException
import org.jline.reader.LineReaderBuilder
import org.jline.reader.UserInterruptException
import org.jline.terminal.TerminalBuilder
import org.slf4j.LoggerFactory

private val logger = KotlinLogging.logger {}

class RealmShell(
    private val context: RealmShellContext,
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

        logger.info { "Realm shell started. Type 'help' for available commands." }

        try {
            runLoop(reader)
        } finally {
            removeLogbackAppender(appender)
            terminal.close()
        }
    }

    private fun runLoop(reader: org.jline.reader.LineReader) {
        while (!context.isStopRequested()) {
            val line = try {
                reader.readLine("realm> ")
            } catch (_: UserInterruptException) {
                logger.info { "Interrupted by user (Ctrl+C)" }
                break
            } catch (_: EndOfFileException) {
                logger.info { "End of input (Ctrl+D)" }
                break
            }

            if (line.isBlank()) continue

            executeCommand(line)
        }
    }

    private fun executeCommand(line: String) {
        val argv = line.trim().split(Regex("\\s+"))

        try {
            rootCommand.parse(argv)
        } catch (e: CliktError) {
            rootCommand.echoFormattedHelp(e)
        } catch (e: Exception) {
            logger.error(e) { "Command execution failed" }
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
