package com.typewritermc.loader

import kotlinx.coroutines.CoroutineScope
import java.nio.file.Path
import java.util.ServiceLoader

interface LoaderBootstrap {
    suspend fun start(
        entrypoint: HostEntrypoint,
        workDirectory: Path,
        scope: CoroutineScope,
    ): RunningHost

    companion object {
        fun discover(): LoaderBootstrap =
            ServiceLoader.load(LoaderBootstrap::class.java).firstOrNull()
                ?: error("No LoaderBootstrap provider is installed.")
    }
}
