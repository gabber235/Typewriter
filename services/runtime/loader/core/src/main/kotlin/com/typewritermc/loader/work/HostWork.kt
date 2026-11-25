package com.typewritermc.loader.work

import com.typewritermc.loader.api.work.InFlightWork
import com.typewritermc.loader.api.work.WorkItem
import com.typewritermc.loader.api.work.WorkRuntime
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import kotlin.time.Duration

/** The host's work in flight, [inFlight], and how long each drain of it waits at most, [drainBound]. */
class HostWork(
    val inFlight: InFlightWork,
    private val drainBound: Duration,
) {
    /** The work in flight as the gauge `typewriter.work.in_flight`, reported until the handle closes. */
    fun exportTo(telemetry: ServiceTelemetry): AutoCloseable = inFlight.exportTo(telemetry)

    /** Drains the work of [runtimes] (null: all work) for at most the drain bound before [reason]; see [InFlightWork.drain]. */
    suspend fun drain(
        reason: String,
        telemetry: ServiceTelemetry?,
        runtimes: Set<WorkRuntime>? = null,
    ): List<WorkItem> = inFlight.drain(drainBound, reason, telemetry, runtimes)
}
