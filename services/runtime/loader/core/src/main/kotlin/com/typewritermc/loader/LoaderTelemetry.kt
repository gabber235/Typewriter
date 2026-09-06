package com.typewritermc.loader

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

/** Receives formatted loader telemetry on the logging surface owned by a host entrypoint. */
fun interface LoaderLogOutput {
    fun write(line: String)
}

/**
 * Creates the loader owned telemetry SDK with W3C context propagation and host directed console logging.
 * Configured OTLP endpoints add batched span and log exporters; console records use a synchronous processor. The
 * caller must flush and shut down this SDK after dependent runtimes stop.
 */
internal fun loaderOpenTelemetry(
    logOutput: LoaderLogOutput,
    configuration: LoaderTelemetryConfiguration,
): OpenTelemetrySdk {
    val resource =
        Resource.getDefault().merge(
            Resource
                .builder()
                .put(ServiceAttributes.SERVICE_NAME, "loader")
                .put(ServiceAttributes.SERVICE_VERSION, LOADER_VERSION)
                .build(),
        )
    val tracerProvider =
        SdkTracerProvider
            .builder()
            .setResource(resource)
            .setSampler(loaderSampler(configuration.sampler))
    val loggerProvider =
        SdkLoggerProvider
            .builder()
            .setResource(resource)
            .addLogRecordProcessor(
                SimpleLogRecordProcessor.create(ConsoleLogRecordExporter(ConsoleLogOutput(logOutput::write))),
            )

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
        .build()
}

/**
 * Flushes trace and log providers before requesting SDK shutdown, waiting up to ten seconds at each stage. Foreign
 * OpenTelemetry implementations are ignored. Timeout completion is not inspected here, so returning does not
 * guarantee that every record reached an exporter.
 */
internal fun closeLoaderOpenTelemetry(openTelemetry: OpenTelemetry) {
    val sdk = openTelemetry as? OpenTelemetrySdk ?: return
    sdk.sdkTracerProvider.forceFlush().join(10, TimeUnit.SECONDS)
    sdk.sdkLoggerProvider.forceFlush().join(10, TimeUnit.SECONDS)
    sdk.shutdown().join(10, TimeUnit.SECONDS)
}

private fun loaderSampler(configuration: LoaderSamplerConfiguration): Sampler =
    when (configuration) {
        LoaderSamplerConfiguration.AlwaysOn -> {
            Sampler.alwaysOn()
        }

        LoaderSamplerConfiguration.AlwaysOff -> {
            Sampler.alwaysOff()
        }

        is LoaderSamplerConfiguration.TraceIdRatio -> {
            Sampler.traceIdRatioBased(configuration.ratio)
        }

        is LoaderSamplerConfiguration.ParentBasedTraceIdRatio -> {
            Sampler.parentBased(Sampler.traceIdRatioBased(configuration.ratio))
        }
    }
