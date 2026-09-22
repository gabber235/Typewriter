package com.typewritermc.visibility.rule

import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.visibility.entry.effect.SelfView
import com.typewritermc.visibility.entry.effect.VisibilityEffectEntry
import com.typewritermc.visibility.selector.TargetResolution
import com.typewritermc.visibility.selector.TargetSelector
import com.typewritermc.visibility.selector.ViewerSelector
import it.unimi.dsi.fastutil.objects.Object2ObjectOpenHashMap
import it.unimi.dsi.fastutil.objects.ObjectOpenHashSet
import java.util.UUID

/**
 * Ruler that keeps the rules for a viewer and target selector combination up to date.
 *
 * Every tick the selectors are resolved on the server thread into an immutable snapshot, which is
 * then diffed against the previous tick off the server thread, so only real membership changes reach
 * the engine. With static target selectors the viewer and target sets are diffed separately, which
 * keeps an unchanged tick at two set comparisons. Viewer dependent target selectors are resolved and
 * diffed once per viewer.
 */
class StandardVisibilityRuler(
    private val viewers: ViewerSelector,
    private val targets: TargetSelector,
    override val priority: Int,
    override val entryId: String,
    private val effect: Ref<VisibilityEffectEntry>,
) : VisibilityRuler() {

    private var previousViewers: Set<UUID> = emptySet()
    private var previousTargets: Set<UUID> = emptySet()
    private var previousSelfTargets: Map<UUID, Set<String>> = emptyMap()

    // Written by the tick coroutine and read on the server thread, where it feeds the hysteresis of
    // a viewer dependent selector.
    @Volatile
    private var previousTargetsByViewer: Map<UUID, Set<UUID>> = emptyMap()

    @Volatile
    private var captured: Snapshot = Snapshot.Empty

    override fun captureServerState() {
        captured = resolveSnapshot()
    }

    override suspend fun tick() {
        val snapshot = captured

        when (snapshot) {
            is Snapshot.Shared -> applySeparable(snapshot.viewers, snapshot.targets)
            is Snapshot.PerViewer -> applyViewerDependent(snapshot.targetsByViewer)
        }

        reconcileSelfPairs(snapshot.selfTargets)
    }

    private fun resolveSnapshot(): Snapshot {
        val currentViewers = viewers.resolve()
        return when (val resolution = targets.resolution) {
            is TargetResolution.Shared -> {
                val currentTargets = resolution.resolve()
                Snapshot.Shared(currentViewers, currentTargets, resolveSelfTargets(currentTargets))
            }

            is TargetResolution.PerViewer -> {
                val previous = previousTargetsByViewer
                val targetsByViewer = Object2ObjectOpenHashMap<UUID, Set<UUID>>(currentViewers.size)
                for (viewerId in currentViewers) {
                    val viewer = server.getPlayer(viewerId) ?: continue
                    targetsByViewer[viewerId] = resolution.resolveFor(viewer, previous[viewerId] ?: emptySet())
                }

                val union = ObjectOpenHashSet<UUID>()
                targetsByViewer.values.forEach { union.addAll(it) }
                Snapshot.PerViewer(targetsByViewer, resolveSelfTargets(union))
            }
        }
    }

    /**
     * The targets that also see this effect on themselves, each with the parts of the effect they
     * see, so a change in which parts of a bundle apply is noticed as well.
     *
     * A player dependent self view is resolved once per candidate per tick on the server thread, so
     * it has to stay cheap: a toggle backed by an expensive variable pays that cost for every player
     * the target selector covers. The answer is not cached, because a cache delays the toggle turning
     * off for as long as it lives.
     */
    private fun resolveSelfTargets(candidates: Set<UUID>): Map<UUID, Set<String>> {
        if (candidates.isEmpty()) return emptyMap()
        val entry = effect.get() ?: return emptyMap()
        return when (val view = entry.selfView) {
            SelfView.Never -> emptyMap()
            is SelfView.Always -> candidates.associateWith { view.parts }
            is SelfView.PerPlayer -> {
                val selfTargets = HashMap<UUID, Set<String>>()
                for (id in candidates) {
                    val player = server.getPlayer(id) ?: continue
                    val parts = view.partsFor(player)
                    if (parts.isNotEmpty()) selfTargets[id] = parts
                }
                selfTargets
            }
        }
    }

    private suspend fun applySeparable(currentViewers: Set<UUID>, currentTargets: Set<UUID>) {
        if (currentViewers == previousViewers && currentTargets == previousTargets) return

        val addedViewers = currentViewers - previousViewers
        val removedViewers = previousViewers - currentViewers
        val addedTargets = currentTargets - previousTargets
        val removedTargets = previousTargets - currentTargets

        for (viewer in removedViewers) {
            for (target in previousTargets) removePairRule(viewer, target)
        }
        for (target in removedTargets) {
            for (viewer in previousViewers) {
                if (viewer in removedViewers) continue
                removePairRule(viewer, target)
            }
        }

        for (viewer in addedViewers) {
            for (target in currentTargets) createRule(viewer, target)
        }
        for (viewer in currentViewers) {
            if (viewer in addedViewers) continue
            for (target in addedTargets) createRule(viewer, target)
        }

        previousViewers = currentViewers
        previousTargets = currentTargets
    }

    private suspend fun applyViewerDependent(currentTargetsByViewer: Map<UUID, Set<UUID>>) {
        for ((viewerId, previousTargets) in previousTargetsByViewer) {
            if (viewerId in currentTargetsByViewer) continue
            for (target in previousTargets) removePairRule(viewerId, target)
        }

        for ((viewerId, currentTargets) in currentTargetsByViewer) {
            val previousTargets = previousTargetsByViewer[viewerId] ?: emptySet()
            if (currentTargets == previousTargets) continue

            for (target in previousTargets) {
                if (target in currentTargets) continue
                removePairRule(viewerId, target)
            }
            for (target in currentTargets) {
                if (target in previousTargets) continue
                createRule(viewerId, target)
            }
        }

        previousTargetsByViewer = currentTargetsByViewer
    }

    private suspend fun createRule(viewer: UUID, target: UUID) {
        if (viewer == target) return
        if (hasRule(viewer, target)) return
        addRule(VisibilityRule(viewer, target, priority, effect, this, entryId))
    }

    /** Self pairs are owned by [reconcileSelfPairs] and never touched by membership changes. */
    private suspend fun removePairRule(viewer: UUID, target: UUID) {
        if (viewer == target) return
        removeRuleAt(viewer, target)
    }

    private suspend fun reconcileSelfPairs(currentSelfTargets: Map<UUID, Set<String>>) {
        if (currentSelfTargets == previousSelfTargets) return

        for ((id, parts) in previousSelfTargets) {
            if (currentSelfTargets[id] == parts) continue
            // Gone, or a different set of the effect's parts applies now. A changed set is removed
            // here and created again below, so the effector is built for the parts that apply.
            removeRuleAt(id, id)
        }
        for (id in currentSelfTargets.keys) {
            if (hasRule(id, id)) continue
            addRule(VisibilityRule(id, id, priority, effect, this, entryId))
        }

        previousSelfTargets = currentSelfTargets
    }

    /** Drops the diff state along with the rules, so a ruler that ticks again rebuilds from scratch. */
    override suspend fun dispose() {
        super.dispose()
        previousViewers = emptySet()
        previousTargets = emptySet()
        previousTargetsByViewer = emptyMap()
        previousSelfTargets = emptyMap()
        captured = Snapshot.Empty
    }

    /** What the server thread resolved for one tick, handed to [tick] and never changed afterwards. */
    private sealed interface Snapshot {
        val selfTargets: Map<UUID, Set<String>>

        class Shared(
            val viewers: Set<UUID>,
            val targets: Set<UUID>,
            override val selfTargets: Map<UUID, Set<String>>,
        ) : Snapshot

        class PerViewer(
            val targetsByViewer: Map<UUID, Set<UUID>>,
            override val selfTargets: Map<UUID, Set<String>>,
        ) : Snapshot

        companion object {
            val Empty: Snapshot = Shared(emptySet(), emptySet(), emptyMap())
        }
    }
}
