package com.typewritermc.region.content

import com.typewritermc.core.extension.Initializable
import com.typewritermc.core.extension.annotations.Singleton
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.switchContext
import com.typewritermc.engine.paper.content.isInContentInteraction
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.TICK_MS
import com.typewritermc.region.cancelAndJoinBounded
import kotlinx.coroutines.*
import org.bukkit.Bukkit
import org.bukkit.Location
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject
import java.util.*
import kotlin.time.Duration.Companion.milliseconds

/**
 * Renders the live working preview of every open edit session to nearby players who are
 * not the session's editor: the outline follows the editor's carries, drags and undos in
 * real time, with a name tag saying who is working on the region. Only players who hold
 * the region edit permission and are inside a content editor themselves see it; everyone
 * else keeps seeing the published boundary.
 *
 * The renderer is participant agnostic: it draws whatever [RegionEditSession.preview]
 * holds for whoever is near. A future collaborative mode reuses it unchanged by
 * publishing its shared working model as the preview.
 */
@Singleton
class RegionEditSpectators : Initializable, KoinComponent {
    private val registry: RegionEditRegistry by inject()
    private val views = mutableMapOf<ViewKey, SpectatorView>()
    private var scope: CoroutineScope? = null

    override suspend fun initialize() {
        val scope = CoroutineScope(SupervisorJob() + Dispatchers.UntickedAsync)
        this.scope = scope
        scope.launch {
            try {
                while (isActive) {
                    Dispatchers.Sync.switchContext { render() }
                    delay(TICK_MS.milliseconds)
                }
            } finally {
                withContext(NonCancellable) {
                    Dispatchers.Sync.switchContext {
                        views.values.forEach(SpectatorView::despawn)
                        views.clear()
                    }
                }
            }
        }
    }

    override suspend fun shutdown() {
        val scope = this.scope ?: return
        this.scope = null
        scope.coroutineContext.job.cancelAndJoinBounded()
    }

    /** Main thread only: reconciles one view per session and eligible nearby player. */
    private fun render() {
        val active = registry.sessions()
        val desired = mutableSetOf<ViewKey>()

        for (session in active) {
            val preview = session.preview ?: continue
            for (viewer in Bukkit.getOnlinePlayers()) {
                if (!canSpectate(viewer, session, preview)) continue
                val key = ViewKey(session.entryId, viewer.uniqueId)
                desired += key
                views.getOrPut(key) { SpectatorView(viewer) }.update(preview, session.editorName)
            }
        }

        val stale = views.keys - desired
        for (key in stale) views.remove(key)?.despawn()

        for (session in active) {
            val watching = desired.filter { it.entryId == session.entryId }.mapTo(mutableSetOf()) { it.viewerId }
            session.spectators.retainAll(watching)
            session.spectators.addAll(watching)
        }
    }

    private fun canSpectate(viewer: Player, session: RegionEditSession, preview: SessionPreview): Boolean {
        if (viewer.uniqueId == session.editorId) return false
        if (!viewer.hasPermission(SPECTATE_PERMISSION)) return false
        if (!viewer.isInContentInteraction) return false
        if (preview.transform.world.identifier != viewer.world.uid.toString()) return false
        // Distance to the boundary, not the anchor: a viewer at the edge of a huge region
        // is close to the edit even when its center is far away.
        val location = viewer.location
        val local = preview.transform.toLocal(Vector(location.x, location.y, location.z))
        return preview.shape.signedDistance(local) <= RANGE
    }

    private data class ViewKey(val entryId: String, val viewerId: UUID)

    private class SpectatorView(private val viewer: Player) {
        private val outline = RegionOutline(viewer)
        private val hologram = EditorHologram(viewer)

        fun update(preview: SessionPreview, editorName: String) {
            val anchor = preview.transform.worldOrigin
            outline.update(
                Location(viewer.world, anchor.x, anchor.y, anchor.z),
                preview.transform.yawDegrees,
                preview.transform.pitchDegrees,
                preview.shape,
                preview.color,
                rollDegrees = preview.transform.rollDegrees,
            )
            val top = preview.shape.localBounds
                .rotated(preview.transform.yawDegrees, preview.transform.pitchDegrees, preview.transform.rollDegrees)
                .maxY
            val hex = String.format("#%02X%02X%02X", preview.color.red, preview.color.green, preview.color.blue)
            hologram.update(
                Location(viewer.world, anchor.x, anchor.y + top + NAME_LIFT, anchor.z),
                "<$hex>■</$hex> <white><bold>${preview.regionName}</bold></white> <$hex>■</$hex>\n" +
                        "<yellow>✎ $editorName ${preview.activity}</yellow>",
            )
        }

        fun despawn() {
            outline.despawn()
            hologram.despawn()
        }
    }

    companion object {
        private const val RANGE = 64.0
        private const val NAME_LIFT = 1.0
        internal const val SPECTATE_PERMISSION = "typewriter.region.edit"
    }
}
