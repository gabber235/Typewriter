@file:Suppress("ForbiddenImport")

package com.typewritermc.services.libs.telemetry.console

import ch.qos.logback.classic.Level
import ch.qos.logback.classic.Logger
import ch.qos.logback.classic.LoggerContext
import ch.qos.logback.classic.spi.ILoggingEvent
import ch.qos.logback.classic.spi.ThrowableProxyUtil
import ch.qos.logback.core.AppenderBase
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.api.logs.LogRecordBuilder
import io.opentelemetry.api.logs.Severity
import io.opentelemetry.context.Context
import org.slf4j.LoggerFactory
import java.time.Instant

class OpenTelemetryLogbackAppender(
    private val openTelemetry: OpenTelemetry,
    private val minimumLevel: Level = Level.WARN,
) : AppenderBase<ILoggingEvent>() {
    private val logger = openTelemetry.logsBridge.get("typewriter.logback")

    override fun append(event: ILoggingEvent) {
        if (!event.level.isGreaterOrEqual(minimumLevel)) return
        logger
            .logRecordBuilder()
            .setTimestamp(Instant.ofEpochMilli(event.timeStamp))
            .setContext(Context.current())
            .setSeverity(event.level.severity())
            .setSeverityText(event.level.levelStr)
            .setBody(event.formattedMessage)
            .setAttribute("code.logger.name", event.loggerName)
            .setAttribute("thread.name", event.threadName)
            .apply {
                event.keyValuePairs.orEmpty().forEach { pair -> attribute(pair.key, pair.value) }
                event.throwableProxy?.let { throwable ->
                    setAttribute("exception.type", throwable.className)
                    throwable.message?.let { setAttribute("exception.message", it) }
                    setAttribute("exception.stacktrace", ThrowableProxyUtil.asString(throwable))
                }
            }.emit()
    }
}

fun installOpenTelemetryLogback(
    openTelemetry: OpenTelemetry,
    minimumLevel: Level,
): AutoCloseable {
    val loggerContext = LoggerFactory.getILoggerFactory() as LoggerContext
    val root = loggerContext.getLogger(Logger.ROOT_LOGGER_NAME)
    val previousLevel = root.level
    root
        .iteratorForAppenders()
        .asSequence()
        .toList()
        .forEach(root::detachAppender)
    root.level = minimumLevel
    val appender =
        OpenTelemetryLogbackAppender(openTelemetry, minimumLevel).apply {
            context = loggerContext
            name = "OPEN_TELEMETRY"
            start()
        }
    root.addAppender(appender)
    return AutoCloseable {
        root.detachAppender(appender)
        root.level = previousLevel
        appender.stop()
    }
}

private fun Level.severity(): Severity =
    when {
        isGreaterOrEqual(Level.ERROR) -> Severity.ERROR
        isGreaterOrEqual(Level.WARN) -> Severity.WARN
        isGreaterOrEqual(Level.INFO) -> Severity.INFO
        isGreaterOrEqual(Level.DEBUG) -> Severity.DEBUG
        else -> Severity.TRACE
    }

private fun LogRecordBuilder.attribute(
    key: String,
    value: Any?,
) {
    when (value) {
        is Boolean -> setAttribute(key, value)
        is Byte -> setAttribute(key, value.toLong())
        is Short -> setAttribute(key, value.toLong())
        is Int -> setAttribute(key, value.toLong())
        is Long -> setAttribute(key, value)
        is Float -> setAttribute(key, value.toDouble())
        is Double -> setAttribute(key, value)
        null -> Unit
        else -> setAttribute(key, value.toString())
    }
}
