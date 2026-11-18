package com.typewritermc.services.libs.telemetry.testing

import com.typewritermc.services.libs.telemetry.InstrumentationScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import io.opentelemetry.sdk.OpenTelemetrySdk
import io.opentelemetry.sdk.common.CompletableResultCode
import io.opentelemetry.sdk.logs.SdkLoggerProvider
import io.opentelemetry.sdk.logs.data.LogRecordData
import io.opentelemetry.sdk.logs.export.SimpleLogRecordProcessor
import io.opentelemetry.sdk.testing.exporter.InMemoryLogRecordExporter
import io.opentelemetry.sdk.testing.exporter.InMemorySpanExporter
import io.opentelemetry.sdk.trace.SdkTracerProvider
import io.opentelemetry.sdk.trace.data.SpanData
import io.opentelemetry.sdk.trace.export.SimpleSpanProcessor
import java.util.concurrent.TimeUnit

/**
 * An in-memory OpenTelemetry SDK whose finished spans and emitted log records can be read back, closed with a flush
 * and a shutdown. A log record is readable as soon as it is emitted, while its span may still run.
 */
class InMemoryTelemetry : AutoCloseable {
    private val exporter = InMemorySpanExporter.create()
    private val provider =
        SdkTracerProvider
            .builder()
            .addSpanProcessor(SimpleSpanProcessor.create(exporter))
            .build()
    private val logExporter = InMemoryLogRecordExporter.create()
    private val logProvider =
        SdkLoggerProvider
            .builder()
            .addLogRecordProcessor(SimpleLogRecordProcessor.create(logExporter))
            .build()
    val openTelemetry: OpenTelemetrySdk =
        OpenTelemetrySdk
            .builder()
            .setTracerProvider(provider)
            .setLoggerProvider(logProvider)
            .build()
    val telemetry = ServiceTelemetry(openTelemetry, InstrumentationScope("test", "1.2.3"))

    fun spans(): List<SpanData> = exporter.finishedSpanItems

    fun span(name: String): SpanData = spans().single { it.name == name }

    fun logs(): List<LogRecordData> = logExporter.finishedLogRecordItems

    override fun close() {
        await("force flush", provider.forceFlush())
        await("shutdown", provider.shutdown())
        await("log shutdown", logProvider.shutdown())
        exporter.close()
    }

    private fun await(
        operation: String,
        result: CompletableResultCode,
    ) {
        result.join(10, TimeUnit.SECONDS)
        check(result.isDone) { "Telemetry $operation timed out" }
        check(result.isSuccess) { "Telemetry $operation failed" }
    }
}
