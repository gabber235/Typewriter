package com.typewritermc.region.content

import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.asMini
import org.bukkit.Color
import org.bukkit.Location
import org.bukkit.entity.Display
import org.bukkit.entity.Player
import org.bukkit.entity.TextDisplay

/**
 * A floating readout above the edited region, visible only to the editing player. The
 * display interpolates teleports, so it glides along while the region is carried.
 *
 * Every method must run on the server main thread; the content mode hops to the sync
 * dispatcher for its per tick update.
 */
internal class EditorHologram(private val player: Player) {
    private var display: TextDisplay? = null
    private var lastText: String? = null

    fun update(anchor: Location?, text: String) {
        if (anchor == null || anchor.world != player.world ||
            anchor.distanceSquared(player.location) > RANGE_SQUARED
        ) {
            despawn()
            return
        }
        // world.spawn force loads its chunk, and a hologram in an unloaded chunk is not
        // visible anyway, so it is skipped until the chunk loads.
        if (!anchor.world.isChunkLoaded(anchor.blockX shr 4, anchor.blockZ shr 4)) {
            despawn()
            return
        }

        val current = display?.takeIf { it.isValid } ?: spawn(anchor)
        if (current.location.distanceSquared(anchor) > MOVE_EPSILON_SQUARED) current.teleport(anchor)
        if (text != lastText) {
            lastText = text
            current.text(text.asMini())
        }
    }

    fun despawn() {
        display?.remove()
        display = null
        lastText = null
    }

    private fun spawn(location: Location): TextDisplay =
        location.world.spawn(location, TextDisplay::class.java) { hologram ->
            hologram.isPersistent = false
            hologram.isVisibleByDefault = false
            hologram.billboard = Display.Billboard.CENTER
            hologram.isSeeThrough = true
            hologram.teleportDuration = 2
            hologram.alignment = TextDisplay.TextAlignment.CENTER
            hologram.backgroundColor = Color.fromARGB(0xB4, 0x11, 0x12, 0x1A)
            hologram.brightness = Display.Brightness(15, 15)
            hologram.lineWidth = 220
            player.showEntity(plugin, hologram)
        }.also { display = it }

    companion object {
        private const val RANGE_SQUARED = 96.0 * 96.0
        private const val MOVE_EPSILON_SQUARED = 0.0025
    }
}
