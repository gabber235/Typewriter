package com.typewritermc.realm.testing

import com.typewritermc.formula.graph.GraphWork
import com.typewritermc.realm.authoring.AuthoringViewStore
import com.typewritermc.realm.authoring.PinnedReads
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import com.typewritermc.services.libs.telemetry.serviceTelemetry
import io.opentelemetry.api.OpenTelemetry

/** Telemetry for a realm part whose test reads none of it; a test that reads it passes a fixture's harness instead. */
val UNOBSERVED_TELEMETRY: ServiceTelemetry = OpenTelemetry.noop().serviceTelemetry("realm.test")

/** Runs [block] on work whose counts a test does not read: its recorder drops them. */
inline fun <T> unobserved(block: (GraphWork) -> T): T = GraphWork.counted({}, block)

/** Runs [block] on reads pinned to the store's current view, on work whose counts a test does not read. */
inline fun <T> AuthoringViewStore.unobservedPin(block: (PinnedReads) -> T): T = unobserved { work -> pin(work).use(block) }
