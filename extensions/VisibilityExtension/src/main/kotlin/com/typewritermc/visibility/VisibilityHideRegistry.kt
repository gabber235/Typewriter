package com.typewritermc.visibility

import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.utils.playerHides
import com.typewritermc.engine.paper.utils.Sync
import kotlinx.coroutines.Dispatchers
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import java.util.UUID

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
    override suspend fun initialize() {}

    /**
     * Releases every outstanding hide.
     * A reload discards this registry, while the hides live on the player connections and would
     * outlive it with nothing left to undo them.
     */
    override suspend fun shutdown() {
        Dispatchers.Sync.switchContext { playerHides.release(this@VisibilityHideRegistry) }
    }

    fun hide(viewer: Player, target: Player) {
        if (viewer.uniqueId == target.uniqueId) return
        playerHides.hide(this, viewer, target)
    }

    /**
     * Undoes a hide.
     * The target stays hidden while anything else still wants them hidden from this viewer.
     */
    fun show(viewerId: UUID, targetId: UUID) {
        if (viewerId == targetId) return
        playerHides.show(this, viewerId, targetId)
    }
}
