package com.typewritermc.region

import com.google.common.cache.CacheBuilder
import com.google.common.collect.Sets
import com.typewritermc.core.entries.Query
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.TICK_MS
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.engine.paper.utils.toPosition
import com.typewritermc.region.RegionEngine.Companion.MAX_INDEXED_CHUNK_SPAN
import com.typewritermc.region.data.CrossingCause
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.RegionDefinition
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.data.buildShapeOrNull
import com.typewritermc.region.data.describeInLog
import com.typewritermc.region.data.hasConstPlacement
import com.typewritermc.region.handler.LazyInsideQueryHandler
import com.typewritermc.region.handler.RegionHandler
import com.typewritermc.region.tracker.RegionTracker
import com.typewritermc.region.tracker.Tier
import com.typewritermc.region.tracker.TrackerKey
import it.unimi.dsi.fastutil.objects.ObjectHeapPriorityQueue
import it.unimi.dsi.fastutil.objects.ReferenceLinkedOpenHashSet
import kotlinx.coroutines.*
import org.bukkit.Location
import org.bukkit.entity.Entity
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.HandlerList
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerJoinEvent
import org.bukkit.event.player.PlayerMoveEvent
import org.bukkit.event.player.PlayerQuitEvent
import org.bukkit.event.player.PlayerTeleportEvent
import org.bukkit.event.vehicle.VehicleMoveEvent
import org.bukkit.util.BoundingBox
import org.koin.core.component.KoinComponent
import java.util.*
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.ConcurrentMap
import java.util.concurrent.ConcurrentLinkedQueue
import kotlin.time.Duration.Companion.milliseconds

/**
 * The entry point of the extension. Consumers obtain it via Koin and call [observe] or
 * [query].
 *
 * The engine keeps a registry of trackers keyed by [TrackerKey]. Static trackers with a
 * bounded AABB live in a chunk index, so a move only consults the trackers around the
 * crossed chunks, the trackers the player is currently a member of, and the few unindexable
 * ones. A Bukkit listener dispatches moves and teleports on the main thread, where
 * [cancellation][RegionHandler.onClassification] is possible. A tick loop refreshes dynamic
 * trackers at their refresh rate through an every tick bucket and a due time heap, instead
 * of scanning all trackers each tick.
 *
 * All shared state lives in concurrent collections. The due time heap is only touched by
 * the tick loop coroutine and is fed through [pendingScheduling]. A suspending mutex cannot
 * be used here because the producers run inside non suspending Bukkit event handlers.
 */
@Singleton
class RegionEngine : Initializable, Listener, KoinComponent {
    private val trackers = ConcurrentHashMap<TrackerKey, RegionTracker>()

    private val chunkIndex = ConcurrentHashMap<ChunkKey, MutableSet<RegionTracker>>()
    private val indexedChunks = ConcurrentHashMap<RegionTracker, List<ChunkKey>>()
    private val unindexed: MutableSet<RegionTracker> = Sets.newConcurrentHashSet()

    private val playerTrackers = ConcurrentHashMap<UUID, MutableSet<RegionTracker>>()

    /** Trackers holding a refusal against a player, so it can be lifted when their next move lands. */
    private val refusedTrackers = ConcurrentHashMap<UUID, MutableSet<RegionTracker>>()

    /** Maintained here because the server's own list is not safe to walk off the main thread. */
    private val online = ConcurrentHashMap<UUID, Player>()

    /**
     * `false` until [initialize] has read the roster.
     *
     * Nothing orders the extension's [Initializable]s, so handlers attach and dispatch before the
     * engine knows who is online. An empty roster is "not heard of yet" there, not "gone", and
     * treating the two alike would evict every player during a publish.
     */
    @Volatile
    private var rosterKnown = false

    /**
     * Trackers for regions nobody subscribes to, kept so repeated fact and variable reads
     * do not rebuild one per call.
     *
     * The cache is bounded and evicts one entry at a time. Its natural size is players
     * times definitions, so any fixed bound is reached on a busy server, and a map emptied
     * whenever it fills would make every read that follows evaluate every placement variable
     * again, on exactly the servers that need the cache. Evicting one entry keeps the rest
     * warm.
     */
    private val queryCache: ConcurrentMap<TrackerKey, RegionTracker> = CacheBuilder.newBuilder()
        .maximumSize(QUERY_CACHE_MAX)
        .build<TrackerKey, RegionTracker>()
        .asMap()

    private val everyTick: MutableSet<RegionTracker> = Sets.newConcurrentHashSet()
    private val pendingScheduling = ConcurrentLinkedQueue<RegionTracker>()

    /** The tick each still failing tracker first threw on, so it is logged at an interval, not every tick. */
    private val failingTrackers = ConcurrentHashMap<RegionTracker, Long>()

    /** Trackers whose dispatch threw, so a broken region is named once rather than on every move. */
    private val failingDispatch: MutableSet<RegionTracker> = Sets.newConcurrentHashSet()

    /** The definitions already named for having no usable shape, emptied on every publish. */
    private val reportedUnusable: MutableSet<RegionDefinition> = Sets.newConcurrentHashSet()

    private var tickJob: Job? = null
    private var scope: CoroutineScope? = null

    override suspend fun initialize() {
        reportedUnusable.clear()
        queryCache.clear()
        reportUnbuildableDefinitions()
        scope = CoroutineScope(SupervisorJob() + Dispatchers.UntickedAsync)
        // The listener is registered before the roster is read, because this runs off the main
        // thread on every
        // publish: a player joining between the two would be in neither, and the engine would
        // not see them again until the next reload. Recording a joiner twice costs nothing.
        server.pluginManager.registerEvents(this, plugin)
        // On the main thread because the server's list is the one PlayerList mutates there, and
        // the roster is recorded there too: a player quitting between the read and the writes
        // would be put back into [online] by them, and nothing would ever take them out again.
        withContext(Dispatchers.Sync) { recordRoster(server.onlinePlayers) }
        seedTrackersRegisteredBeforeTheRoster()
        tickJob = scope?.launch { runTickLoop() }
    }

    /**
     * Records who is online, after which a viewer missing from the roster is a viewer who has
     * left. Internal so a test can drive the roster without a whole [initialize].
     */
    internal fun recordRoster(players: Collection<Player>) {
        players.forEach { online[it.uniqueId] = it }
        rosterKnown = true
    }

    /**
     * Aligns the handlers that attached before this engine knew who was online.
     *
     * Nothing orders the extension's [Initializable]s, so the event binder and the audience
     * manager can attach handlers here before [initialize] runs. Their seeding walks a roster
     * that is still empty, leaving every player standing inside a region a non member, and the
     * first move each of them makes fires an enter. Once per publish, for everyone indoors.
     */
    private fun seedTrackersRegisteredBeforeTheRoster() {
        val players = onlinePlayers()
        if (players.isEmpty()) return
        for (tracker in trackers.values) {
            if (!tracker.isRegistered) continue
            // Each tracker is isolated, as in every other loop over them. A placement variable that
            // throws while being seeded would otherwise leave every tracker behind it unaligned,
            // and each of those fires a spurious enter for everyone already standing inside.
            runCatching {
                tracker.seedHandlers(players)
                for (player in players) updateMembershipIndex(player, tracker)
            }.onFailure {
                logger.severe("Region '${tracker.definitionName}' could not be aligned after the publish:")
                logger.severe(it.stackTraceToString())
            }
        }
    }

    /**
     * Names every named definition whose fields do not describe a valid shape. Such a definition
     * is skipped everywhere else in silence, and a region that quietly matches nothing is
     * the hardest kind of failure for a builder to diagnose.
     *
     * An inline definition has no entry of its own to sweep, so it is named through
     * [reportUnusableShape] when something first tries to resolve it.
     */
    private fun reportUnbuildableDefinitions() {
        for (entry in Query.find<RegionDefinitionEntry>()) {
            if (entry.buildShapeOrNull()?.usable != true) reportUnusableShape(entry)
        }
    }

    /**
     * Names [definition] in the console for having no usable shape, once per publish.
     *
     * The lookups that reach this run per fact read and per display tick, and an unusable shape
     * stays unusable, so the definitions already named are remembered rather than repeated.
     */
    private fun reportUnusableShape(definition: RegionDefinition) {
        if (!reportedUnusable.add(definition)) return

        val consequence =
            "Every event, audience, fact and display pointing at it does nothing until it is fixed."
        val failure = runCatching { definition.buildShape() }.exceptionOrNull()
        if (failure != null) {
            logger.warning("${definition.describeInLog()} has no usable shape: ${failure.message} $consequence")
            return
        }
        logger.warning(
            "${definition.describeInLog()} has no usable shape: its fields do not describe a volume, " +
                    "like a polygon of fewer than three points. $consequence"
        )
    }

    override suspend fun shutdown() {
        HandlerList.unregisterAll(this)

        tickJob?.cancelAndJoinBounded()
        tickJob = null
        scope?.coroutineContext?.job?.cancelAndJoinBounded()
        scope = null

        trackers.clear()
        chunkIndex.clear()
        indexedChunks.clear()
        unindexed.clear()
        playerTrackers.clear()
        refusedTrackers.clear()
        rosterKnown = false
        online.clear()
        queryCache.clear()
        everyTick.clear()
        pendingScheduling.clear()
        failingTrackers.clear()
        failingDispatch.clear()
        reportedUnusable.clear()
    }

    /**
     * Subscribes a handler to a region. All subscribers of a constant placement definition
     * share one tracker. Viewer dependent definitions get one tracker per [viewer].
     *
     * Returns `null` when [data] is an unresolved reference, or when the definition is
     * viewer dependent and no [viewer] was given.
     */
    fun observe(data: RegionData, viewer: Player?, handler: RegionHandler): Subscription? {
        val definition = data.resolveDefinition() ?: return null
        val shared = definition.hasConstPlacement
        if (!shared && viewer == null) return null

        val key = TrackerKey(definition, if (shared) null else viewer?.uniqueId)
        while (true) {
            val tracker = trackers[key] ?: claim(key, definition, viewer.takeUnless { shared }) ?: return null

            // The handler is attached under the registry's own lock, so it cannot land between
            // another thread
            // finding this tracker empty and removing it. That handler would be subscribed to a
            // tracker no dispatch reaches any more, and its entry would never fire again.
            val attached = trackers.computeIfPresent(key) { _, current ->
                if (current === tracker) current.attach(handler)
                current
            }
            if (attached === tracker) {
                reindex(tracker)
                // The handler is attached by now, so a throwing seed must not escape: the caller
                // would never receive the subscription that cancels it, and a handler nothing can
                // detach keeps its tracker, and the player it captured, alive until the next
                // publish. Seeding only aligns the starting membership; the handler works without it.
                runCatching { seed(tracker, handler) }.onFailure {
                    logger.severe("Region '${tracker.definitionName}' failed to align a new subscriber:")
                    logger.severe(it.stackTraceToString())
                }
                return Subscription(this, key, handler, tracker)
            }
            // A concurrent detach removed the tracker from the registry, or replaced it. Retry.
        }
    }

    /**
     * Registers a tracker for [key], or returns the one another thread registered first.
     * `null` when the definition's fields do not describe a valid shape.
     *
     * The resolve runs before the insert and outside the map on purpose. It evaluates the
     * definition's placement `Var`s, which is user code that may call back into the engine,
     * and a [ConcurrentHashMap] mapping function would hold a bin lock across that.
     */
    private fun claim(key: TrackerKey, definition: RegionDefinition, viewer: Player?): RegionTracker? {
        val shape = definition.buildShapeOrNull()
        if (shape?.usable != true) reportUnusableShape(definition)
        if (shape == null) return null
        val fresh = RegionTracker(viewer, definition)
        fresh.isRegistered = true
        // The first read of the placement variables, and the one place they are read before the
        // tracker is registered anywhere. A throw here escaping would reach whichever subscriber
        // asked, and the event binder is mid way through replacing that player's subscriptions
        // when it does: they would lose every region event for the rest of the session.
        val resolved = runCatching { fresh.refresh() }.onFailure {
            logger.severe("${definition.describeInLog()} could not resolve its placement:")
            logger.severe(it.stackTraceToString())
        }
        if (resolved.isFailure) return null

        val winner = trackers.putIfAbsent(key, fresh)
        if (winner != null) {
            fresh.isRegistered = false
            return winner
        }
        register(key, fresh)

        // The roster is read after the insert, and the quit handler empties it before it sweeps
        // the registry, so one of the two always sees the other: a tracker claimed for a player
        // who is already leaving would otherwise outlive them, keep their Player object reachable,
        // and sit in the unindexed set that every move of every other player walks.
        val viewerId = key.viewerId
        if (viewerId != null && rosterKnown && !online.containsKey(viewerId)) {
            trackers.remove(key, fresh)
            unregister(key, fresh)
            return null
        }
        return fresh
    }

    /**
     * Resolves a tracker for an immediate read, without subscribing. Returns the registered
     * tracker when one exists, otherwise a cached tracker without subscribers. The cached
     * tracker's transform is refreshed on every call for dynamic definitions.
     *
     * Facts, variables and one shot actions should use this. Callers that want
     * notifications should use [observe].
     */
    fun query(data: RegionData, viewer: Player): RegionTracker? {
        val definition = data.resolveDefinition() ?: return null
        val shared = definition.hasConstPlacement
        val key = TrackerKey(definition, if (shared) null else viewer.uniqueId)

        trackers[key]?.let { return it }
        queryCache[key]?.let { tracker ->
            if (tracker.tier == Tier.Dynamic) tracker.refresh()
            return tracker
        }

        // The shape is checked below the cache lookups, so a cache hit never pays for building one.
        val shape = definition.buildShapeOrNull()
        if (shape?.usable != true) reportUnusableShape(definition)
        if (shape == null) return null
        val tracker = RegionTracker(viewer.takeUnless { shared }, definition)
        tracker.refresh()
        return queryCache.putIfAbsent(key, tracker) ?: tracker
    }

    /**
     * The registered tracker events and audiences of [data] observe for [viewer], or `null`
     * when nothing observes it. Unlike [query] this never creates a tracker, so diagnostics
     * can tell "the region resolves fine" apart from "nothing is subscribed at all".
     */
    fun registeredTracker(data: RegionData, viewer: Player): RegionTracker? {
        val definition = data.resolveDefinition() ?: return null
        val shared = definition.hasConstPlacement
        return trackers[TrackerKey(definition, if (shared) null else viewer.uniqueId)]
    }

    private fun register(key: TrackerKey, tracker: RegionTracker) {
        queryCache.remove(key)
        schedule(tracker)
    }

    /**
     * Aligns a fresh handler's membership with the current player positions without firing
     * callbacks. Without this, subscribing again after a publish would fire enter events for
     * every player who was already inside.
     */
    private fun seed(tracker: RegionTracker, handler: RegionHandler) {
        if (handler is LazyInsideQueryHandler) return

        val tracked = handler.tracked
        if (tracked != null) {
            val player = server.getPlayer(tracked) ?: return
            tracker.seedHandler(player, handler)
            updateMembershipIndex(player, tracker)
            return
        }

        for (player in onlinePlayers()) {
            tracker.seedHandler(player, handler)
            updateMembershipIndex(player, tracker)
        }
    }

    internal fun detach(key: TrackerKey, handler: RegionHandler) {
        var emptied: RegionTracker? = null
        // The detach and the emptiness decision share the registry's lock with [observe]'s
        // attach, so a subscription arriving in between is never dropped on a tracker that is
        // about to leave the registry.
        val kept = trackers.computeIfPresent(key) { _, tracker ->
            tracker.detach(handler)
            if (!tracker.isEmpty()) return@computeIfPresent tracker
            emptied = tracker
            null
        }
        kept?.let { reindex(it) }
        emptied?.let { unregister(key, it) }
    }

    private fun unregister(key: TrackerKey, tracker: RegionTracker) {
        tracker.isRegistered = false
        everyTick.remove(tracker)
        failingTrackers.remove(tracker)
        failingDispatch.remove(tracker)
        reindex(tracker)

        for (memberships in playerTrackers.values) {
            memberships.remove(tracker)
        }
        for (refusals in refusedTrackers.values) {
            refusals.remove(tracker)
        }
    }

    /**
     * Places a tracker in the spatial structures. A tracker with a bounded margin and a chunk
     * span within [MAX_INDEXED_CHUNK_SPAN] goes into the chunk index. Every other tracker goes
     * into the [unindexed] set, which every move consults.
     *
     * A dynamic tracker is indexed too, and reindexed each time it refreshes. Excluding them
     * puts one entry per viewer per moving region into [unindexed], and every move of every
     * player then walks all of them.
     */
    private fun reindex(tracker: RegionTracker) {
        placeInIndex(tracker)
        // The check inside and the writes it makes are not one step, so an unregister running
        // alongside can strip the tracker and then have this thread put it back. The sweep is
        // repeated with the flag as it stands after the writes, which either finds the tracker
        // still registered and leaves it alone, or takes it out for good.
        if (!tracker.isRegistered) placeInIndex(tracker)
    }

    private fun placeInIndex(tracker: RegionTracker) {
        // The read of the old keys, the writes and the strip are one update of this map, so two
        // threads reindexing the same tracker cannot both work from the same starting set. When
        // one of those two writes loses, the tracker sits in chunks that nothing records, and no
        // later reindex or unregister can take it out of them again.
        indexedChunks.compute(tracker) { _, indexed ->
            val previous = indexed.orEmpty()
            // An unregistered tracker leaves the structures entirely. Treating it as merely
            // unindexable parks it in [unindexed], which every move walks, and the tracker holds
            // its viewer, so one logout would pin that player for the life of the server.
            if (!tracker.isRegistered) {
                unindexed.remove(tracker)
                stripFromChunkIndex(tracker, previous, keeping = emptySet())
                return@compute null
            }
            val keys = chunkKeysFor(tracker)
            if (keys == null) {
                unindexed.add(tracker)
                stripFromChunkIndex(tracker, previous, keeping = emptySet())
                return@compute null
            }
            if (keys == previous) return@compute previous

            // The new keys are added before the stale ones are stripped, with the new set in hand, so
            // a move dispatching in between always finds the tracker under one set of keys or the
            // other. Stripping first opens a window where the tracker is in no chunk at all, and a
            // crossing in that window is simply lost.
            for (chunkKey in keys) {
                chunkIndex.compute(chunkKey) { _, set ->
                    (set ?: Sets.newConcurrentHashSet()).apply { add(tracker) }
                }
            }
            stripFromChunkIndex(tracker, previous, keeping = keys.toSet())
            unindexed.remove(tracker)
            keys
        }
    }

    /** The chunks [tracker] belongs in, or `null` when it cannot be indexed by chunk at all. */
    private fun chunkKeysFor(tracker: RegionTracker): List<ChunkKey>? {
        if (tracker.marginUnbounded) return null
        val aabb = tracker.cachedAabb ?: return null

        val spanX = aabb.maxChunkX - aabb.minChunkX + 1
        val spanZ = aabb.maxChunkZ - aabb.minChunkZ + 1
        if (spanX.toLong() * spanZ > MAX_INDEXED_CHUNK_SPAN) return null

        val keys = ArrayList<ChunkKey>(spanX * spanZ)
        for (chunkX in aabb.minChunkX..aabb.maxChunkX) {
            for (chunkZ in aabb.minChunkZ..aabb.maxChunkZ) {
                keys.add(ChunkKey(aabb.world, chunkX, chunkZ))
            }
        }
        return keys
    }

    private fun stripFromChunkIndex(tracker: RegionTracker, previous: List<ChunkKey>, keeping: Set<ChunkKey>) {
        for (chunkKey in previous) {
            if (chunkKey in keeping) continue
            // The removal happens inside compute so it cannot delete a bucket another thread is
            // in the middle of populating.
            chunkIndex.compute(chunkKey) { _, set ->
                set?.apply { remove(tracker) }?.takeIf { it.isNotEmpty() }
            }
        }
    }

    @EventHandler(priority = EventPriority.HIGH, ignoreCancelled = true)
    fun onMove(event: PlayerMoveEvent) {
        // PlayerTeleportEvent extends PlayerMoveEvent. Teleports are handled in onTeleport,
        // so they are skipped here to fire each crossing exactly once.
        if (event is PlayerTeleportEvent) return
        if (!event.hasChangedBlock()) return
        val player = event.player
        // The player steering a vehicle gets this event from the vehicle's packet, and cancelling
        // it puts the rider back without the vehicle, which carries them across on its next packet
        // anyway. So a ride crosses with no event to refuse, like a passenger who sends none, and
        // no refusal is recorded for a crossing that stands.
        val revocable = event.takeUnless { player.isInsideVehicle }
        dispatchMove(player, event.from, event.to, CrossingCause.PLAYER_MOVED, revocable)
    }

    @EventHandler(priority = EventPriority.HIGH, ignoreCancelled = true)
    fun onTeleport(event: PlayerTeleportEvent) {
        dispatchMove(event.player, event.from, event.to, CrossingCause.TELEPORTED, event)
    }

    /**
     * Only the player steering a vehicle sends move packets, so only they get a [PlayerMoveEvent]
     * while riding. Anyone else aboard a boat or a minecart, and anyone in a minecart rolling on
     * its own, crosses a static region's boundary with nothing firing unless the vehicle's own
     * event is watched. Boats and minecarts are the only vehicles that fire one; a second rider
     * on a camel crosses unseen until the region moves and its reconcile catches them.
     *
     * The steering player is dispatched twice per crossing, once from each event. The second
     * classifies them where the first already put them, so it fires nothing.
     *
     * [VehicleMoveEvent] cannot be cancelled, so a crossing on this path ignores cancellation
     * requests the same way an engulf does.
     */
    @EventHandler(priority = EventPriority.MONITOR)
    fun onVehicleMove(event: VehicleMoveEvent) {
        if (event.from.blockX == event.to.blockX &&
            event.from.blockY == event.to.blockY &&
            event.from.blockZ == event.to.blockZ &&
            event.from.world == event.to.world
        ) return

        for (player in ridingPlayers(event.vehicle)) {
            dispatchMove(player, event.from, player.location, CrossingCause.PLAYER_MOVED, null)
        }
    }

    /** Every player riding [vehicle], however deep the stack of mounts is. */
    private fun ridingPlayers(vehicle: Entity): List<Player> = vehicle.passengers.flatMap { passenger ->
        if (passenger is Player) listOf(passenger) else ridingPlayers(passenger)
    }

    // LOWEST so the roster holds the joiner before anything else binds to a region. The audience
    // manager and the event binder both subscribe from this event at NORMAL, and a subscription
    // for a viewer the roster has never heard of is read as a subscription for someone who has
    // already left: their trackers would be claimed and immediately thrown away again.
    @EventHandler(priority = EventPriority.LOWEST)
    fun onJoin(event: PlayerJoinEvent) {
        online[event.player.uniqueId] = event.player
    }

    // LOWEST so the final leave dispatch runs before other listeners, like the event
    // binder's MONITOR cleanup, cancel their subscriptions.
    @EventHandler(priority = EventPriority.LOWEST)
    fun onQuit(event: PlayerQuitEvent) {
        val player = event.player
        val uuid = player.uniqueId
        // The roster entry goes first: the tick loop reconciles against this map, and a reconcile landing
        // after the memberships below are cleared would put the leaver straight back into them.
        online.remove(uuid)

        releaseRefusals(player)
        // Then every tracker, not only the ones that held a refusal. A handler also remembers which
        // way the player crossed it last, so it can tell a rollback of its own crossing from one it
        // had no part in, and a player whose last crossing took them out of a region is in none of
        // the sets a later dispatch or the sweep below would reach. Left behind, that one entry per
        // player per handler is never read again and never freed.
        for (tracker in trackers.values) tracker.clearRefusals(player)
        // Each tracker is isolated: the leave callbacks run the subscribing entries' own code, and a
        // throw from one of them would take the sweep below with it, leaving the quitter's
        // trackers in the registry and their Player reachable for as long as the server runs.
        playerTrackers.remove(uuid)?.forEach { tracker ->
            runCatching { tracker.evict(player, CrossingCause.DISCONNECTED) }.onFailure {
                logger.severe("Region '${tracker.definitionName}' failed to release ${player.name} on quit:")
                logger.severe(it.stackTraceToString())
            }
        }
        // The registry is swept, with no index of each viewer's keys. Such an index has to be
        // written outside the registry's own lock, and a subscription landing during the quit
        // then leaves a tracker nothing sweeps. A quit is rare enough to pay for a pass over the
        // registry, which the query cache below pays for too.
        for (key in trackers.keys.filter { it.viewerId == uuid }) {
            trackers.remove(key)?.let { unregister(key, it) }
        }
        queryCache.keys.removeIf { it.viewerId == uuid }
    }

    /**
     * Dispatches a crossing on the main thread. The candidates are the trackers indexed
     * under the from and to chunks, the unindexed ones, and the trackers the player is a
     * member of. When a handler requests cancellation, the Bukkit event is cancelled and
     * every touched tracker is resynced against the pre move position, so no handler keeps
     * state from the rolled back crossing.
     */
    private fun dispatchMove(
        player: Player,
        from: Location,
        to: Location,
        cause: CrossingCause,
        event: PlayerMoveEvent?,
    ) {
        val toPosition = to.toPosition()

        val candidates = ReferenceLinkedOpenHashSet<RegionTracker>()
        val toChunk = ChunkKey(toPosition.world, to.blockX shr 4, to.blockZ shr 4)
        chunkIndex[toChunk]?.let(candidates::addAll)
        val fromChunk = ChunkKey(World(from.world.uid.toString()), from.blockX shr 4, from.blockZ shr 4)
        if (fromChunk != toChunk) chunkIndex[fromChunk]?.let(candidates::addAll)
        candidates.addAll(unindexed)
        playerTrackers[player.uniqueId]?.let(candidates::addAll)
        if (candidates.isEmpty()) {
            releaseRefusals(player)
            return
        }

        var cancelled = false
        val box = player.boundingBox
        val touched = ArrayList<RegionTracker>(candidates.size)
        for (tracker in candidates) {
            if (!tracker.isRegistered) continue
            if (!tracker.wantsDispatch()) continue
            if (!withinInfluence(tracker, box, toPosition) && !tracker.hasMember(player)) continue

            touched.add(tracker)
            if (dispatchIsolated(tracker, player, toPosition, cause, event)) cancelled = true
            updateMembershipIndex(player, tracker)
        }
        if (!cancelled || touched.isEmpty() || event == null) {
            releaseRefusals(player)
            return
        }

        event.isCancelled = true
        val fromPosition = from.toPosition()
        for (tracker in touched) {
            runCatching { tracker.resyncAt(player, fromPosition) }
                .onFailure { reportDispatchFailure(tracker, it) }
            updateMembershipIndex(player, tracker)
        }
        refusedTrackers.computeIfAbsent(player.uniqueId) { Sets.newConcurrentHashSet() }.addAll(touched)
    }

    /**
     * Dispatches one tracker, keeping its failures to itself.
     *
     * A dispatch runs the subscribing entries' own code, and the band a proximity handler reads is
     * a variable that throws on every read once its entry is deleted. Letting that escape skips
     * every candidate behind this one, so unrelated regions miss the crossing entirely, leaves the
     * membership index disagreeing with the handler, and strands the refusal from the previous
     * move, which the tracker then keeps replaying until some later move happens to lift it.
     */
    private fun dispatchIsolated(
        tracker: RegionTracker,
        player: Player,
        position: Position,
        cause: CrossingCause,
        event: PlayerMoveEvent?,
    ): Boolean {
        val cancelled = runCatching { tracker.dispatch(player, position, cause, event) }
            .onFailure {
                reportDispatchFailure(tracker, it)
                // Nothing rolls a throwing tracker back, so nothing would ever lift a refusal it
                // recorded on the way down either. Left held, it answers every later crossing of
                // that player and the region stops seeing them entirely.
                runCatching { tracker.clearRefusals(player) }
            }
            .getOrNull() ?: return false

        if (failingDispatch.remove(tracker)) {
            logger.warning("Region '${tracker.definitionName}' reacts to crossings again.")
        }
        return cancelled
    }

    /**
     * Names a tracker whose dispatch threw, once.
     *
     * A move fires per player per tick, so the same broken region would otherwise print a stack
     * trace several times a second. It stays silent until the tracker works again, which
     * [dispatchIsolated] says out loud.
     */
    private fun reportDispatchFailure(tracker: RegionTracker, failure: Throwable) {
        if (!failingDispatch.add(tracker)) return
        logger.severe(
            "Region '${tracker.definitionName}' failed on a crossing. It stops reacting to them:"
        )
        logger.severe(failure.stackTraceToString())
    }

    /**
     * Forgets every refusal held against [player]. A refusal only means "the crossing you just
     * made was undone", so the first move of theirs that survives ends it.
     *
     * Without this the refusal outlives its move: a player rolled back out of a tracker's
     * reach is never dispatched to it again, and the tracker would still be holding their
     * refusal the next time they teleport in.
     */
    private fun releaseRefusals(player: Player) {
        if (refusedTrackers.isEmpty()) return
        val trackers = refusedTrackers.remove(player.uniqueId) ?: return
        for (tracker in trackers) tracker.clearRefusals(player)
    }

    private fun withinInfluence(tracker: RegionTracker, box: BoundingBox, position: Position): Boolean {
        if (tracker.marginUnbounded) return true
        val aabb = tracker.cachedAabb ?: return false
        return aabb.reachableBy(position, box)
    }

    private fun updateMembershipIndex(player: Player, tracker: RegionTracker) {
        val uuid = player.uniqueId
        val member = tracker.hasMember(player)
        var departed = false

        // A reconcile in flight can land after the quit handler cleared this player, and
        // recreating their entry here would keep the tracker, and their Player, alive forever.
        // The roster is read inside the update so the two share the bin lock: read outside it,
        // a quit landing in between is simply overwritten by the write that follows.
        playerTrackers.compute(uuid) { _, memberships ->
            if (rosterKnown && !online.containsKey(uuid)) {
                departed = true
                return@compute memberships?.apply { remove(tracker) }
            }
            if (!member) return@compute memberships?.apply { remove(tracker) }
            (memberships ?: Sets.newConcurrentHashSet()).apply { add(tracker) }
        }
        if (!departed) return

        // The handlers are evicted as well as the index entry: the same late dispatch will have
        // written the player back into their membership sets, and on their next login the tracker
        // would believe they never left.
        //
        // The player is evicted without asking Bukkit whether they are gone: a quitting player
        // is still online for the whole quit chain, so that question is always answered "no"
        // here. The dispatch that wrote the membership back fired an enter, the tracker is
        // already out of the index above so the quit's own sweep will not reach it, and nothing
        // else pairs a leave with that enter.
        tracker.evict(player, CrossingCause.DISCONNECTED)
    }

    private fun schedule(tracker: RegionTracker) {
        if (tracker.tier != Tier.Dynamic) return

        if (tracker.refreshRateTicks <= 1) {
            everyTick.add(tracker)
        } else {
            pendingScheduling.add(tracker)
        }
    }

    /**
     * The due time heap is only used inside this coroutine. New dynamic trackers arrive
     * through [pendingScheduling]. Unregistered trackers are dropped when they come due.
     */
    private suspend fun runTickLoop() {
        val heap = ObjectHeapPriorityQueue<ScheduledRefresh>(compareBy { it.dueTick })
        var tick = 0L
        var failingSince = 0L

        while (true) {
            val tickStart = System.currentTimeMillis()
            tick += 1
            try {
                tickDynamicTrackers(heap, tick)
                if (failingSince != 0L) {
                    logger.warning("RegionEngine tick recovered after ${tick - failingSince} failed ticks.")
                    failingSince = 0L
                }
            } catch (throwable: Throwable) {
                // The first failure in full and the ones after it at an interval, so a persistent
                // failure is visible in the console without filling it every tick.
                if (failingSince == 0L) {
                    failingSince = tick
                    logger.severe("RegionEngine tick failed. Dynamic regions stop updating while this persists:")
                    logger.severe(throwable.stackTraceToString())
                } else if ((tick - failingSince) % FAILURE_LOG_INTERVAL_TICKS == 0L) {
                    logger.warning("RegionEngine tick still failing (${throwable::class.simpleName}: ${throwable.message})")
                }
            }

            val elapsed = System.currentTimeMillis() - tickStart
            val wait = TICK_MS - elapsed
            // The tick body has no suspension point, so without this a tick that runs
            // longer than TICK_MS leaves the loop with nowhere to observe cancellation and
            // shutdown can only time out.
            if (wait > 0) delay(wait.milliseconds) else yield()
        }
    }

    private fun tickDynamicTrackers(heap: ObjectHeapPriorityQueue<ScheduledRefresh>, tick: Long) {
        for (tracker in everyTick) {
            if (!tracker.isRegistered) {
                everyTick.remove(tracker)
                continue
            }
            refreshIsolated(tracker, tick)
        }

        while (true) {
            val tracker = pendingScheduling.poll() ?: break
            if (!tracker.isRegistered) continue
            heap.enqueue(ScheduledRefresh(tick + tracker.refreshRateTicks, tracker))
        }

        while (!heap.isEmpty && heap.first().dueTick <= tick) {
            val tracker = heap.dequeue().tracker
            if (!tracker.isRegistered) continue

            refreshIsolated(tracker, tick)
            heap.enqueue(ScheduledRefresh(tick + tracker.refreshRateTicks, tracker))
        }
    }

    /**
     * Refreshes one tracker, keeping its failures to itself.
     *
     * A placement variable whose entry was deleted throws on every read, and the dispatch that
     * follows runs the subscribing entries' own code. Letting either escape would skip every
     * tracker behind this one in the tick, leave the scheduling queue unread, and take the
     * failing tracker out of the heap for good: one broken region would freeze every moving
     * region on the server.
     */
    private fun refreshIsolated(tracker: RegionTracker, tick: Long) {
        val failure = runCatching { refreshAndReconcile(tracker) }.exceptionOrNull()
        if (failure == null) {
            val failingSince = failingTrackers.remove(tracker) ?: return
            logger.warning("Region '${tracker.definitionName}' updates again after ${tick - failingSince} failed ticks.")
            return
        }

        val failingSince = failingTrackers.putIfAbsent(tracker, tick)
        if (failingSince == null) {
            logger.severe("Region '${tracker.definitionName}' failed to update. It stops following its placement:")
            logger.severe(failure.stackTraceToString())
            return
        }
        if ((tick - failingSince) % FAILURE_LOG_INTERVAL_TICKS == 0L) {
            logger.warning(
                "Region '${tracker.definitionName}' still failing " +
                        "(${failure::class.simpleName}: ${failure.message})"
            )
        }
    }

    /**
     * Resolves the transform again, since a dynamic placement may have moved, and reconciles
     * every online player with [CrossingCause.ENGULFED]. Cancellation requests are ignored
     * on this path. Internal so tests can drive the reconcile deterministically.
     */
    internal fun refreshAndReconcile(tracker: RegionTracker) {
        tracker.refresh()
        reindex(tracker)
        if (!tracker.wantsDispatch()) return

        // A per viewer tracker only carries handlers for that one viewer, so classifying anyone
        // else is work whose result is thrown away by the handler's own filter.
        for (player in tracker.viewer?.let(::listOf) ?: onlinePlayers()) {
            if (!player.isOnline) continue
            val position = player.position
            if (!withinInfluence(tracker, player.boundingBox, position) && !tracker.hasMember(player)) continue

            tracker.dispatch(player, position, CrossingCause.ENGULFED, null)
            updateMembershipIndex(player, tracker)
        }
    }

    /**
     * The online players, as a collection safe to walk off the main thread.
     *
     * `server.onlinePlayers` is a live view over the list the server mutates when someone joins
     * or leaves, so iterating it from the tick loop throws as soon as either happens.
     */
    internal fun onlinePlayers(): Collection<Player> = online.values

    /**
     * Handle returned to a subscriber, used to detach later. The [tracker] is exposed so
     * displays can read the cached transform without querying again.
     */
    class Subscription internal constructor(
        private val engine: RegionEngine,
        private val key: TrackerKey,
        private val handler: RegionHandler,
        val tracker: RegionTracker,
    ) {
        fun cancel() = engine.detach(key, handler)
    }

    private class ScheduledRefresh(val dueTick: Long, val tracker: RegionTracker)

    private data class ChunkKey(val world: World, val x: Int, val z: Int)

    companion object {
        private const val QUERY_CACHE_MAX = 2048L
        private const val MAX_INDEXED_CHUNK_SPAN = 1024L
        private const val FAILURE_LOG_INTERVAL_TICKS = 100L
    }
}
