package com.typewritermc.realm.testing

import com.typewritermc.realm.authoring.GraphWorkRecorder
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import io.opentelemetry.api.OpenTelemetry

/** Telemetry for a realm part whose test reads none of it; a test that reads it passes a fixture's harness instead. */
val UNOBSERVED_TELEMETRY: ServiceTelemetry = OpenTelemetry.noop().serviceTelemetry("realm.test")

/** Graph work for a view store whose test reads none of it. */
val UNOBSERVED_GRAPH_WORK = GraphWorkRecorder { _, _ -> }
