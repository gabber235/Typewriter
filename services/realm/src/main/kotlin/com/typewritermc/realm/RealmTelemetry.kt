package com.typewritermc.realm

import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.exporter.logging.LoggingSpanExporter
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter
import io.opentelemetry.sdk.OpenTelemetrySdk
import io.opentelemetry.sdk.resources.Resource
import io.opentelemetry.sdk.trace.SdkTracerProvider
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor
import io.opentelemetry.sdk.trace.export.SimpleSpanProcessor
import io.opentelemetry.sdk.trace.samplers.Sampler
import io.opentelemetry.semconv.ServiceAttributes

private val realmSettings by lazy(RealmSettings::system)

fun realmOpenTelemetry(): OpenTelemetrySdk {
    val resource =
        Resource.getDefault().merge(
            Resource
                .builder()
                .put(ServiceAttributes.SERVICE_NAME, "realm")
                .put(ServiceAttributes.SERVICE_VERSION, REALM_VERSION)
                .build(),
        )
    val provider =
        SdkTracerProvider
            .builder()
            .setResource(resource)
            .setSampler(realmSampler())
            .addSpanProcessor(SimpleSpanProcessor.create(LoggingSpanExporter.create()))

    realmSetting("OTEL_EXPORTER_OTLP_ENDPOINT")?.let { endpoint ->
        val exporter = OtlpGrpcSpanExporter.builder().setEndpoint(endpoint).build()
        provider.addSpanProcessor(BatchSpanProcessor.builder(exporter).build())
    }

    return OpenTelemetrySdk
        .builder()
        .setTracerProvider(provider.build())
        .buildAndRegisterGlobal()
}

fun closeRealmOpenTelemetry(openTelemetry: OpenTelemetry) {
    (openTelemetry as? OpenTelemetrySdk)?.sdkTracerProvider?.shutdown()
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
