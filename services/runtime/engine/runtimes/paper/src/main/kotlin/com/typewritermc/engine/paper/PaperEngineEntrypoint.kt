package com.typewritermc.engine.paper

import com.typewritermc.discovery.RuntimeRegistrar
import com.typewritermc.engine.runtime.EngineDeployment
import com.typewritermc.engine.session.SessionTimings
import com.typewritermc.imprint.ImprintRuntimeEntrypoint
import com.typewritermc.loader.api.HostedRuntimeEntrypoint
import com.typewritermc.loader.paper.TypewriterLoaderPlugin
import org.bukkit.plugin.Plugin
import org.bukkit.plugin.java.JavaPlugin
import org.koin.dsl.bind
import org.koin.dsl.module

/**
 * The parts of a Paper engine. Paper engine code loads outside Paper's plugin system, so the loader's plugin object is
 * the one Paper handle, and every part that needs it receives it through its constructor.
 */
val paperModule =
    module {
        single<Plugin> { JavaPlugin.getPlugin(TypewriterLoaderPlugin::class.java) }
        single { SessionTimings.MINECRAFT }
        single { SessionListener(get(), get()) } bind RuntimeRegistrar::class
    }

/** Stages a Paper engine deployment. */
@ImprintRuntimeEntrypoint
class PaperEngineEntrypoint : HostedRuntimeEntrypoint by EngineDeployment(paperModule)
