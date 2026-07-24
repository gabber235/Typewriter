package com.typewritermc.services.libs.telemetry.koin

import com.typewritermc.services.libs.telemetry.InstrumentationScope
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import io.opentelemetry.api.OpenTelemetry
import org.koin.core.module.Module
import org.koin.dsl.module

fun serviceTelemetryModule(instrumentation: InstrumentationScope): Module = module {
    single { ServiceTelemetry(get<OpenTelemetry>(), instrumentation) }
}
fun serviceTelemetryModule(name: String, version: String? = null, schemaUrl: String? = null): Module =
    serviceTelemetryModule(InstrumentationScope(name, version, schemaUrl))
