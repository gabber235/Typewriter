package com.typewritermc.visibility

import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.playerHides
import kotlinx.coroutines.Dispatchers
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import java.util.*
import java.util.concurrent.ConcurrentHashMap

/**
 * What one viewer sees instead of a hidden target.
 *
 * A disguise records this alongside its hide so packet hooks and client side teams can follow the
 * visible entity. Plain hides leave it absent and everything keeps using the real target.
 */
data class VisibleReplacement(val entityId: Int, val member: String)

/**
 * The owner under which visibility effects hide players from each other.
 *
 * The hides themselves live in [com.typewritermc.engine.paper.utils.PlayerHides], which counts the
 * features that want a pair hidden so an overlapping cinematic and visibility rule do not undo each
 * other, and which forgets a disconnected player for every feature at once. This registry gives the
 * extension one owner to release on teardown, and nothing else.
 *
 * All methods must be called from the main thread.
 */
@Singleton
class VisibilityHideRegistry : Initializable, KoinComponent {
    private val replacements = ConcurrentHashMap<Pair<UUID, UUID>, VisibleReplacement>()

    override suspend fun initialize() {}

    /**
     * Releases every outstanding hide.
     * A reload discards this registry, while the hides live on the player connections and would
     * outlive it with nothing left to undo them.
     */
    override suspend fun shutdown() {
        Dispatchers.Sync.switchContext { playerHides.release(this@VisibilityHideRegistry) }
    }

    fun hide(viewer: Player, target: Player, replacement: VisibleReplacement? = null) {
        if (viewer.uniqueId == target.uniqueId) return
        val key = viewer.uniqueId to target.uniqueId
        if (replacement == null) replacements.remove(key) else replacements[key] = replacement
        playerHides.hide(this, viewer, target)
    }

    /**
     * What [viewerId] sees instead of [targetId], or null when the real target is shown.
     */
    fun replacementFor(viewerId: UUID, targetId: UUID): VisibleReplacement? {
        if (viewerId == targetId) return null
        return replacements[viewerId to targetId]
    }

    /**
     * Undoes a hide.
     * The target stays hidden while anything else still wants them hidden from this viewer.
     */
    fun show(viewerId: UUID, targetId: UUID) {
        if (viewerId == targetId) return
        replacements.remove(viewerId to targetId)
        playerHides.show(this, viewerId, targetId)
    }

    /**
     * Drops every replacement shown to [viewerId].
     * Called when the viewer disconnects.
     */
    fun forget(viewerId: UUID) {
        replacements.keys.removeIf { it.first == viewerId }
    }
}
