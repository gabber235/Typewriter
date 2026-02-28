package com.typewritermc.services.libs.telemetry

import io.github.oshai.kotlinlogging.KLogger
import io.github.oshai.kotlinlogging.KotlinLogging.logger
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.api.trace.StatusCode
import io.opentelemetry.sdk.common.CompletableResultCode
import io.opentelemetry.sdk.trace.data.SpanData
import io.opentelemetry.sdk.trace.export.SpanExporter

class PrettyConsoleSpanExporter : SpanExporter {
    private val loggers = mutableMapOf<String, KLogger>()

    private fun SpanData.logger(): KLogger? {
        if (this.attributes.get(AttributeKey.booleanKey("log.hide")) == true) {
            return null
        }

        val logName = this.attributes.get(AttributeKey.stringKey("log.name")) ?: "Unknown"
        return loggers.getOrPut(logName) { logger(logName) }
    }

    override fun export(spans: Collection<SpanData>): CompletableResultCode {
        spans.forEach { span ->
            val logger = span.logger() ?: return@forEach
            val durationMs = (span.endEpochNanos - span.startEpochNanos) / 1_000_000
            val status = if (span.status.statusCode == StatusCode.ERROR) "ERROR" else "OK"

            val attrs = span.attributes.asMap()
                .entries
                .filter { !it.key.key.startsWith("log") }
                .joinToString(", ") { "${it.key}=${it.value}" }

            val events = span.events
                .joinToString(", ") { event ->
                    val eventDuration =
                        event.attributes.get(io.opentelemetry.api.common.AttributeKey.longKey("duration_ms"))
                    if (eventDuration != null) "${event.name}:${eventDuration}ms" else event.name
                }

            val message = buildString {
                append("[${span.name}] ")
                append("${durationMs}ms ")
                append(status)
                if (attrs.isNotEmpty()) append(" | $attrs")
                if (events.isNotEmpty()) append(" | events: [$events]")
                if (span.status.statusCode == StatusCode.ERROR) {
                    span.status.description?.let { append(" | $it") }
                }
            }

            when (span.status.statusCode) {
                StatusCode.ERROR -> logger.error { message }
                else -> logger.info { message }
            }
        }
        return CompletableResultCode.ofSuccess()
    }

    override fun flush(): CompletableResultCode = CompletableResultCode.ofSuccess()

    override fun shutdown(): CompletableResultCode = CompletableResultCode.ofSuccess()
}
