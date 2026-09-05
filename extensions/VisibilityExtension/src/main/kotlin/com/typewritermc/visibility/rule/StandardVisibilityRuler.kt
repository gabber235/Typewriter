package com.typewritermc.visibility.rule

import com.typewritermc.core.entries.Ref
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.visibility.entry.effect.VisibilityEffectEntry
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
    private var previousSelfTargets: Map<UUID, Int> = emptyMap()

    // Written by the tick coroutine and read on the server thread, where it feeds the hysteresis of
    // a viewer dependent selector.
    @Volatile
    private var previousTargetsByViewer: MutableMap<UUID, Set<UUID>> = Object2ObjectOpenHashMap()

    @Volatile
    private var captured = Snapshot(emptySet(), emptySet(), null, emptyMap())

    override fun captureServerState() {
        captured = resolveSnapshot()
    }

    override suspend fun tick() {
        val snapshot = captured

        if (snapshot.targetsByViewer == null) {
            applySeparable(snapshot.viewers, snapshot.targets)
        } else {
            applyViewerDependent(snapshot.targetsByViewer)
        }

        reconcileSelfPairs(snapshot.selfTargets)
    }

    private fun resolveSnapshot(): Snapshot {
        val currentViewers = viewers.resolve()
        if (!targets.viewerDependent) {
            val currentTargets = targets.resolve()
            return Snapshot(currentViewers, currentTargets, null, resolveSelfTargets(currentTargets))
        }

        val targetsByViewer = Object2ObjectOpenHashMap<UUID, Set<UUID>>(currentViewers.size)
        for (viewerId in currentViewers) {
            val viewer = server.getPlayer(viewerId) ?: continue
            targetsByViewer[viewerId] = targets.resolveFor(viewer, previousTargetsByViewer[viewerId] ?: emptySet())
        }

        val union = ObjectOpenHashSet<UUID>()
        targetsByViewer.values.forEach { union.addAll(it) }
        return Snapshot(currentViewers, emptySet(), targetsByViewer, resolveSelfTargets(union))
    }

    /**
     * The targets that also see this effect on themselves, each with the variant of the effect they
     * see, so a change in which parts of a bundle apply is noticed as well.
     *
     * Effects that cannot apply to self skip this entirely, and a toggle that cannot change is
     * settled once for every candidate. The rest is resolved once per candidate per tick on the
     * server thread, so it has to stay cheap: a toggle backed by an expensive variable pays that cost
     * for every player the target selector covers. The answer is not cached, because a cache delays
     * the toggle turning off for as long as it lives.
     */
    private fun resolveSelfTargets(candidates: Set<UUID>): Map<UUID, Int> {
        if (candidates.isEmpty()) return emptyMap()
        val entry = effect.get() ?: return emptyMap()
        if (!entry.supportsSelf) return emptyMap()
        when (entry.constantSelf()) {
            false -> return emptyMap()
            true -> return candidates.associateWith { CONSTANT_SELF_VARIANT }
            null -> {}
        }

        val selfTargets = HashMap<UUID, Int>()
        for (id in candidates) {
            val player = server.getPlayer(id) ?: continue
            val variant = entry.selfVariant(player)
            if (variant != 0) selfTargets[id] = variant
        }
        return selfTargets
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

    private suspend fun applyViewerDependent(currentTargetsByViewer: MutableMap<UUID, Set<UUID>>) {
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

    private suspend fun reconcileSelfPairs(currentSelfTargets: Map<UUID, Int>) {
        if (currentSelfTargets == previousSelfTargets) return

        for ((id, variant) in previousSelfTargets) {
            if (currentSelfTargets[id] == variant) continue
            // Gone, or a different set of the effect's parts applies now. A changed variant is
            // removed here and created again below, so the effector is built for the parts that apply.
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
        previousTargetsByViewer = Object2ObjectOpenHashMap()
        previousSelfTargets = emptyMap()
        captured = Snapshot(emptySet(), emptySet(), null, emptyMap())
    }

    private class Snapshot(
        val viewers: Set<UUID>,
        val targets: Set<UUID>,
        val targetsByViewer: MutableMap<UUID, Set<UUID>>?,
        val selfTargets: Map<UUID, Int>,
    )

    private companion object {
        /** The one variant a toggle that cannot change has. */
        const val CONSTANT_SELF_VARIANT = 1
    }
}
