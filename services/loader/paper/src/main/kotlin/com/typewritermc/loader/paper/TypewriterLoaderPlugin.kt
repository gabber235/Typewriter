package com.typewritermc.loader.paper

import com.typewritermc.loader.HostEntrypoint
import com.typewritermc.loader.RunningHost
import com.typewritermc.loader.standalone.LoaderApplication
import com.typewritermc.loader.standalone.localLoaderApplication
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
    private var application: LoaderApplication? = null

    override fun onEnable() {
        scope.launch {
            val loaderApplication = localLoaderApplication()
            application = loaderApplication
            host = loaderApplication.bootstrap.start(HostEntrypoint.PAPER, dataFolder.toPath(), scope)
        }
    }

    override fun onDisable() {
        runBlocking { host?.stop() }
        scope.cancel()
        application?.close()
    }
}
