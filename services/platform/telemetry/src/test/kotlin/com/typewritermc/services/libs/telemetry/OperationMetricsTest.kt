package com.typewritermc.services.libs.telemetry

import de.infix.testBalloon.framework.core.testSuite
import io.kotest.assertions.throwables.shouldThrow
import io.kotest.matchers.shouldBe
import io.opentelemetry.api.common.AttributeKey
import io.opentelemetry.sdk.OpenTelemetrySdk
import io.opentelemetry.sdk.metrics.SdkMeterProvider
import io.opentelemetry.sdk.testing.exporter.InMemoryMetricReader
import io.opentelemetry.sdk.trace.SdkTracerProvider
import io.opentelemetry.sdk.trace.samplers.Sampler
import kotlinx.coroutines.CancellationException

val OperationMetricsTest by testSuite {
    test("operation outcomes survive disabled tracing without a presentation") {
        val reader = InMemoryMetricReader.create()
        OpenTelemetrySdk.builder()
            .setTracerProvider(SdkTracerProvider.builder().setSampler(Sampler.alwaysOff()).build())
            .setMeterProvider(SdkMeterProvider.builder().registerMetricReader(reader).build())
            .build().use { sdk ->
                val telemetry = sdk.serviceTelemetry("test")
                val failure = ErrorSlug.of("operation-failed")
                telemetry.mainSpanBlocking("operation", failure) { _ -> }
                telemetry.mainSpan("operation", failure) { _ -> }
                shouldThrow<SluggedException> {
                    telemetry.mainSpanBlocking("operation", failure) { _ -> error("failed") }
                }
                shouldThrow<CancellationException> {
                    telemetry.mainSpan("operation", failure) { _ -> throw CancellationException("cancelled") }
                }
                val metrics = reader.collectAllMetrics()
                val outcomes = metrics.single { it.name == "typewriter.operation.completed" }
                    .longSumData.points.associate {
                        it.attributes.get(AttributeKey.stringKey("operation.outcome")) to it.value
                    }
                outcomes shouldBe mapOf("completed" to 2L, "failed" to 1L, "cancelled" to 1L)
                metrics.single { it.name == "typewriter.operation.duration" }
                    .histogramData.points.sumOf { it.count } shouldBe 4L
            }
    }
}
