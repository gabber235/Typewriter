package com.typewritermc.roadnetwork

import com.google.common.cache.CacheBuilder
import com.google.common.cache.CacheLoader
import com.google.gson.Gson
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import de.bsommerfeld.pathetic.bukkit.PatheticBukkit
import de.bsommerfeld.pathetic.bukkit.listener.ChunkInvalidateListener
import kotlinx.coroutines.*
import org.bukkit.event.HandlerList
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import java.util.concurrent.TimeUnit

@Singleton
class RoadNetworkManager : Initializable, KoinComponent {
    private val gson by inject<Gson>(named("roadNetworkParser"))
    private val networks = CacheBuilder.newBuilder()
        .expireAfterAccess(10, TimeUnit.MINUTES)
        .build(CacheLoader.from(::loadRoadNetwork))

    private var job: Job? = null

    private val editors = CacheBuilder.newBuilder()
        .expireAfterAccess(2, TimeUnit.MINUTES)
        .removalListener<Ref<out RoadNetworkEntry>, RoadNetworkEditor> { notification ->
            Dispatchers.UntickedAsync.launch {
                notification.value?.dispose()
            }
        }
        .build(CacheLoader.from(::createEditor))

    override suspend fun initialize() {
        job = Dispatchers.UntickedAsync.launch {
            while (plugin.isEnabled) {
                delay(500)
                editors.asMap().values.forEach { it.refresh() }
            }
        }

        initializePathetic()
    }

    // Replaces PatheticBukkit.initialize to skip its bStats setup. bStats spins up a
    // ScheduledExecutorService that has no public shutdown hook, so on extension reload
    // it keeps firing tasks against the dead extension classloader and throws
    // NoClassDefFoundError. Registering only the chunk listener gives us pathfinding
    // without the leak.
    private fun initializePathetic() {
        val instanceField = PatheticBukkit::class.java.getDeclaredField("instance").apply { isAccessible = true }
        if (instanceField.get(null) != null) return
        instanceField.set(null, plugin)
        plugin.server.pluginManager.registerEvents(ChunkInvalidateListener(), plugin)
    }

    private fun loadRoadNetwork(id: String): CompletableDeferred<RoadNetwork> {
        val deferred = CompletableDeferred<RoadNetwork>()
        Dispatchers.UntickedAsync.launch {
            val network = try {
                Query.findById<RoadNetworkEntry>(id)?.loadRoadNetwork(gson)
            } catch (e: Exception) {
                logger.severe("Failed to load road network with id $id: ${e.message}")
                null
            } ?: RoadNetwork()

            deferred.complete(network)
        }
        return deferred
    }

    suspend fun getNetwork(ref: Ref<out RoadNetworkEntry>): RoadNetwork {
        return networks.get(ref.id).await()
    }

    @OptIn(ExperimentalCoroutinesApi::class)
    fun getNetworkOrNull(ref: Ref<out RoadNetworkEntry>): RoadNetwork? {
        val deferred = networks.get(ref.id)
        return if (deferred.isCompleted) deferred.getCompleted() else null
    }

    internal suspend fun saveRoadNetwork(ref: Ref<out RoadNetworkEntry>, network: RoadNetwork) {
        val entry = ref.get()
        if (entry == null) {
            logger.severe("Failed to save road network with id ${ref.id}")
            return
        }
        entry.saveRoadNetwork(gson, network)
        val old = networks.getIfPresent(ref.id)
        if (old != null && !old.isCompleted) {
            old.complete(network)
        } else {
            networks.put(ref.id, CompletableDeferred(network))
        }
    }

    private fun createEditor(ref: Ref<out RoadNetworkEntry>): RoadNetworkEditor {
        return RoadNetworkEditor(ref).also { it.load() }
    }

    fun getEditorNetwork(ref: Ref<out RoadNetworkEntry>): RoadNetworkEditor = editors.get(ref)

    override suspend fun shutdown() {
        job?.cancel()
        editors.asMap().values.forEach { it.dispose() }
        editors.invalidateAll()
        networks.invalidateAll()
        shutdownPathetic()
    }

    // TODO: Drop this once pathetic-bukkit ships its own PatheticBukkit.shutdown.
    private fun shutdownPathetic() {
        runCatching {
            HandlerList.getHandlerLists().forEach { list ->
                list.registeredListeners
                    .map { it.listener }
                    .filter { it.javaClass.name.contains("de.bsommerfeld.pathetic") }
                    .toSet()
                    .forEach(HandlerList::unregisterAll)
            }
            PatheticBukkit::class.java.getDeclaredField("instance")
                .apply { isAccessible = true }
                .set(null, null)
        }.onFailure { logger.warning("Failed to shutdown Pathetic: ${it.message}") }
    }
}