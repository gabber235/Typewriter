@file:Suppress("ForbiddenImport")

package com.typewritermc.services.libs.telemetry.console

import io.opentelemetry.api.logs.Severity
import io.opentelemetry.sdk.common.CompletableResultCode
import io.opentelemetry.sdk.logs.data.LogRecordData
import io.opentelemetry.sdk.logs.export.LogRecordExporter
import java.time.Instant
import java.time.format.DateTimeFormatter

fun interface ConsoleLogOutput {
    fun write(line: String)
}

class ConsoleLogRecordExporter(
    private val output: ConsoleLogOutput,
) : LogRecordExporter {
    override fun export(logs: Collection<LogRecordData>): CompletableResultCode =
        runCatching {
            logs.forEach { output.write(format(it)) }
        }.fold(
            onSuccess = { CompletableResultCode.ofSuccess() },
            onFailure = { CompletableResultCode.ofFailure() },
        )

    override fun flush(): CompletableResultCode = CompletableResultCode.ofSuccess()

    override fun shutdown(): CompletableResultCode = CompletableResultCode.ofSuccess()

    internal fun format(log: LogRecordData): String {
        val timestamp = instant(log.timestampEpochNanos)
        val body = log.bodyValue?.asString().orEmpty()
        return formatConsoleLine(timestamp, log.severity.name, body, reference(log))
    }

    private fun reference(log: LogRecordData): String {
        if (log.severity.severityNumber < Severity.WARN.severityNumber) return ""
        val slug =
            log.attributes.get(
                io.opentelemetry.api.common.AttributeKey
                    .stringKey("exception.slug"),
            )
        val identifier = slug ?: log.eventName?.takeIf(String::isNotBlank) ?: return ""
        return " [$identifier]"
    }

    private fun instant(epochNanos: Long): Instant = Instant.ofEpochSecond(epochNanos / NANOS_PER_SECOND, epochNanos % NANOS_PER_SECOND)
}

internal fun formatConsoleLine(
    timestamp: Instant,
    severity: String,
    body: String,
    reference: String = "",
): String = "${DateTimeFormatter.ISO_INSTANT.format(timestamp)} ${severity.padEnd(5)} $body$reference"

private const val NANOS_PER_SECOND = 1_000_000_000L
