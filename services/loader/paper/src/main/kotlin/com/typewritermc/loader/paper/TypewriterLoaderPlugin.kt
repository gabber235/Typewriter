package com.typewritermc.loader.paper

import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.LoaderBootstrap
import com.typewritermc.loader.RunningHost
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.bukkit.plugin.java.JavaPlugin

class TypewriterLoaderPlugin : JavaPlugin() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var host: RunningHost? = null

    override fun onEnable() {
        scope.launch {
            val bootstrap =
                runCatching { LoaderBootstrap.discover() }.getOrElse { failure ->
                    logger.warning(failure.message ?: "No loader bootstrap provider is installed.")
                    return@launch
                }
            host = bootstrap.start(HostEntrypoint.PAPER, dataFolder.toPath(), scope)
        }
    }

    override fun onDisable() {
        runBlocking { host?.stop() }
        scope.cancel()
    }
}
