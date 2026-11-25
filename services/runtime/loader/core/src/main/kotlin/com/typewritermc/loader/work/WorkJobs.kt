package com.typewritermc.loader.work

import com.typewritermc.loader.api.work.InFlightWork
import com.typewritermc.loader.api.work.WorkItem
import com.typewritermc.loader.artifactSpan
import com.typewritermc.services.libs.telemetry.EventProjection
import com.typewritermc.services.libs.telemetry.LogSeverity
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import kotlinx.coroutines.delay
import kotlinx.coroutines.withTimeoutOrNull
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds

/** The host's work in flight as the gauge `typewriter.work.in_flight`, reported until the handle closes. */
fun InFlightWork.exportTo(telemetry: ServiceTelemetry): AutoCloseable =
    telemetry.gauge("typewriter.work.in_flight", "{item}") { count.toLong() }

/**
 * Waits until no work is in flight or [bound] ran out, before the host does [reason] (stops or rolls out), and
 * returns the items still in flight then: empty when the work drained. Items still in flight are logged as a warning
 * that names each of them, and the caller goes on without them.
 */
suspend fun InFlightWork.drain(
    bound: Duration,
    reason: String,
    telemetry: ServiceTelemetry?,
): List<WorkItem> {
    if (count == 0) return emptyList()
    return telemetry.artifactSpan("loader.work.drain", "loader-work-drain-failed") { span ->
        span?.annotate {
            attribute("work.drain.reason", reason)
            attribute("work.drain.bound_ms", bound.inWholeMilliseconds)
        }
        val drained = withTimeoutOrNull(bound) { while (count > 0) delay(DRAIN_POLL) } != null
        val left = if (drained) emptyList() else items
        if (left.isNotEmpty()) {
            span?.event(
                "loader.work.drain.expired",
                EventProjection.log(
                    LogSeverity.WARN,
                    "Work still in flight after the $bound drain before $reason, going on without it: ${left.joinToString()}",
                ),
            ) {
                attribute("work.drain.left_count", left.size)
                attribute("work.drain.left", left.joinToString())
            }
        }
        left
    }
}

/** How often a drain checks whether the work in flight ended. */
private val DRAIN_POLL = 10.milliseconds
