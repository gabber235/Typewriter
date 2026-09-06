package com.typewritermc.loader.standalone.shell

import com.typewritermc.loader.LOADER_VERSION
import com.typewritermc.services.libs.registrar.RegistrarSnapshot
import kotlinx.coroutines.flow.StateFlow
import java.util.concurrent.atomic.AtomicBoolean
import kotlin.time.Duration
import kotlin.time.TimeSource

/**
 * Shared command context containing borrowed registrar state, monotonic uptime, and a stop request flag.
 * Requesting stop only ends the shell loop; the standalone runner remains responsible for shutting down the host
 * and application.
 */
class LoaderShellContext(
    val registrarStates: StateFlow<RegistrarSnapshot>,
    timeSource: TimeSource,
) {
    private val startedAt = timeSource.markNow()
    private val stopRequested = AtomicBoolean(false)

    val version: String get() = LOADER_VERSION
    val uptime: Duration get() = startedAt.elapsedNow()
    val registrarSnapshot: RegistrarSnapshot get() = registrarStates.value

    fun requestStop() {
        stopRequested.set(true)
    }

    fun isStopRequested(): Boolean = stopRequested.get()
}
