package com.typewritermc.loader.paper

import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.LoaderApplication
import com.typewritermc.loader.RunningHost
import com.typewritermc.loader.api.work.InFlightWork
import com.typewritermc.loader.loaderApplication
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.runBlocking
import org.bukkit.plugin.ServicePriority
import org.bukkit.plugin.java.JavaPlugin

/**
 * Hosts the stable loader inside Paper while keeping downloaded engines outside Paper plugin loading.
 *
 * Enable creates an isolated loader application rooted at the plugin data directory. Disable stops every child runtime,
 * cancels loader work, and closes dependency injection ownership before Paper unloads the plugin.
 *
 * The host's [InFlightWork] is a Bukkit service from enable on, so another plugin can observe the work of every hosted
 * runtime, such as a stepped game test that starts no tick while work a tick caused still runs.
 */
class TypewriterLoaderPlugin : JavaPlugin() {
    private val scope = CoroutineScope(SupervisorJob() + Dispatchers.IO)
    private var host: RunningHost? = null
    private var application: LoaderApplication? = null
    private val work = InFlightWork()

    override fun onEnable() {
        server.servicesManager.register(InFlightWork::class.java, work, this, ServicePriority.Normal)
        scope.launch {
            val createdApplication = loaderApplication(PaperLogOutput(logger))
            application = createdApplication
            host = createdApplication.bootstrap.start(HostEntrypoint.PAPER, dataFolder.toPath(), work, scope)
        }
    }

    override fun onDisable() {
        runBlocking { host?.stop() }
        scope.cancel()
        application?.close()
    }
}
