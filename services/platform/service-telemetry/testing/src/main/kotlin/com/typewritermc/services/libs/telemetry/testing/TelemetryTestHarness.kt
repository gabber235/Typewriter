package com.typewritermc.services.libs.telemetry.testing

import com.typewritermc.services.libs.telemetry.InstrumentationScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.context.Context
import io.opentelemetry.sdk.OpenTelemetrySdk
import io.opentelemetry.sdk.common.CompletableResultCode
import io.opentelemetry.sdk.logs.SdkLoggerProvider
import io.opentelemetry.sdk.logs.data.LogRecordData
import io.opentelemetry.sdk.logs.export.SimpleLogRecordProcessor
import io.opentelemetry.sdk.testing.exporter.InMemoryLogRecordExporter
import io.opentelemetry.sdk.testing.exporter.InMemorySpanExporter
import io.opentelemetry.sdk.trace.ReadWriteSpan
import io.opentelemetry.sdk.trace.ReadableSpan
import io.opentelemetry.sdk.trace.SdkTracerProvider
import io.opentelemetry.sdk.trace.SpanProcessor
import io.opentelemetry.sdk.trace.data.SpanData
import io.opentelemetry.sdk.trace.export.SimpleSpanProcessor
import io.opentelemetry.sdk.trace.samplers.Sampler
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicBoolean

class TelemetryTestHarness private constructor(
    val openTelemetry: OpenTelemetrySdk,
    val telemetry: ServiceTelemetry,
    private val exporter: InMemorySpanExporter,
    private val logExporter: InMemoryLogRecordExporter,
    private val provider: SdkTracerProvider,
    private val loggerProvider: SdkLoggerProvider,
    private val trackingProcessor: TrackingSpanProcessor,
) : AutoCloseable {
    private val closed = AtomicBoolean()

    companion object {
        fun create(
            instrumentation: InstrumentationScope = InstrumentationScope("test"),
            sampler: Sampler = Sampler.alwaysOn(),
        ): TelemetryTestHarness {
            val exporter = InMemorySpanExporter.create()
            val logExporter = InMemoryLogRecordExporter.create()
            val trackingProcessor = TrackingSpanProcessor()
            val provider =
                SdkTracerProvider
                    .builder()
                    .setSampler(sampler)
                    .addSpanProcessor(trackingProcessor)
                    .addSpanProcessor(SimpleSpanProcessor.create(exporter))
                    .build()
            val loggerProvider =
                SdkLoggerProvider
                    .builder()
                    .addLogRecordProcessor(SimpleLogRecordProcessor.create(logExporter))
                    .build()
            val sdk =
                OpenTelemetrySdk
                    .builder()
                    .setTracerProvider(provider)
                    .setLoggerProvider(loggerProvider)
                    .build()
            return TelemetryTestHarness(
                sdk,
                ServiceTelemetry(sdk, instrumentation),
                exporter,
                logExporter,
                provider,
                loggerProvider,
                trackingProcessor,
            )
        }
    }

    fun finishedSpans(): List<SpanData> = exporter.finishedSpanItems

    fun finishedLogs(): List<LogRecordData> = logExporter.finishedLogRecordItems

    fun clear() {
        exporter.reset()
        logExporter.reset()
    }

    fun activeSpanCount(): Int = trackingProcessor.activeCount()

    fun assertNoActiveSpans() {
        if (activeSpanCount() != 0) throw AssertionError("Expected no active spans, found ${activeSpanCount()}")
    }

    fun forceFlush() {
        await("trace force flush", provider.forceFlush())
        await("log force flush", loggerProvider.forceFlush())
    }

    fun spans(block: SpanAssertions.() -> Unit) = SpanAssertions(finishedSpans()).block()

    override fun close() {
        if (!closed.compareAndSet(false, true)) return
        forceFlush()
        await("shutdown", provider.shutdown())
        await("log shutdown", loggerProvider.shutdown())
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

private class TrackingSpanProcessor : SpanProcessor {
    private val active = ConcurrentHashMap.newKeySet<String>()

    override fun onStart(
        parentContext: Context,
        span: ReadWriteSpan,
    ) {
        active += span.spanContext.spanId
    }

    override fun isStartRequired() = true

    override fun onEnd(span: ReadableSpan) {
        active -= span.spanContext.spanId
    }

    override fun isEndRequired() = true

    override fun shutdown(): CompletableResultCode = CompletableResultCode.ofSuccess()

    override fun forceFlush(): CompletableResultCode = CompletableResultCode.ofSuccess()

    fun activeCount(): Int = active.size
}
