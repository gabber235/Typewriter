package com.typewritermc.loader

import kotlinx.coroutines.CoroutineScope
import kotlinx.serialization.Serializable
import java.nio.file.Path

@Serializable
enum class HostEntrypoint {
    STANDALONE,
    PAPER,
}

/**
 * Bridges a process entrypoint into the shared loader host lifecycle.
 *
 * Implementations assemble entrypoint specific dependencies, register or restore the host, and return ownership through
 * [RunningHost]. The supplied [CoroutineScope] belongs to the process entrypoint and bounds background loader work.
 */
interface LoaderBootstrap {
    suspend fun start(
        entrypoint: HostEntrypoint,
        workDirectory: Path,
        scope: CoroutineScope,
    ): RunningHost
}

/**
 * Ownership handle returned after host startup. Exposes the service connection to callers while retaining the stop
 * action supplied by the bootstrap. The entrypoint must stop this handle before closing its [LoaderApplication];
 * this wrapper itself does not enforce idempotence or cancel the entrypoint scope.
 */
class RunningHost(
    private val ownedService: LoaderService,
    private val stopAction: suspend () -> Unit,
) {
    val service: LoaderServiceConnection = ownedService

    suspend fun stop() {
        stopAction()
    }
}
