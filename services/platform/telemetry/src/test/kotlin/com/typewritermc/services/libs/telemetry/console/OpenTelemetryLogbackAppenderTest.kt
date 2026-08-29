@file:Suppress("ForbiddenImport")

package com.typewritermc.services.libs.telemetry.console

import ch.qos.logback.classic.Level
import ch.qos.logback.classic.LoggerContext
import ch.qos.logback.classic.spi.LoggingEvent
import de.infix.testBalloon.framework.core.testSuite
import io.kotest.matchers.collections.shouldHaveSize
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.sdk.OpenTelemetrySdk
import io.opentelemetry.sdk.logs.SdkLoggerProvider
import io.opentelemetry.sdk.logs.export.SimpleLogRecordProcessor
import io.opentelemetry.sdk.testing.exporter.InMemoryLogRecordExporter
import io.opentelemetry.sdk.trace.SdkTracerProvider

val OpenTelemetryLogbackAppenderTest by testSuite {
    test("bridges enabled diagnostics with active trace context") {
        val exporter = InMemoryLogRecordExporter.create()
        val loggerProvider =
            SdkLoggerProvider
                .builder()
                .addLogRecordProcessor(SimpleLogRecordProcessor.create(exporter))
                .build()
        val tracerProvider = SdkTracerProvider.builder().build()
        val sdk =
            OpenTelemetrySdk
                .builder()
                .setTracerProvider(tracerProvider)
                .setLoggerProvider(loggerProvider)
                .build()
        val loggerContext = LoggerContext()
        val logger = loggerContext.getLogger("third.party")
        val appender =
            OpenTelemetryLogbackAppender(sdk, Level.WARN).apply {
                context = loggerContext
                start()
            }
        val span = sdk.getTracer("test").spanBuilder("test.span").startSpan()

        span.makeCurrent().use {
            appender.doAppend(LoggingEvent("test", logger, Level.INFO, "hidden", null, null))
            appender.doAppend(LoggingEvent("test", logger, Level.ERROR, "visible", IllegalStateException("broken"), null))
        }

        val record = exporter.finishedLogRecordItems.single()
        record.bodyValue?.asString() shouldBe "visible"
        record.spanContext.traceId shouldBe span.spanContext.traceId
        record.spanContext.spanId shouldBe span.spanContext.spanId
        record.attributes[AttributeKey.stringKey("code.logger.name")] shouldBe "third.party"
        record.attributes[AttributeKey.stringKey("exception.type")] shouldBe IllegalStateException::class.java.name

        span.end()
        appender.stop()
        loggerProvider.shutdown()
        tracerProvider.shutdown()
    }

    test("drops diagnostics below the configured level") {
        val exporter = InMemoryLogRecordExporter.create()
        val provider =
            SdkLoggerProvider
                .builder()
                .addLogRecordProcessor(SimpleLogRecordProcessor.create(exporter))
                .build()
        val sdk = OpenTelemetrySdk.builder().setLoggerProvider(provider).build()
        val loggerContext = LoggerContext()
        val appender =
            OpenTelemetryLogbackAppender(sdk, Level.WARN).apply {
                context = loggerContext
                start()
            }

        appender.doAppend(LoggingEvent("test", loggerContext.getLogger("third.party"), Level.INFO, "hidden", null, null))

        exporter.finishedLogRecordItems shouldHaveSize 0
        appender.stop()
        provider.shutdown()
    }
}
