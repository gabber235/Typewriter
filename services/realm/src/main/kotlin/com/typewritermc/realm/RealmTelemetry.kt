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

private val realmSettings by lazy(RealmSettings::system)

fun realmOpenTelemetry(console: ConsoleLogOutput): OpenTelemetrySdk {
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
            .setSampler(realmSampler())
    val loggerProvider =
        SdkLoggerProvider
            .builder()
            .setResource(resource)
            .addLogRecordProcessor(SimpleLogRecordProcessor.create(ConsoleLogRecordExporter(console)))

    realmSetting("OTEL_EXPORTER_OTLP_ENDPOINT")?.let { endpoint ->
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

private fun realmSampler(): Sampler =
    when (realmSetting("OTEL_TRACES_SAMPLER") ?: "always_on") {
        "parentbased_traceidratio" -> Sampler.parentBased(Sampler.traceIdRatioBased(realmSamplerRatio()))
        "traceidratio" -> Sampler.traceIdRatioBased(realmSamplerRatio())
        "always_off" -> Sampler.alwaysOff()
        else -> Sampler.alwaysOn()
    }

private fun realmSamplerRatio(): Double = realmSetting("OTEL_TRACES_SAMPLER_ARG")?.toDoubleOrNull()?.coerceIn(0.0, 1.0) ?: 1.0

internal fun realmSetting(
    name: String,
    default: String? = null,
): String? = realmSettings.get(name, default)
