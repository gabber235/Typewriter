package com.typewritermc.engine.paper

import com.github.retrooper.packetevents.PacketEvents
import com.google.gson.Gson
import com.typewritermc.core.TypewriterCore
import com.typewritermc.core.interaction.SessionTracker
import com.typewritermc.core.serialization.createDataSerializerGson
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.command.TypewriterCommandManager
import com.typewritermc.engine.paper.content.ContentHandler
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.action.ActionHandler
import com.typewritermc.engine.paper.entry.dialogue.DialogueHandler
import com.typewritermc.engine.paper.entry.entity.EntityHandler
import com.typewritermc.engine.paper.entry.temporal.TemporalHandler
import com.typewritermc.engine.paper.entry.temporal.TemporalPlaceholders
import com.typewritermc.engine.paper.events.TypewriterUnloadEvent
import com.typewritermc.engine.paper.extensions.bstats.BStatsMetrics
import com.typewritermc.engine.paper.extensions.modrinth.Modrinth
import com.typewritermc.engine.paper.extensions.placeholderapi.PlaceholderExpansion
import com.typewritermc.engine.paper.extensions.placeholderapi.PlaceholderHandler
import com.typewritermc.engine.paper.facts.FactDatabase
import com.typewritermc.engine.paper.facts.FactHandler
import com.typewritermc.engine.paper.facts.FactStorage
import com.typewritermc.engine.paper.facts.FactTracker
import com.typewritermc.engine.paper.facts.storage.FileFactStorage
import com.typewritermc.engine.paper.interaction.*
import com.typewritermc.engine.paper.loader.PaperDependencyChecker
import com.typewritermc.engine.paper.loader.dataSerializerModule
import com.typewritermc.engine.paper.snippets.SnippetDatabase
import com.typewritermc.engine.paper.snippets.SnippetDatabaseImpl
import com.typewritermc.engine.paper.ui.ClientSynchronizer
import com.typewritermc.engine.paper.ui.CommunicationHandler
import com.typewritermc.engine.paper.ui.PanelHost
import com.typewritermc.engine.paper.ui.Writers
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.createBukkitDataParser
import com.typewritermc.loader.DependencyChecker
import io.papermc.paper.plugin.lifecycle.event.registrar.ReloadableRegistrarEvent
import io.papermc.paper.plugin.lifecycle.event.types.LifecycleEvents
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import lirand.api.architecture.KotlinPlugin
import org.bukkit.plugin.Plugin
import org.bukkit.plugin.java.JavaPlugin
import org.koin.core.component.KoinComponent
import org.koin.core.component.get
import org.koin.core.context.GlobalContext.startKoin
import org.koin.core.logger.Level
import org.koin.core.logger.MESSAGE
import org.koin.core.module.dsl.bind
import org.koin.core.module.dsl.createdAtStart
import org.koin.core.module.dsl.singleOf
import org.koin.core.module.dsl.withOptions
import org.koin.core.qualifier.named
import org.koin.dsl.bind
import org.koin.dsl.module
import org.koin.java.KoinJavaComponent
import java.io.File
import java.util.logging.Level.*
import java.util.logging.Logger
import kotlin.time.Duration.Companion.seconds

@Suppress("UnstableApiUsage")
class TypewriterPaperPlugin : KotlinPlugin(), KoinComponent {
    override fun onLoad() {
        super.onLoad()
        val modules = module {
            single { this@TypewriterPaperPlugin } withOptions
                    {
                        named("plugin")
                        bind<Plugin>()
                        bind<JavaPlugin>()
                        bind<TypewriterPaperPlugin>()
                        createdAtStart()
                    }

            single<Logger> { this@TypewriterPaperPlugin.logger } withOptions {
                named("logger")
                createdAtStart()
            }

            single(named("version")) { this@TypewriterPaperPlugin.pluginMeta.version }

            singleOf(::TypewriterCore)
            factory<File>(named("baseDir")) { plugin.dataFolder }
            single { PaperDependencyChecker() } withOptions {
                named("dependencyChecker")
                bind<DependencyChecker>()
                bind<PaperDependencyChecker>()
                createdAtStart()
            }

            singleOf<StagingManager>(::StagingManagerImpl)
            singleOf(::ClientSynchronizer)
            singleOf(::PlayerSessionManager)
            singleOf(::CommunicationHandler)
            singleOf(::Writers)
            singleOf(::PanelHost)
            singleOf<SnippetDatabase>(::SnippetDatabaseImpl)
            singleOf(::FactDatabase)
            singleOf<FactStorage>(::FileFactStorage)
            singleOf(::EntryListeners)
            singleOf(::AudienceManager)
            singleOf<AssetStorage>(::LocalAssetStorage)
            singleOf<AssetManager>(::AssetManager)
            singleOf(::ChatHistoryHandler)
            singleOf(::ActionBarBlockerHandler)
            singleOf(::PacketInterceptor)
            singleOf(::EntityHandler)
            singleOf(::TypewriterCommandManager)

            factory { FactTracker(it.get()) } bind SessionTracker::class
            single { InteractionTriggerHandler() } bind TriggerHandler::class
            single { InteractionBoundHandler() } bind TriggerHandler::class
            single { ActionHandler() } bind TriggerHandler::class
            single { ContentHandler() } bind TriggerHandler::class
            single { DialogueHandler() } bind TriggerHandler::class
            single { FactHandler() } bind TriggerHandler::class
            single { TemporalHandler() } bind TriggerHandler::class

            single { TemporalPlaceholders() } bind PlaceholderHandler::class

            factory<Gson>(named("dataSerializer")) { createDataSerializerGson(getAll()) }
            factory<Gson>(named("bukkitDataParser")) { createBukkitDataParser() }

            single<ClassLoader>(named("globalClassloader")) { globalClassloader() }

            factory<Boolean>(named("isEnabled")) { isEnabled }
        }
        startKoin {
            modules(modules, TypewriterCore.module, dataSerializerModule)
        }
    }

    override suspend fun onEnableAsync() {
        PacketEvents.getAPI().settings.downsampleColors(false)

        get<FactDatabase>().initialize()
        get<AssetManager>().initialize()
        get<PlayerSessionManager>().initialize()
        get<ChatHistoryHandler>().initialize()
        get<ActionBarBlockerHandler>().initialize()
        get<PacketInterceptor>().initialize()
        get<AudienceManager>().initialize()
        get<EntityHandler>().initialize()

        if (server.pluginManager.getPlugin("PlaceholderAPI") != null) {
            PlaceholderExpansion.register()
        }

        BStatsMetrics.registerMetrics()

        // This is a hack to get the minecraft dispatcher.
        // As we need to dynamically add and remove commands on the fly
        this.lifecycleManager.registerEventHandler(LifecycleEvents.COMMANDS) {
            val manager = get<TypewriterCommandManager>()
            manager.registerDispatcher(it.registrar().dispatcher)
            if (it.cause() == ReloadableRegistrarEvent.Cause.RELOAD) {
                manager.registerCommands()
            }
        }
        // We want to initialize all the extensions after all the plugins have been enabled to make sure
        // that all the plugins are loaded.
        Dispatchers.Sync.launch {
            delay(100)
            load()
            get<CommunicationHandler>().initialize()

            delay(5.seconds)
            Modrinth.initialize()
        }
    }

    suspend fun load() {
        // Needs to be first, as it will load the classLoader
        get<TypewriterCore>().load()

        get<StagingManager>().loadState()
        get<CommunicationHandler>().load()
        get<PlayerSessionManager>().load()
        get<EntryListeners>().load()
        get<AudienceManager>().load()
        get<TypewriterCommandManager>().registerCommands()

        if (server.pluginManager.getPlugin("PlaceholderAPI") != null) {
            PlaceholderExpansion.load()
        }
    }

    suspend fun unload() {
        TypewriterUnloadEvent().callEvent()

        get<TypewriterCommandManager>().unregisterCommands()

        get<PacketInterceptor>().unload()
        get<AudienceManager>().unload()
        get<EntryListeners>().unload()
        get<PlayerSessionManager>().unload()
        get<StagingManager>().unload()

        if (server.pluginManager.getPlugin("PlaceholderAPI") != null) {
            PlaceholderExpansion.unload()
        }

        // Needs to be last, as it will unload the classLoader
        get<TypewriterCore>().unload()
    }

    suspend fun reload() {
        unload()
        load()
    }

    val isGeyserInstalled: Boolean by lazy { server.pluginManager.isPluginEnabled("Geyser-Spigot") }
    val isFloodgateInstalled: Boolean by lazy { server.pluginManager.isPluginEnabled("Floodgate") }

    override suspend fun onDisableAsync() {
        get<StagingManager>().shutdown()
        get<FactDatabase>().shutdown()
        get<ChatHistoryHandler>().shutdown()
        get<ActionBarBlockerHandler>().shutdown()
        get<PacketInterceptor>().shutdown()
        get<CommunicationHandler>().shutdown()
        get<PlayerSessionManager>().shutdown()
        get<AssetManager>().shutdown()
        get<AudienceManager>().shutdown()
        get<EntityHandler>().shutdown()

        unload()
    }
}

private class MinecraftLogger(private val logger: Logger) :
    org.koin.core.logger.Logger(logger.level.convertLogger()) {
    override fun display(level: Level, msg: MESSAGE) {
        when (level) {
            Level.DEBUG -> logger.fine(msg)
            Level.INFO -> logger.info(msg)
            Level.ERROR -> logger.severe(msg)
            Level.NONE -> logger.finest(msg)
            Level.WARNING -> logger.warning(msg)
        }
    }
}

fun java.util.logging.Level?.convertLogger(): Level {
    return when (this) {
        FINEST -> Level.DEBUG
        FINER -> Level.DEBUG
        FINE -> Level.DEBUG
        CONFIG -> Level.DEBUG
        INFO -> Level.INFO
        WARNING -> Level.WARNING
        SEVERE -> Level.ERROR
        else -> Level.INFO
    }
}

val logger: Logger by lazy { plugin.logger }

val plugin: TypewriterPaperPlugin by lazy { KoinJavaComponent.get(JavaPlugin::class.java) }