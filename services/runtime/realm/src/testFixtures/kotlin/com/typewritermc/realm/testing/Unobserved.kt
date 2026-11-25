package com.typewritermc.realm.testing

import com.typewritermc.formula.graph.GraphWork
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import io.opentelemetry.api.OpenTelemetry

/** Telemetry for a realm part whose test reads none of it; a test that reads it passes a fixture's harness instead. */
val UNOBSERVED_TELEMETRY: ServiceTelemetry = OpenTelemetry.noop().serviceTelemetry("realm.test")

/** Work for reads whose counts a test does not read; it goes to a recorder that drops it. */
fun unobservedWork(): GraphWork = GraphWork.counted({}) { it }
