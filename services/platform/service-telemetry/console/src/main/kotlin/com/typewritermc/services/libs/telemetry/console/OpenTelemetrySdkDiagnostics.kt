package com.typewritermc.services.libs.telemetry.console

import java.util.logging.Handler
import java.util.logging.Level
import java.util.logging.LogRecord
import java.util.logging.Logger

class OpenTelemetrySdkDiagnosticHandler(
    private val output: ConsoleLogOutput,
) : Handler() {
    init {
        level = Level.WARNING
    }

    override fun publish(record: LogRecord) {
        if (!isLoggable(record)) return
        runCatching {
            output.write(
                formatConsoleLine(
                    timestamp = record.instant,
                    severity = record.level.consoleSeverity(),
                    body = record.consoleBody(),
                    reference = " [otel.sdk]",
                ),
            )
        }
    }

    override fun flush() = Unit

    override fun close() = Unit
}

fun installOpenTelemetrySdkDiagnostics(output: ConsoleLogOutput): AutoCloseable {
    val logger = Logger.getLogger(OPEN_TELEMETRY_LOGGER_NAME)
    val previousLevel = logger.level
    val previousUseParentHandlers = logger.useParentHandlers
    val previousHandlers = logger.handlers.toList()
    previousHandlers.forEach(logger::removeHandler)
    val handler = OpenTelemetrySdkDiagnosticHandler(output)
    logger.level = Level.WARNING
    logger.useParentHandlers = false
    logger.addHandler(handler)
    return AutoCloseable {
        logger.removeHandler(handler)
        handler.close()
        previousHandlers.forEach(logger::addHandler)
        logger.level = previousLevel
        logger.useParentHandlers = previousUseParentHandlers
    }
}

private fun Level.consoleSeverity(): String =
    when {
        intValue() >= Level.SEVERE.intValue() -> "ERROR"
        intValue() >= Level.WARNING.intValue() -> "WARN"
        intValue() >= Level.INFO.intValue() -> "INFO"
        intValue() >= Level.FINE.intValue() -> "DEBUG"
        else -> "TRACE"
    }

private fun LogRecord.consoleBody(): String =
    sequenceOf(message, thrown?.message)
        .filterNotNull()
        .map { value -> value.lineSequence().joinToString(" ") { it.trim() }.trim() }
        .filter(String::isNotEmpty)
        .distinct()
        .joinToString(": ")

private const val OPEN_TELEMETRY_LOGGER_NAME = "io.opentelemetry"
