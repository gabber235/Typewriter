@file:Suppress("ForbiddenImport", "ForbiddenMethodCall")

package com.typewritermc.services.libs.telemetry

import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.common.Attributes
import io.opentelemetry.api.trace.Span
import io.opentelemetry.context.Context
import java.time.Instant

data class SpanPresentation(
    val displayName: String,
) {
    init {
        require(displayName.isNotBlank()) { "Span presentation name must not be blank" }
    }
}

enum class LogSeverity {
    TRACE,
    DEBUG,
    INFO,
    WARN,
    ERROR,
}

sealed interface EventProjection {
    data object TraceOnly : EventProjection

    class Log internal constructor(
        val severity: LogSeverity,
        val body: String,
    ) : EventProjection

    companion object {
        fun log(
            severity: LogSeverity,
            body: String,
        ): EventProjection {
            require(body.isNotBlank()) { "Projected event body must not be blank" }
            return Log(severity, body)
        }
    }
}

class TelemetryEventAttributes internal constructor() {
    private val attributes = Attributes.builder()

    fun attribute(
        key: AttributeKey<String>,
        value: String,
    ) = apply { attributes.put(key, value) }

    fun attribute(
        key: AttributeKey<Long>,
        value: Long,
    ) = apply { attributes.put(key, value) }

    fun attribute(
        key: AttributeKey<Double>,
        value: Double,
    ) = apply { attributes.put(key, value) }

    fun attribute(
        key: AttributeKey<Boolean>,
        value: Boolean,
    ) = apply { attributes.put(key, value) }

    fun attribute(
        key: String,
        value: String,
    ) = attribute(AttributeKey.stringKey(key), value)

    fun attribute(
        key: String,
        value: Int,
    ) = attribute(key, value.toLong())

    fun attribute(
        key: String,
        value: Long,
    ) = attribute(AttributeKey.longKey(key), value)

    fun attribute(
        key: String,
        value: Double,
    ) = attribute(AttributeKey.doubleKey(key), value)

    fun attribute(
        key: String,
        value: Boolean,
    ) = attribute(AttributeKey.booleanKey(key), value)

    fun exception(failure: Throwable) {
        attributes.put("exception.type", failure.javaClass.name)
        attributes.put("exception.message", failure.message ?: failure.javaClass.simpleName)
        attributes.put("exception.stacktrace", failure.stackTraceToString())
    }

    internal fun build(projection: EventProjection): TelemetryEvent {
        if (projection is EventProjection.Log) {
            attributes.put("typewriter.event.projection", "log")
            attributes.put("typewriter.event.severity", projection.severity.name)
        }
        return TelemetryEvent(attributes.build())
    }
}

internal data class TelemetryEvent(
    val attributes: Attributes,
)

internal fun ServiceTelemetry.recordEvent(
    span: Span,
    name: String,
    projection: EventProjection,
    block: TelemetryEventAttributes.() -> Unit,
) {
    requireStableSegment(name)
    val timestamp = Instant.now()
    val event = TelemetryEventAttributes().apply(block).build(projection)
    span.addEvent(name, event.attributes, timestamp)
    if (projection !is EventProjection.Log) return

    logger
        .logRecordBuilder()
        .setTimestamp(timestamp)
        .setContext(Context.current().with(span))
        .setEventName(name)
        .setSeverity(projection.severity.openTelemetrySeverity())
        .setSeverityText(projection.severity.name)
        .setBody(projection.body)
        .setAllAttributes(event.attributes)
        .emit()
}

private fun LogSeverity.openTelemetrySeverity(): io.opentelemetry.api.logs.Severity =
    when (this) {
        LogSeverity.TRACE -> io.opentelemetry.api.logs.Severity.TRACE
        LogSeverity.DEBUG -> io.opentelemetry.api.logs.Severity.DEBUG
        LogSeverity.INFO -> io.opentelemetry.api.logs.Severity.INFO
        LogSeverity.WARN -> io.opentelemetry.api.logs.Severity.WARN
        LogSeverity.ERROR -> io.opentelemetry.api.logs.Severity.ERROR
    }
