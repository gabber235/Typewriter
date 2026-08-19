package com.typewritermc.realm

import com.typewritermc.services.libs.telemetry.console.ConsoleLogOutput
import com.typewritermc.services.libs.telemetry.console.ConsoleLogRecordExporter
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.api.baggage.propagation.W3CBaggagePropagator
import io.opentelemetry.api.trace.propagation.W3CTraceContextPropagator
import io.opentelemetry.context.propagation.ContextPropagators
import io.opentelemetry.context.propagation.TextMapPropagator
import io.opentelemetry.exporter.otlp.logs.OtlpGrpcLogRecordExporter
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter
import io.opentelemetry.sdk.OpenTelemetrySdk
import io.opentelemetry.sdk.logs.SdkLoggerProvider
import io.opentelemetry.sdk.logs.export.BatchLogRecordProcessor
import io.opentelemetry.sdk.logs.export.SimpleLogRecordProcessor
import io.opentelemetry.sdk.resources.Resource
import io.opentelemetry.sdk.trace.SdkTracerProvider
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor
import io.opentelemetry.sdk.trace.samplers.Sampler
import io.opentelemetry.semconv.ServiceAttributes
import java.util.concurrent.TimeUnit

internal fun realmOpenTelemetry(
    console: ConsoleLogOutput,
    configuration: RealmTelemetryConfiguration,
): OpenTelemetrySdk {
    val resource =
        Resource.getDefault().merge(
            Resource
                .builder()
                .put(ServiceAttributes.SERVICE_NAME, "realm")
                .put(ServiceAttributes.SERVICE_VERSION, REALM_VERSION)
                .build(),
        )
    val tracerProvider =
        SdkTracerProvider
            .builder()
            .setResource(resource)
            .setSampler(realmSampler(configuration.sampler))
    val loggerProvider =
        SdkLoggerProvider
            .builder()
            .setResource(resource)
            .addLogRecordProcessor(SimpleLogRecordProcessor.create(ConsoleLogRecordExporter(console)))

    configuration.otlpEndpoint?.let { endpoint ->
        val spanExporter = OtlpGrpcSpanExporter.builder().setEndpoint(endpoint).build()
        tracerProvider.addSpanProcessor(BatchSpanProcessor.builder(spanExporter).build())
        val logExporter = OtlpGrpcLogRecordExporter.builder().setEndpoint(endpoint).build()
        loggerProvider.addLogRecordProcessor(BatchLogRecordProcessor.builder(logExporter).build())
    }
    val propagators =
        ContextPropagators.create(
            TextMapPropagator.composite(
                W3CTraceContextPropagator.getInstance(),
                W3CBaggagePropagator.getInstance(),
            ),
        )

    return OpenTelemetrySdk
        .builder()
        .setTracerProvider(tracerProvider.build())
        .setLoggerProvider(loggerProvider.build())
        .setPropagators(propagators)
        .buildAndRegisterGlobal()
}

fun closeRealmOpenTelemetry(openTelemetry: OpenTelemetry) {
    val sdk = openTelemetry as? OpenTelemetrySdk ?: return
    sdk.sdkTracerProvider.forceFlush().join(10, TimeUnit.SECONDS)
    sdk.sdkLoggerProvider.forceFlush().join(10, TimeUnit.SECONDS)
    sdk.shutdown().join(10, TimeUnit.SECONDS)
}

private fun realmSampler(configuration: RealmSamplerConfiguration): Sampler =
    when (configuration) {
        RealmSamplerConfiguration.AlwaysOn -> {
            Sampler.alwaysOn()
        }

        RealmSamplerConfiguration.AlwaysOff -> {
            Sampler.alwaysOff()
        }

        is RealmSamplerConfiguration.TraceIdRatio -> {
            Sampler.traceIdRatioBased(configuration.ratio)
        }

        is RealmSamplerConfiguration.ParentBasedTraceIdRatio -> {
            Sampler.parentBased(Sampler.traceIdRatioBased(configuration.ratio))
        }
    }
