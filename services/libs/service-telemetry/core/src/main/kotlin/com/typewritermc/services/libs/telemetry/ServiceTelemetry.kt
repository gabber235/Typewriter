package com.typewritermc.services.libs.telemetry

import io.opentelemetry.api.OpenTelemetry
import io.opentelemetry.api.trace.Tracer

data class InstrumentationScope(
    val name: String,
    val version: String? = null,
    val schemaUrl: String? = null,
) {
    init {
        require(name.isNotBlank()) { "Instrumentation name must not be blank" }
    }
}

class ServiceTelemetry(
    openTelemetry: OpenTelemetry,
    instrumentation: InstrumentationScope,
) {
    internal val tracer: Tracer =
        openTelemetry
            .tracerBuilder(instrumentation.name)
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
