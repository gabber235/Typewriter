package com.typewritermc.region.entries.display

import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.TickableDisplay
import com.typewritermc.region.RegionEngine
import com.typewritermc.region.content.RegionEditRegistry
import com.typewritermc.region.data.RegionData
import com.typewritermc.region.data.ResolvedTransform
import com.typewritermc.region.handler.LazyInsideQueryHandler
import com.typewritermc.region.tracker.RegionTracker
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent
import java.util.*
import java.util.concurrent.ConcurrentHashMap

/**
 * Shared base for the region boundary [AudienceDisplay]s. Each audience player holds an
 * observation on the region's tracker, so [tick] reads the tracker's cached transform
 * instead of resolving again variables per player per tick. The engine keeps the cached
 * transform fresh for dynamic regions.
 *
 * While a player edits the region in a content mode, the display is suppressed for them
 * and its artifacts are cleaned up, so the editor's preview is the only boundary they see.
 * Rendering resumes when the editor closes.
 *
 * Subclasses clean up their per player artifacts in [onDisplayPlayerRemoved].
 */
abstract class RegionBoundaryDisplay(
    protected val region: RegionData,
    private val area: BoundaryRenderArea,
    private val entryId: String?,
) : AudienceDisplay(), TickableDisplay {
    protected val engine: RegionEngine by KoinJavaComponent.inject(RegionEngine::class.java)
    private val editRegistry: RegionEditRegistry by KoinJavaComponent.inject(RegionEditRegistry::class.java)
    private val subscriptions = ConcurrentHashMap<UUID, RegionEngine.Subscription>()

    final override fun onPlayerAdd(player: Player) {
        engine.observe(region, player, LazyInsideQueryHandler(this, player.uniqueId))
            ?.also { subscriptions[player.uniqueId] = it }
    }

    final override fun onPlayerRemove(player: Player) {
        subscriptions.remove(player.uniqueId)?.cancel()
        onDisplayPlayerRemoved(player)
    }

    /**
     * Called after the player's region observation is cancelled, so subclasses can restore
     * fake blocks or dispose fake entities. Must be idempotent; suppression during content
     * mode editing calls it every tick.
     */
    protected open fun onDisplayPlayerRemoved(player: Player) {}

    final override fun tick() {
        for (player in players) {
            if (editRegistry.isSuppressed(player.uniqueId, entryId, region)) {
                onDisplayPlayerRemoved(player)
                continue
            }
            val tracker = subscriptions[player.uniqueId]?.tracker ?: continue
            val transform = tracker.lastTransform ?: continue
            // Every artifact these displays send carries raw coordinates and no world, so a
            // viewer in another world would be shown the boundary at the same coordinates
            // where they stand. Their artifacts are cleaned up rather than left behind,
            // because the restore paths refuse to touch a player who is elsewhere.
            if (transform.world.identifier != player.world.uid.toString()) {
                onDisplayPlayerRemoved(player)
                continue
            }
            renderForPlayer(player, tracker, transform)
        }
    }

    /**
     * The window to filter samples with, or `null` when the display renders the full
     * boundary.
     */
    protected fun nearWindow(player: Player): NearWindow? = area.window(player)

    override fun dispose() {
        subscriptions.values.forEach(RegionEngine.Subscription::cancel)
        subscriptions.clear()
        super.dispose()
    }

    /**
     * Render the boundary for [player]. Implementations may call
     * `tracker.shape.sampleBoundary(density)` to obtain local frame samples and map them
     * through [transform] to world space, or sample the world directly like the ground
     * outline displays.
     */
    protected abstract fun renderForPlayer(player: Player, tracker: RegionTracker, transform: ResolvedTransform)
}
