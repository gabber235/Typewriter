package com.typewritermc.region.flag

import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.priority
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.region.RegionEngine
import com.typewritermc.region.data.RegionDefinitionEntry
import com.typewritermc.region.data.buildShapeOrNull
import com.typewritermc.region.data.hasConstPlacement
import com.typewritermc.region.entries.modifier.AllowanceModifierEntry
import com.typewritermc.region.entries.modifier.BlockBreakModifierEntry
import com.typewritermc.region.entries.modifier.BlockBreakModifierHandler
import com.typewritermc.region.entries.modifier.BlockInteractModifierEntry
import com.typewritermc.region.entries.modifier.BlockInteractModifierHandler
import com.typewritermc.region.entries.modifier.BlockPlaceModifierEntry
import com.typewritermc.region.entries.modifier.BlockPlaceModifierHandler
import com.typewritermc.region.entries.modifier.BucketModifierEntry
import com.typewritermc.region.entries.modifier.BucketModifierHandler
import com.typewritermc.region.entries.modifier.CombatModifierHandler
import com.typewritermc.region.entries.modifier.EntityDamageModifierEntry
import com.typewritermc.region.entries.modifier.EntityDamageModifierHandler
import com.typewritermc.region.entries.modifier.EntityInteractModifierEntry
import com.typewritermc.region.entries.modifier.EntityInteractModifierHandler
import com.typewritermc.region.entries.modifier.ExplosionModifierEntry
import com.typewritermc.region.entries.modifier.ExplosionModifierHandler
import com.typewritermc.region.entries.modifier.FireSpreadModifierEntry
import com.typewritermc.region.entries.modifier.FireSpreadModifierHandler
import com.typewritermc.region.entries.modifier.FluidFlowModifierEntry
import com.typewritermc.region.entries.modifier.FluidFlowModifierHandler
import com.typewritermc.region.entries.modifier.IgniteModifierEntry
import com.typewritermc.region.entries.modifier.IgniteModifierHandler
import com.typewritermc.region.entries.modifier.MobDamageModifierEntry
import com.typewritermc.region.entries.modifier.MobGriefModifierEntry
import com.typewritermc.region.entries.modifier.MobGriefModifierHandler
import com.typewritermc.region.entries.modifier.MobSpawnModifierEntry
import com.typewritermc.region.entries.modifier.MobSpawnModifierHandler
import com.typewritermc.region.entries.modifier.PistonModifierEntry
import com.typewritermc.region.entries.modifier.PistonModifierHandler
import com.typewritermc.region.entries.modifier.PlayerDamageModifierEntry
import com.typewritermc.region.entries.modifier.PvpModifierEntry
import com.typewritermc.region.entries.modifier.RedstoneModifierEntry
import com.typewritermc.region.entries.modifier.RedstoneModifierHandler
import com.typewritermc.region.entries.modifier.RegionModifierEntry
import com.typewritermc.region.entries.modifier.TrampleModifierEntry
import com.typewritermc.region.entries.modifier.TrampleModifierHandler
import com.typewritermc.region.tracker.RegionTracker
import org.bukkit.event.HandlerList
import org.bukkit.event.Listener
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import kotlin.reflect.KClass

/**
 * Owns the region flags: which regions carry which rules, and the one handler per rule that
 * enforces them.
 *
 * Exactly one handler is created per flag type that is actually used, however many regions use it,
 * and none at all for a type nobody uses. An unused redstone flag therefore costs nothing on a
 * redstone tick: its listener is never registered.
 */
@Singleton
class RegionFlagManager : Initializable, KoinComponent {
    private val engine: RegionEngine by inject()

    @Volatile
    var index: RegionFlagIndex? = null
        private set

    private val handlers = mutableListOf<Listener>()

    override suspend fun initialize() {
        val regions = buildFlaggedRegions(Query.find<RegionDefinitionEntry>().toList())
        val flagIndex = RegionFlagIndex(regions, engine)
        index = flagIndex

        for ((name, flag) in viewerlessFlagsOnDynamicRegions(regions, VIEWERLESS_FLAGS)) {
            logger.warning(
                "Region '$name' carries the flag '$flag', but its placement is bound to a variable. " +
                        "That flag decides about events with no player behind them, which cannot resolve a " +
                        "per viewer region, so it will never apply. Give the region a constant placement, or " +
                        "remove the flag."
            )
        }

        for ((name, flag) in viewerlessFlagsOnDynamicRegions(regions, PARTLY_VIEWERLESS_FLAGS)) {
            logger.warning(
                "Region '$name' carries the flag '$flag', but its placement is bound to a variable. " +
                        "That flag usually decides about events with a player behind them, but not always. " +
                        "On a per viewer region it applies only when a player is behind the event, and never " +
                        "otherwise, because the region cannot resolve without one. Give the region a constant " +
                        "placement to cover every case, or accept the gap."
            )
        }

        for ((name, flag) in variableAllowancesOnViewerlessFlags(regions)) {
            logger.warning(
                "Region '$name' carries the flag '$flag' with its allowance bound to a variable. " +
                        "A variable needs a player to resolve, and events like a crop growing or sand " +
                        "coming to rest have none, so the flag abstains for those and whatever region " +
                        "sits below it decides instead. Give the allowance a constant value to cover " +
                        "every case, or accept the gap."
            )
        }

        val used = regions.flatMap { it.modifiers.keys }.toSet()
        for (factory in used.mapNotNull { handlerFactories[it] }.distinct()) {
            val handler = factory(flagIndex)
            server.pluginManager.registerEvents(handler, plugin)
            handlers += handler
        }
    }

    override suspend fun shutdown() {
        handlers.forEach { HandlerList.unregisterAll(it) }
        handlers.clear()
        index = null
    }
}

/**
 * The regions that carry at least one flag, ordered by entry id.
 *
 * The order breaks ties between regions of equal priority, so it has to be the same on every
 * server and across every restart. Load order is not: pages are read in the order the filesystem
 * lists them, which is unspecified and shifts as pages are added. Sorting by id makes the winner
 * of a tie arbitrary but fixed, rather than something that can flip on a restart and quietly
 * reverse whether a region allows building.
 *
 * A constant placement region is resolved into a tracker right away, which gives the transform, the
 * shape and the containment test without registering anything with the engine. A variable placement
 * region cannot be resolved without a viewer, so it gets no tracker and no AABB and is resolved per
 * player at lookup time.
 */
internal fun buildFlaggedRegions(entries: List<RegionDefinitionEntry>): List<FlaggedRegion> =
    entries.sortedBy { it.id }.mapIndexedNotNull { order, entry ->
        val resolved = entry.modifiers.mapNotNull { it.get() }
        // A flag reference that no longer resolves means the entry was deleted on the web, and
        // dropping it in silence unprotects the region without saying so anywhere. Said before the
        // guards below, because deleting the last flag a region carried is exactly the case they
        // drop, and the case a builder most needs to hear about.
        val missing = entry.modifiers.size - resolved.size
        if (missing > 0) {
            logger.warning(
                "Region '${entry.name}' points at $missing flag entr${if (missing == 1) "y" else "ies"} " +
                        "that no longer exist. Whatever they protected is not protected any more."
            )
        }
        val modifiers = resolved.associateBy { it::class }
        if (modifiers.isEmpty()) return@mapIndexedNotNull null
        if (entry.buildShapeOrNull() == null) return@mapIndexedNotNull null

        // Two flags of the same type on one region cannot both decide, and the winner is
        // whichever the builder happened to list last. Saying so beats a region that quietly
        // ignores half of what the panel shows on it. Only worth saying for a region that
        // enforces anything at all, which is why it sits below the guards.
        for (duplicate in resolved.groupBy { it::class }.values.filter { it.size > 1 }) {
            logger.warning(
                "Region '${entry.name}' carries ${duplicate.size} flags of the same kind. " +
                        "Only '${duplicate.last().name}' decides."
            )
        }

        val tracker = if (entry.hasConstPlacement) RegionTracker(null, entry).also { it.refresh() } else null
        FlaggedRegion(
            entry = entry,
            priority = entry.ref().priority,
            order = order,
            modifiers = modifiers,
            tracker = tracker,
            aabb = tracker?.cachedAabb,
        )
    }

/**
 * The (region name, flag name) pairs where a flag that decides about viewerless events sits on a
 * region that only exists per viewer. Such a flag can never apply, and it is reported so the
 * region does not fail in silence.
 */
internal fun viewerlessFlagsOnDynamicRegions(
    regions: List<FlaggedRegion>,
    viewerless: Set<KClass<out RegionModifierEntry>>,
): List<Pair<String, String>> = regions
    .filter { it.tracker == null }
    .flatMap { region ->
        region.modifiers
            .filterKeys { it in viewerless }
            .map { (_, flag) -> region.entry.name to flag.name }
    }

/**
 * The flags that decide about events with no player behind them and whose allowance cannot resolve
 * without one, with the region carrying them.
 *
 * Elsewhere a player is always there to resolve the variable, so only the partly viewerless flags
 * are listed.
 */
internal fun variableAllowancesOnViewerlessFlags(regions: List<FlaggedRegion>): List<Pair<String, String>> =
    regions.flatMap { region ->
        region.modifiers
            .filterKeys { it in PARTLY_VIEWERLESS_FLAGS }
            .values
            .filterIsInstance<AllowanceModifierEntry>()
            .filter { it.allowed.get(null) == null }
            .map { region.entry.name to it.name }
    }

/** The flags whose events have no player behind them, so they cannot resolve a per viewer region. */
internal val VIEWERLESS_FLAGS: Set<KClass<out RegionModifierEntry>> = setOf(
    PistonModifierEntry::class,
    RedstoneModifierEntry::class,
    FireSpreadModifierEntry::class,
    FluidFlowModifierEntry::class,
    ExplosionModifierEntry::class,
    MobSpawnModifierEntry::class,
    MobGriefModifierEntry::class,
)

/**
 * The flags whose events usually have a player behind them, but sometimes do not: a zombie or an
 * explosion can trigger the same event as a punch. On a per viewer region, such a flag applies
 * only to the occurrences that do have a player behind them, and silently does not to the rest,
 * since the region cannot resolve without one.
 */
internal val PARTLY_VIEWERLESS_FLAGS: Set<KClass<out RegionModifierEntry>> = setOf(
    EntityDamageModifierEntry::class,
    BucketModifierEntry::class,
    IgniteModifierEntry::class,
    BlockPlaceModifierEntry::class,
    BlockBreakModifierEntry::class,
    BlockInteractModifierEntry::class,
    TrampleModifierEntry::class,
)

/** The three flags about a player being hurt share one handler, which weighs them against each other. */
private val combatHandler: (RegionFlagIndex) -> Listener = { index -> CombatModifierHandler(index) }

/**
 * The handler for each flag type. Only the types a region actually uses are ever registered, and
 * a handler shared by several types is registered once.
 */
internal val handlerFactories: Map<KClass<out RegionModifierEntry>, (RegionFlagIndex) -> Listener> = mapOf(
    BlockBreakModifierEntry::class to { index -> BlockBreakModifierHandler(index) },
    BlockPlaceModifierEntry::class to { index -> BlockPlaceModifierHandler(index) },
    BlockInteractModifierEntry::class to { index -> BlockInteractModifierHandler(index) },
    EntityInteractModifierEntry::class to { index -> EntityInteractModifierHandler(index) },
    PistonModifierEntry::class to { index -> PistonModifierHandler(index) },
    RedstoneModifierEntry::class to { index -> RedstoneModifierHandler(index) },
    FireSpreadModifierEntry::class to { index -> FireSpreadModifierHandler(index) },
    FluidFlowModifierEntry::class to { index -> FluidFlowModifierHandler(index) },
    ExplosionModifierEntry::class to { index -> ExplosionModifierHandler(index) },
    MobSpawnModifierEntry::class to { index -> MobSpawnModifierHandler(index) },
    MobGriefModifierEntry::class to { index -> MobGriefModifierHandler(index) },
    PvpModifierEntry::class to combatHandler,
    MobDamageModifierEntry::class to combatHandler,
    PlayerDamageModifierEntry::class to combatHandler,
    BucketModifierEntry::class to { index -> BucketModifierHandler(index) },
    EntityDamageModifierEntry::class to { index -> EntityDamageModifierHandler(index) },
    TrampleModifierEntry::class to { index -> TrampleModifierHandler(index) },
    IgniteModifierEntry::class to { index -> IgniteModifierHandler(index) },
)
