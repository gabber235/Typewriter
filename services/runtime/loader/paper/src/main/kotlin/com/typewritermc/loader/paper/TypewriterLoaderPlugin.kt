package com.typewritermc.loader.paper

import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.LoaderApplication
import com.typewritermc.loader.RunningHost
import com.typewritermc.loader.loaderApplication
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.bukkit.plugin.java.JavaPlugin

/**
 * Hosts the stable loader inside Paper while keeping downloaded engines outside Paper plugin loading.
 *
 * Enable creates an isolated loader application rooted at the plugin data directory. Disable stops every child runtime,
 * cancels loader work, and closes dependency injection ownership before Paper unloads the plugin.
 */
class TypewriterLoaderPlugin : JavaPlugin() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var host: RunningHost? = null
    private var application: LoaderApplication? = null

    override fun onEnable() {
        scope.launch {
            val createdApplication = loaderApplication { logger.info(it) }
            application = createdApplication
            host = createdApplication.bootstrap.start(HostEntrypoint.PAPER, dataFolder.toPath(), scope)
        }
    }

    override fun onDisable() {
        runBlocking { host?.stop() }
        scope.cancel()
        application?.close()
    }
}
