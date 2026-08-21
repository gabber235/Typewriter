package com.typewritermc.loader

import kotlinx.coroutines.CoroutineScope
import java.nio.file.Path

interface LoaderBootstrap {
    suspend fun start(
        entrypoint: HostEntrypoint,
        workDirectory: Path,
        scope: CoroutineScope,
    ): RunningHost
}
