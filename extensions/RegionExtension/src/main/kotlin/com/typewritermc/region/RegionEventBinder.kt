package com.typewritermc.region

import com.typewritermc.core.entries.Query
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.region.data.hasConstPlacement
import com.typewritermc.region.entries.event.*
import com.typewritermc.region.handler.EnterExitHandler
import com.typewritermc.region.handler.ProximityHandler
import com.typewritermc.region.handler.RegionHandler
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.HandlerList
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerJoinEvent
import org.bukkit.event.player.PlayerQuitEvent
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList

/**
 * Connects the region event entries ([RegionEnterEventEntry], [RegionExitEventEntry],
 * [RegionProximityEventEntry]) to the [RegionEngine].
 *
 * A constant placement region gets one shared handler per entry, bound once at initialize.
 * The shared tracker classifies every crossing player against it, so a crossing fires the
 * entry once regardless of how many players are online. Viewer dependent regions are bound
 * per player on join, so only the viewer's own crossings of their own region fire.
 *
 * No explicit rebinding is needed on publish. `TypewriterCore.load()` reruns every
 * `Initializable` together with the entry library, so [initialize] always sees fresh
 * entries.
 *
 * The handler callbacks return [RegionEventDispatch]'s `shouldCancel` result. The
 * [RegionEngine] applies it by cancelling the Bukkit event and resyncing handler state to
 * the pre move position. Engulf crossings fire from the async tick loop and cannot be
 * cancelled.
 */
@Singleton
class RegionEventBinder : Initializable, Listener, KoinComponent {
    private val engine: RegionEngine by inject()
    private val sharedSubscriptions = CopyOnWriteArrayList<RegionEngine.Subscription>()
    private val playerSubscriptions = ConcurrentHashMap<UUID, List<RegionEngine.Subscription>>()

    /**
     * Resolved once at initialize, because [Query.find] filters the whole entry library and
     * [bindFor] would otherwise run three of those while a player is logging in.
     */
    @Volatile
    private var perPlayerEntries: List<RegionEventEntry> = emptyList()

    override suspend fun initialize() {
        server.pluginManager.registerEvents(this, plugin)
        reportUnresolvedRegions()

        perPlayerEntries = regionEventEntries().filterNot { it.isShared() }
        bindShared()
        // On the main thread because the server's list is the one PlayerList mutates there.
        withContext(Dispatchers.Sync) { server.onlinePlayers.toList() }.forEach(::bindFor)
    }

    private fun regionEventEntries(): List<RegionEventEntry> =
        Query.find<RegionEnterEventEntry>().toList() +
                Query.find<RegionExitEventEntry>().toList() +
                Query.find<RegionProximityEventEntry>().toList()

    /**
     * Names every event entry whose region does not resolve. Binding one is a no op, so the
     * entry sits on the page looking configured and never fires. Deleting the definition an
     * event points at is the easiest way to get there.
     */
    private fun reportUnresolvedRegions() {
        val unresolved = (
                Query.find<RegionEnterEventEntry>() +
                        Query.find<RegionExitEventEntry>() +
                        Query.find<RegionProximityEventEntry>()
                ).filter { it.region.resolveDefinition() == null }

        for (entry in unresolved) {
            logger.warning("Region event '${entry.name}' points at a region that does not resolve, so it never fires.")
        }
    }

    override suspend fun shutdown() {
        HandlerList.unregisterAll(this)
        sharedSubscriptions.forEach(RegionEngine.Subscription::cancel)
        sharedSubscriptions.clear()
        playerSubscriptions.values.forEach { it.forEach(RegionEngine.Subscription::cancel) }
        playerSubscriptions.clear()
    }

    @EventHandler
    fun onJoin(event: PlayerJoinEvent) = bindFor(event.player)

    // MONITOR so the engine's LOWEST priority quit dispatch fires final leave events
    // before these subscriptions are cancelled.
    @EventHandler(priority = EventPriority.MONITOR)
    fun onQuit(event: PlayerQuitEvent) {
        playerSubscriptions.remove(event.player.uniqueId)?.forEach(RegionEngine.Subscription::cancel)
    }

    private fun bindShared() {
        for (entry in regionEventEntries()) {
            if (!entry.isShared()) continue
            engine.observe(entry.region, null, handlerFor(entry, tracked = null))
                ?.let(sharedSubscriptions::add)
        }
    }

    private fun bindFor(player: Player) {
        // A player can quit between the roster snapshot and this bind. Their subscriptions would
        // hold a tracker that holds them, and only their own reconnect would ever cancel it.
        if (!player.isOnline) return
        // The subscriptions are taken outside the map update. Resolving a region evaluates its
        // placement variables,
        // which is user code, and a variable that reaches back into the binder from inside the
        // update would deadlock on the bin it holds. A join racing a reload binds twice, and the
        // set that loses the put is cancelled by the one that wins.
        val fresh = perPlayerEntries.mapNotNull { entry ->
            engine.observe(entry.region, player, handlerFor(entry, tracked = player.uniqueId))
        }
        playerSubscriptions.put(player.uniqueId, fresh)?.forEach(RegionEngine.Subscription::cancel)
    }

    private fun handlerFor(entry: RegionEventEntry, tracked: UUID?): RegionHandler = when (entry) {
        is RegionEnterEventEntry -> enterHandler(entry, tracked)
        is RegionExitEventEntry -> exitHandler(entry, tracked)
        is RegionProximityEventEntry -> proximityHandler(entry, tracked)
        else -> error("Unknown region event entry ${entry::class.simpleName}")
    }

    private fun RegionEventEntry.isShared(): Boolean =
        region.resolveDefinition()?.hasConstPlacement == true

    private fun enterHandler(entry: RegionEnterEventEntry, tracked: UUID?) = EnterExitHandler(
        owner = entry,
        tracked = tracked,
        boundaryInset = entry.boundaryInset,
        onEnter = { player, cause, _ -> RegionEventDispatch.fireEnter(entry, player, cause) },
    )

    private fun exitHandler(entry: RegionExitEventEntry, tracked: UUID?) = EnterExitHandler(
        owner = entry,
        tracked = tracked,
        boundaryInset = entry.boundaryInset,
        onLeave = { player, cause, _ -> RegionEventDispatch.fireExit(entry, player, cause) },
    )

    private fun proximityHandler(entry: RegionProximityEventEntry, tracked: UUID?) = ProximityHandler(
        owner = entry,
        tracked = tracked,
        distance = entry.distance,
        distanceMode = entry.distanceMode,
        boundaryInset = entry.boundaryInset,
        onEnterBand = { player, cause, _ -> RegionEventDispatch.fireProximity(entry, player, cause) },
        onLeaveBand = { player, cause, _ -> RegionEventDispatch.fireProximity(entry, player, cause) },
    )
}
