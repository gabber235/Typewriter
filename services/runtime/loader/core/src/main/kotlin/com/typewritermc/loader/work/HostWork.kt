package com.typewritermc.loader.work

import com.typewritermc.loader.api.work.InFlightWork
import com.typewritermc.loader.api.work.WorkItem
import com.typewritermc.loader.api.work.WorkRuntime
import com.typewritermc.loader.api.work.countedIn
import com.typewritermc.services.libs.telemetry.ServiceTelemetry
import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.plus
import kotlin.coroutines.ContinuationInterceptor
import kotlin.time.Duration

/**
 * The host's work in flight, [inFlight], and how long each drain of it waits at most, [drainBound].
 *
 * The loader's own work counts as the host's own, in no runtime, as an engine's counts as its runtime's: its tasks run
 * on the dispatcher of a [scope] built here and its file operations on [io], each counted from its dispatch until it
 * ran, and its own messaging counts through counted views of its sessions.
 */
class HostWork(
    val inFlight: InFlightWork,
    private val drainBound: Duration,
) {
    /** [parent] with every task it runs counted as the host's own work, on the dispatcher [parent] runs on. */
    fun scope(parent: CoroutineScope): CoroutineScope {
        val dispatcher = parent.coroutineContext[ContinuationInterceptor] as? CoroutineDispatcher ?: Dispatchers.Default
        return parent + dispatcher.countedIn(inFlight, "loader task")
    }

    /** Where the loader reads and writes its files: each operation counts as the host's own work until it ran. */
    val io: CoroutineDispatcher = Dispatchers.IO.countedIn(inFlight, "loader io")

    /**
     * Where the loader blocks a thread on an outside event, such as a file system watch: uncounted, since a wait is no
     * work, while the work the event starts runs on [io] or the host's [scope].
     */
    val waits: CoroutineDispatcher = Dispatchers.IO

    /** The work in flight as the gauge `typewriter.work.in_flight`, reported until the handle closes. */
    fun exportTo(telemetry: ServiceTelemetry): AutoCloseable = inFlight.exportTo(telemetry)

    /** Drains the work of [runtimes] (null: all work) for at most the drain bound before [reason]; see [InFlightWork.drain]. */
    suspend fun drain(
        reason: String,
        telemetry: ServiceTelemetry?,
        runtimes: Set<WorkRuntime>? = null,
    ): List<WorkItem> = inFlight.drain(drainBound, reason, telemetry, runtimes)
}
