package com.typewritermc.loader

import kotlinx.coroutines.CoroutineScope
import java.nio.file.Path

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
