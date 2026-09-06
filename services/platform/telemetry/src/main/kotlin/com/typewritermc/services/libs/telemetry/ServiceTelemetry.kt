@file:Suppress("ForbiddenImport")

package com.typewritermc.services.libs.telemetry

import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.api.common.Attributes
import io.opentelemetry.api.logs.Logger
import io.opentelemetry.api.trace.Tracer

/**
 * Names the library or service producing telemetry, with optional version and schema metadata.
 *
 * This is instrumentation identity, not a deployment resource or individual request name.
 */
data class InstrumentationScope(
    val name: String,
    val version: String? = null,
    val schemaUrl: String? = null,
) {
    init {
        require(name.isNotBlank()) { "Instrumentation name must not be blank" }
    }
}

/**
 * Provides tracing, operation metrics, and log emission under one instrumentation scope.
 *
 * Use the span boundary helpers to create owned operation scopes and correlate projected logs. The supplied
 * OpenTelemetry instance remains externally owned; this facade does not shut down exporters.
 */
class ServiceTelemetry(
    openTelemetry: OpenTelemetry,
    instrumentation: InstrumentationScope,
) {
    private val meter = openTelemetry.meterBuilder(instrumentation.name).build()
    private val operations = meter.counterBuilder("typewriter.operation.completed").setUnit("{operation}").build()
    private val duration = meter.histogramBuilder("typewriter.operation.duration").setUnit("s").build()

    internal fun recordOperation(name: String, outcome: String, durationSeconds: Double) {
        val attributes = Attributes.builder().put("operation.name", name).put("operation.outcome", outcome).build()
        operations.add(1, attributes)
        duration.record(durationSeconds, attributes)
    }

    internal val tracer: Tracer =
        openTelemetry
            .tracerBuilder(instrumentation.name)
            .apply {
                instrumentation.version?.let(::setInstrumentationVersion)
                instrumentation.schemaUrl?.let(::setSchemaUrl)
            }.build()

    internal val logger: Logger =
        openTelemetry
            .logsBridge
            .loggerBuilder(instrumentation.name)
            .apply {
                instrumentation.version?.let(::setInstrumentationVersion)
                instrumentation.schemaUrl?.let(::setSchemaUrl)
            }.build()
}

fun OpenTelemetry.serviceTelemetry(
    name: String,
    version: String? = null,
    schemaUrl: String? = null,
) = ServiceTelemetry(this, InstrumentationScope(name, version, schemaUrl))
