package com.typewritermc.services.libs.telemetry

import com.typewritermc.services.libs.telemetry.TelemetryQualifier.*
import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.api.trace.Tracer
import io.opentelemetry.exporter.otlp.trace.OtlpGrpcSpanExporter
import io.opentelemetry.sdk.OpenTelemetrySdk
import io.opentelemetry.sdk.resources.Resource
import io.opentelemetry.sdk.trace.SdkTracerProvider
import io.opentelemetry.sdk.trace.export.BatchSpanProcessor
import io.opentelemetry.sdk.trace.export.SimpleSpanProcessor
import io.opentelemetry.sdk.trace.samplers.Sampler
import io.opentelemetry.semconv.ServiceAttributes
import org.koin.core.qualifier.named
import org.koin.dsl.module
import org.koin.dsl.onClose

val SERVICE_TELEMETRY_MODULE = module {
    single(named(OTEL_ENDPOINT)) {
        getProperty("OTEL_EXPORTER_OTLP_ENDPOINT", "")
    }

    single(named(OTEL_SAMPLER)) {
        getProperty("OTEL_TRACES_SAMPLER", "always_on")
    }

    single(named(OTEL_SAMPLER_RATIO)) {
        getProperty("OTEL_TRACES_SAMPLER_ARG", "1.0").toDoubleOrNull() ?: 1.0
    }

    single<OpenTelemetry> {
        val serviceName: String = get(named(SERVICE_NAME))
        val serviceVersion: String = get(named(SERVICE_VERSION))

        val resource = Resource.builder()
            .put(ServiceAttributes.SERVICE_NAME, serviceName)
            .put(ServiceAttributes.SERVICE_VERSION, serviceVersion)
            .build()

        val samplerType: String = get(named(OTEL_SAMPLER))
        val samplerRatio: Double = get(named(OTEL_SAMPLER_RATIO))
        val sampler = configureSampler(samplerType, samplerRatio)

        val tracerProviderBuilder = SdkTracerProvider.builder()
            .setResource(resource)
            .setSampler(sampler)
            .addSpanProcessor(SimpleSpanProcessor.create(PrettyConsoleSpanExporter()))

        val otlpEndpoint: String = get(named(OTEL_ENDPOINT))
        if (otlpEndpoint.isNotBlank()) {
            val otlpExporter = OtlpGrpcSpanExporter.builder()
                .setEndpoint(otlpEndpoint)
                .build()
            tracerProviderBuilder.addSpanProcessor(
                BatchSpanProcessor.builder(otlpExporter).build()
            )
        }

        OpenTelemetrySdk.builder()
            .setTracerProvider(tracerProviderBuilder.build())
            .buildAndRegisterGlobal()
    } onClose { otel ->
        (otel as? OpenTelemetrySdk)?.sdkTracerProvider?.shutdown()
    }

    single<Tracer> {
        val serviceName: String = get(named(SERVICE_NAME))
        val serviceVersion: String = get(named(SERVICE_VERSION))
        val otel: OpenTelemetry = get()
        otel.getTracer(serviceName, serviceVersion)
    }
}

private fun configureSampler(samplerType: String, ratio: Double): Sampler {
    return when (samplerType) {
        "parentbased_traceidratio" -> Sampler.parentBased(Sampler.traceIdRatioBased(ratio))
        "traceidratio" -> Sampler.traceIdRatioBased(ratio)
        "always_off" -> Sampler.alwaysOff()
        else -> Sampler.alwaysOn()
    }
}
