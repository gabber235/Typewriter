package com.typewritermc.visibility

import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.interaction.context
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.entry.entries.ReadableFactEntry
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.engine.paper.facts.RefreshFactTrigger
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.TICK_MS
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.visibility.effector.TickableVisibilityEffector
import com.typewritermc.visibility.effector.VisibilityEffector
import com.typewritermc.visibility.entry.rule.VisibilityRuleProvider
import com.typewritermc.visibility.fact.VisibilityTargetsCountFact
import com.typewritermc.visibility.fact.VisibilityViewersCountFact
import com.typewritermc.visibility.packet.VisibilityTeamManager
import com.typewritermc.visibility.packet.refreshRendering
import com.typewritermc.visibility.rule.PlayerPair
import com.typewritermc.visibility.rule.VisibilityRule
import com.typewritermc.visibility.rule.VisibilityRuler
import it.unimi.dsi.fastutil.objects.ObjectOpenHashSet
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CoroutineStart
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.delay
import kotlinx.coroutines.isActive
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlinx.coroutines.withContext
import kotlinx.coroutines.withTimeoutOrNull
import kotlinx.coroutines.yield
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import org.koin.core.qualifier.named
import java.util.UUID
import java.util.concurrent.ConcurrentHashMap
import java.util.concurrent.CopyOnWriteArrayList
import java.util.concurrent.atomic.AtomicBoolean
import java.util.logging.Logger
import kotlin.time.Duration
import kotlin.time.Duration.Companion.milliseconds
import kotlin.time.Duration.Companion.seconds
import kotlin.time.measureTime

/**
 * Central arbiter of the visibility system.
 *
 * The engine ticks all rulers, conducts the priority contest that decides the single active
 * effect per viewer and target pair, and manages effector lifecycles. Rule mutations are
 * serialized through a mutex, while rule counts are readable lock free from any thread.
 *
 * Effector initialization and disposal run on a per pair job chain, so for any pair the
 * lifecycle calls of consecutive effects never overlap or reorder.
 */
@Singleton
class VisibilityEngine : Initializable, KoinComponent {
    private val logger: Logger by inject()
    private val teamManager: VisibilityTeamManager by inject()
    private val effectsByViewer = ConcurrentHashMap<UUID, ConcurrentHashMap<UUID, ActiveEffect>>()
    private val effectsByTarget = ConcurrentHashMap<UUID, ConcurrentHashMap<UUID, ActiveEffect>>()
    private val lifecycleChains = ConcurrentHashMap<PlayerPair, Job>()
    private val tickingEffectors = CopyOnWriteArrayList<TickableVisibilityEffector>()
    private val mutex = Mutex()

    // Both are replaced on the thread a reload runs on and read from the pool threads that run the
    // lifecycle chains, so neither can be a plain field.
    @Volatile
    private var scope = newEngineScope()

    @Volatile
    private var tickJob: Job? = null

    // Replaced wholesale rather than mutated, since lifecycle chains read it from their own threads
    // while the tick coroutine iterates it.
    @Volatile
    private var rulers: List<VisibilityRuler> = emptyList()

    @Volatile
    private var shuttingDown = false

    private var targetsCountFacts = emptyList<VisibilityTargetsCountFact>()
    private var viewersCountFacts = emptyList<VisibilityViewersCountFact>()
    private val dirtyViewers = ConcurrentHashMap.newKeySet<UUID>()
    private val dirtyTargets = ConcurrentHashMap.newKeySet<UUID>()

    override suspend fun initialize() {
        if (!scope.isActive) scope = newEngineScope()
        shuttingDown = false

        targetsCountFacts = Query.find<VisibilityTargetsCountFact>().toList()
        viewersCountFacts = Query.find<VisibilityViewersCountFact>().toList()

        val providers = Query.find<VisibilityRuleProvider>().toList()
        if (providers.isEmpty()) return

        providers.forEach { provider ->
            try {
                registerRuler(provider.createRuler())
            } catch (e: Exception) {
                logger.severe("Failed to create visibility ruler from entry '${provider.id}': ${e.message}")
                e.printStackTrace()
            }
        }

        tickJob = scope.launch { runTickLoop() }
    }

    /**
     * Registers a ruler with the engine.
     * Rulers are kept sorted by priority so replacement lookups return the highest priority rule.
     */
    internal fun registerRuler(ruler: VisibilityRuler) {
        rulers = (rulers + ruler).sortedByDescending { it.priority }
    }

    override suspend fun shutdown() {
        shuttingDown = true

        // A tick suspended in a hop to the server thread only resumes once that thread runs tasks
        // again, which during a server stop never happens. An unbounded wait would hang the shutdown.
        tickJob?.cancel()
        withTimeoutOrNull(1.seconds) { tickJob?.join() }
        tickJob = null

        // The active effects are collected before the rulers are disposed. Disposing a ruler retracts every rule
        // it owns, and a retraction removes the pair from the indexes itself while scheduling the
        // teardown. Collecting afterwards would always find nothing.
        val remaining = mutex.withLock {
            val active = effectsByViewer.values.flatMap { it.values }
            effectsByViewer.clear()
            effectsByTarget.clear()
            active
        }

        rulers.forEach { ruler ->
            try {
                ruler.dispose()
            } catch (e: CancellationException) {
                throw e
            } catch (e: Exception) {
                logger.severe("Failed to dispose visibility ruler ${ruler::class.simpleName}: ${e.message}")
                e.printStackTrace()
            }
        }
        rulers = emptyList()

        if (isPluginEnabled()) {
            // Under the mutex like every other scheduling site. A tick that outlived the bounded
            // join above still calls addRule, and two unsynchronized schedules for one pair read the
            // same predecessor, which lets an old dispose overlap a new initialize.
            mutex.withLock {
                remaining.forEach { effect -> scheduleLifecycle(effect.rule.pair, effect, next = null) }
            }
            awaitLifecycles()
            // Every rule just disappeared, so the count facts of everyone involved are stale. They
            // are deliberately not refreshed here: player sessions are torn down before the
            // extensions are, so a refresh would have no session to write to. The facts are read
            // again once the reload finishes.
        } else {
            // Bukkit clears the plugin's enabled flag before disabling the plugin, and from that
            // moment mccoroutine's dispatcher no longer schedules onto the server thread. A lifecycle
            // chain runs on the pool, so its hop back would execute inline on a pool thread, and
            // cancelling the scope below would cut most of them short before that. The effectors are
            // therefore disposed here, on the thread the disable itself runs on.
            scope.cancel()
            remaining.forEach { effect -> disposeEffect(effect.rule.pair, effect) }
        }

        tickingEffectors.clear()
        dirtyViewers.clear()
        dirtyTargets.clear()
        scope.cancel()
    }

    /**
     * Offers a rule to the priority contest for its pair.
     *
     * With no active effect the rule always wins. An active effect with a strictly higher
     * priority shadows the rule. Otherwise the active effect is disposed and this rule's
     * effect takes over, on equal priority the last added rule wins.
     */
    suspend fun addRule(rule: VisibilityRule) = mutex.withLock {
        val current = effectsByViewer[rule.viewer]?.get(rule.target)
        if (current != null) {
            if (current.rule == rule) return@withLock
            if (current.rule.priority > rule.priority) return@withLock
            if (current.rule.priority == rule.priority && current.rule.ruler !== rule.ruler) {
                logger.warning(
                    "Visibility priority conflict for pair (${rule.viewer}, ${rule.target}): " +
                            "rule from entry '${rule.entryId}' replaces rule from entry " +
                            "'${current.rule.entryId}' with the same priority ${rule.priority}"
                )
            }
        }
        swapEffect(rule.pair, current, rule)
    }

    /**
     * Retracts a rule from its pair.
     *
     * Only the ruler that owns the active effect can retract it, retracting a shadowed rule is a
     * no op. When the active effect is removed, the highest priority rule still applied by any
     * ruler for the pair takes over.
     */
    suspend fun removeRule(rule: VisibilityRule) = mutex.withLock {
        val current = effectsByViewer[rule.viewer]?.get(rule.target) ?: return@withLock
        if (current.rule.ruler !== rule.ruler) return@withLock

        val replacement = if (shuttingDown) null else findReplacementRule(rule.viewer, rule.target)
        swapEffect(rule.pair, current, replacement)
    }

    /**
     * Number of other players this viewer has an active visibility rule for.
     * Readable lock free from any thread, facts poll this directly. A self effect is excluded: it
     * describes how the player sees themselves, not how many players they see differently.
     */
    fun viewerRuleCount(viewer: UUID, ruleEntryId: String? = null): Int =
        countPairs(effectsByViewer[viewer], viewer, ruleEntryId)

    /**
     * Number of other players that have an active visibility rule for this target.
     * Readable lock free from any thread, facts poll this directly. A self effect is excluded, so a
     * target nobody else sees differently reads zero even while they see themselves changed.
     */
    fun targetRuleCount(target: UUID, ruleEntryId: String? = null): Int =
        countPairs(effectsByTarget[target], target, ruleEntryId)

    private fun countPairs(
        pairs: ConcurrentHashMap<UUID, ActiveEffect>?,
        self: UUID,
        ruleEntryId: String?,
    ): Int {
        if (pairs == null) return 0
        return pairs.count { (other, effect) ->
            other != self && (ruleEntryId == null || effect.rule.entryId == ruleEntryId)
        }
    }

    internal fun activeRuleFor(viewer: UUID, target: UUID): VisibilityRule? =
        effectsByViewer[viewer]?.get(target)?.rule

    internal fun activeEffectorFor(viewer: UUID, target: UUID): VisibilityEffector? =
        effectsByViewer[viewer]?.get(target)?.effector

    /**
     * Waits until all currently scheduled effector lifecycle work has finished.
     */
    internal suspend fun awaitLifecycles() {
        withTimeoutOrNull(10.seconds) {
            while (lifecycleChains.isNotEmpty()) {
                for (chain in lifecycleChains.values) {
                    chain.join()
                }
                // Joining a finished chain does not suspend, so without this the loop can spin
                // between a chain completing and its handler removing it from the map, leaving the
                // surrounding timeout no chance to fire.
                yield()
            }
        } ?: logger.warning("Visibility effector lifecycles did not settle in time")
    }

    private suspend fun runTickLoop() {
        while (currentCoroutineContext().isActive) {
            var queued = Duration.ZERO
            val time = measureTime {
                // An exception escaping here cancels the tick job for the rest of the session, and
                // the whole system silently stops updating.
                try {
                    var worked = Duration.ZERO
                    val hop = measureTime { worked = runServerThreadWork() }
                    queued = hop - worked
                    tickRulers()
                } catch (e: CancellationException) {
                    throw e
                } catch (e: Exception) {
                    logger.severe("Visibility tick failed: ${e.message}")
                    e.printStackTrace()
                }
            }

            val wait = TICK_MS - time.inWholeMilliseconds - AVERAGE_SCHEDULING_DELAY_MS
            if (wait > 0) delay(wait.milliseconds)

            // Only the queueing delay is subtracted. Waiting for a lagging server to pick the hop up
            // is not this system's cost, but what the hop then runs is, and that is where the
            // effectors tick, so excluding it would hide the most expensive part of a tick.
            val own = time - queued
            if (own.inWholeMilliseconds > TICK_MS + SLOW_TICK_GRACE_MS) {
                logger.warning("Visibility ticks took too long: ${own.inWholeMilliseconds}ms")
            }
        }
    }

    private suspend fun tickRulers() {
        rulers.forEach { ruler ->
            guarded({ "tick visibility ruler of entry '${ruler.entryId}'" }) { ruler.tick() }
        }
    }

    /**
     * Everything a tick has to do on the server thread, batched into a single hop.
     *
     * Rulers read live Bukkit collections, ticking effectors read the state of the players they
     * render, count fact refreshes go through player sessions, and the team manager reads the real
     * scoreboard. A separate hop for each would cost a scheduler round trip each, which on a busy
     * server drops rule updates well below one per tick.
     *
     * @return how long the batch itself occupied the server thread, which is the part of the hop
     * this loop is accountable for.
     */
    private suspend fun runServerThreadWork(): Duration {
        if (rulers.isEmpty() && tickingEffectors.isEmpty() &&
            dirtyViewers.isEmpty() && dirtyTargets.isEmpty() && !teamManager.hasPendingWork()
        ) return Duration.ZERO

        var worked = Duration.ZERO
        Dispatchers.Sync.switchContext {
            worked = measureTime {
                guarded({ "refresh visibility count facts" }) { flushDirtyFacts() }
                guarded({ "send client side teams" }) { teamManager.flush() }

                rulers.forEach { ruler ->
                    guarded({ "resolve visibility selectors for entry '${ruler.entryId}'" }) {
                        ruler.captureServerState()
                    }
                }
                tickingEffectors.forEach { effector ->
                    guarded({ "tick visibility effector ${effector::class.simpleName}" }) { effector.tick() }
                }
            }
        }
        return worked
    }

    // The label is built only on failure. A string per effector per tick is allocation the hot path
    // never needs.
    private suspend fun guarded(what: () -> String, block: suspend () -> Unit) {
        try {
            block()
        } catch (e: CancellationException) {
            throw e
        } catch (e: Exception) {
            logger.severe("Failed to ${what()}: ${e.message}")
            e.printStackTrace()
        }
    }

    private fun findReplacementRule(
        viewer: UUID,
        target: UUID,
        exclude: Set<VisibilityRule> = emptySet(),
    ): VisibilityRule? {
        for (ruler in rulers) {
            val rule = ruler.visibilityRuleFor(viewer, target) ?: continue
            if (rule in exclude) continue
            return rule
        }
        return null
    }

    /**
     * Builds the effect of the winning rule, falling back to the rules it shadows when it cannot
     * produce one. Without the fallback a rule with a broken effect reference would leave the pair
     * without an effect for as long as it wins the contest.
     */
    private fun createFirstWorkingEffect(
        pair: PlayerPair,
        rule: VisibilityRule?,
        exhausted: Set<VisibilityRule>,
    ): ActiveEffect? {
        var candidate = rule ?: return null
        val failed = ObjectOpenHashSet(exhausted)
        while (true) {
            createEffect(candidate, failed)?.let { return it }
            if (shuttingDown) return null
            failed.add(candidate)
            candidate = findReplacementRule(pair.viewer, pair.target, failed) ?: return null
        }
    }

    private fun swapEffect(
        pair: PlayerPair,
        previous: ActiveEffect?,
        rule: VisibilityRule?,
        exhausted: Set<VisibilityRule> = emptySet(),
    ) {
        val next = createFirstWorkingEffect(pair, rule, exhausted)

        if (next != null) {
            effectsByViewer.computeIfAbsent(pair.viewer) { ConcurrentHashMap() }[pair.target] = next
            effectsByTarget.computeIfAbsent(pair.target) { ConcurrentHashMap() }[pair.viewer] = next
        } else if (previous != null) {
            removeFromIndexes(pair)
        }

        if (previous == null && next == null) return
        scheduleLifecycle(pair, previous, next)
        markFactsDirty(pair)
    }

    private fun createEffect(rule: VisibilityRule, exhausted: Set<VisibilityRule>): ActiveEffect? {
        val effectEntry = rule.effect.get()
        if (effectEntry == null) {
            logger.warning("Could not find visibility effect entry '${rule.effect.id}' referenced by entry '${rule.entryId}'")
            return null
        }

        return try {
            ActiveEffect(rule, effectEntry.createEffector(rule), exhausted)
        } catch (e: Exception) {
            logger.severe("Failed to create visibility effector from entry '${effectEntry.id}': ${e.message}")
            e.printStackTrace()
            null
        }
    }

    private fun removeFromIndexes(pair: PlayerPair) {
        effectsByViewer.computeIfPresent(pair.viewer) { _, row ->
            row.remove(pair.target)
            if (row.isEmpty()) null else row
        }
        effectsByTarget.computeIfPresent(pair.target) { _, column ->
            column.remove(pair.viewer)
            if (column.isEmpty()) null else column
        }
    }

    private fun scheduleLifecycle(pair: PlayerPair, previous: ActiveEffect?, next: ActiveEffect?) {
        val previousChain = lifecycleChains[pair]
        val chain = scope.launch(start = CoroutineStart.LAZY) {
            previousChain?.join()

            // One re render for the whole transition, not one per effector. A re render is a despawn
            // followed by a respawn, so a bundle whose effects each need one would flicker the target
            // once per sub effect and leave it partly disguised in between. Doing it here also
            // guarantees every hook is registered before the client re reads the target.
            try {
                previous?.let { disposeEffect(pair, it) }
                next?.let { initializeEffect(pair, it) }
            } finally {
                // Read from the effectors rather than from the calls above, and in a finally, because
                // a cancellation between the two still leaves the client with a profile nothing
                // registers any more. Both effectors report true once they have hooked, disposal
                // included, which is what makes reading them here sufficient.
                if (previous.needsPairRerender() || next.needsPairRerender()) {
                    withContext(NonCancellable) { pair.refreshRendering() }
                }
            }
        }
        lifecycleChains[pair] = chain
        chain.invokeOnCompletion { lifecycleChains.remove(pair, chain) }
        chain.start()
    }

    private suspend fun disposeEffect(pair: PlayerPair, effect: ActiveEffect) {
        // A rule change arriving while a failed initialize is already tearing its effector down still
        // sees that effector as the active one, and a shutdown disposes whatever the chains did not
        // reach. The claim keeps an effector from being disposed twice.
        if (!effect.claimDisposal()) return
        if (effect.effector is TickableVisibilityEffector) tickingEffectors.remove(effect.effector)

        // Releasing packets, hooks, hides and spawned entities has to complete even when the caller
        // was cancelled. Every effector hops to the server thread for it, a cancelled coroutine
        // cannot suspend, and the claim above means nothing would retry.
        withContext(NonCancellable) {
            try {
                effect.effector.dispose()
            } catch (e: Exception) {
                logger.severe("Failed to dispose visibility effector for pair (${pair.viewer}, ${pair.target}): ${e.message}")
                e.printStackTrace()
            }
        }
    }

    private suspend fun initializeEffect(pair: PlayerPair, effect: ActiveEffect) {
        try {
            effect.effector.initialize()
            if (effect.effector is TickableVisibilityEffector) tickingEffectors.add(effect.effector)
            return
        } catch (e: CancellationException) {
            // Whatever it registered before the cancellation arrived is still registered.
            disposeEffect(pair, effect)
            throw e
        } catch (e: Exception) {
            logger.severe(
                "Failed to initialize visibility effector of entry '${effect.rule.entryId}' for pair " +
                        "(${pair.viewer}, ${pair.target}): ${e.message}. This rule will not be tried " +
                        "again for this pair until the pair leaves its selection, so that two failing " +
                        "rules cannot keep electing each other."
            )
            e.printStackTrace()
        }

        // An effector that threw partway through still holds whatever it registered, and only its own
        // dispose can release that.
        disposeEffect(pair, effect)

        mutex.withLock {
            if (effectsByViewer[pair.viewer]?.get(pair.target) !== effect) return@withLock
            removeFromIndexes(pair)
            markFactsDirty(pair)

            // The failing rule keeps shadowing every lower priority rule for this pair unless the
            // contest runs again without it. Rules that failed earlier stay excluded too, otherwise
            // two broken rules elect each other indefinitely.
            val exhausted = effect.exhaustedRules + effect.rule
            val replacement = if (shuttingDown) null else findReplacementRule(pair.viewer, pair.target, exhausted)
            if (replacement != null) swapEffect(pair, previous = null, rule = replacement, exhausted = exhausted)
        }
    }

    /** Whether an effect, which may be absent, requires the pair to be re rendered. */
    private fun ActiveEffect?.needsPairRerender(): Boolean = this?.effector?.needsPairRerender == true

    private fun markFactsDirty(pair: PlayerPair) {
        if (targetsCountFacts.isNotEmpty()) dirtyViewers.add(pair.viewer)
        if (viewersCountFacts.isNotEmpty()) dirtyTargets.add(pair.target)
    }

    /**
     * Refreshes the count facts of every player whose rules changed during the tick.
     * Batching per tick stops a selection change touching many pairs from triggering the same fact
     * refresh repeatedly.
     */
    private fun flushDirtyFacts() {
        drain(dirtyViewers).forEach { viewerId ->
            val viewer = server.getPlayer(viewerId) ?: return@forEach
            targetsCountFacts.forEach { fact -> refresh(fact, viewer) }
        }
        drain(dirtyTargets).forEach { targetId ->
            val target = server.getPlayer(targetId) ?: return@forEach
            viewersCountFacts.forEach { fact -> refresh(fact, target) }
        }
    }

    /**
     * The batch is already drained by the time the first refresh runs, so a refresh that throws would
     * skip every player still queued behind it, and nothing marks them dirty again.
     */
    private fun refresh(fact: ReadableFactEntry, player: Player) {
        try {
            RefreshFactTrigger(fact.readableRef()).triggerFor(player, context())
        } catch (e: Exception) {
            logger.severe("Failed to refresh visibility count fact '${fact.id}' for ${player.name}: ${e.message}")
            e.printStackTrace()
        }
    }

    private fun drain(ids: MutableSet<UUID>): List<UUID> {
        if (ids.isEmpty()) return emptyList()
        val drained = ArrayList<UUID>(ids.size)
        val iterator = ids.iterator()
        while (iterator.hasNext()) {
            drained.add(iterator.next())
            iterator.remove()
        }
        return drained
    }

    private fun isPluginEnabled(): Boolean = getKoin().get<Boolean>(named("isEnabled"))

    private fun ReadableFactEntry.readableRef() = Ref(id, ReadableFactEntry::class, this)

    private fun newEngineScope() = CoroutineScope(SupervisorJob() + Dispatchers.UntickedAsync)

    /**
     * @property exhaustedRules the rules that already failed to produce a working effect for this
     * pair. Carried along so a rule that fails to initialize can rerun the contest without the rules
     * that came before it, which stops two broken rules from electing each other indefinitely.
     */
    private class ActiveEffect(
        val rule: VisibilityRule,
        val effector: VisibilityEffector,
        val exhaustedRules: Set<VisibilityRule> = emptySet(),
    ) {
        private val disposed = AtomicBoolean(false)

        /** True for exactly one caller, which is the one that disposes this effector. */
        fun claimDisposal(): Boolean = disposed.compareAndSet(false, true)
    }

    private companion object {
        const val AVERAGE_SCHEDULING_DELAY_MS = 5L
        const val SLOW_TICK_GRACE_MS = 100L
    }
}
