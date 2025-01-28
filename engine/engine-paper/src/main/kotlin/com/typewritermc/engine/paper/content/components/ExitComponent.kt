package com.typewritermc.engine.paper.content.components

import com.typewritermc.engine.paper.content.ContentMode
import com.typewritermc.engine.paper.content.ContentPopTrigger
import com.typewritermc.engine.paper.content.inLastContentMode
import com.typewritermc.engine.paper.entry.entries.InteractionEndTrigger
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.loreString
import com.typewritermc.engine.paper.utils.name
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.registerEvents
import org.bukkit.Material
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerToggleSneakEvent
import org.bukkit.inventory.ItemStack
import java.util.*

fun ContentMode.exit(doubleShiftExits: Boolean = false) = +ExitComponent(doubleShiftExits)
class ExitComponent(
    private val doubleShiftExits: Boolean,
) : ItemComponent, Listener {
    private var playerId: UUID? = null
    private var lastShift = 0L

    override suspend fun initialize(player: Player) {
        super.initialize(player)
        if (!doubleShiftExits) return
        plugin.registerEvents(this)
        playerId = player.uniqueId
    }

    @EventHandler
    private fun onShift(event: PlayerToggleSneakEvent) {
        if (event.player.uniqueId != playerId) return
        // Only count shifting down
        if (!event.isSneaking) return
        if (System.currentTimeMillis() - lastShift < 500) {
            ContentPopTrigger.triggerFor(event.player, context())
        }
        lastShift = System.currentTimeMillis()
    }

    override suspend fun dispose(player: Player) {
        super.dispose(player)
        unregister()
    }

    override fun item(player: Player): Pair<Int, IntractableItem> {
        val sneakingLine = if (doubleShiftExits) {
            "<line> <gray>Double shift to exit"
        } else {
            ""
        }
        val item = if (player.inLastContentMode) {
            ItemStack(Material.BARRIER).apply {
                editMeta { meta ->
                    meta.name = "<red><bold>Exit Editor"
                    meta.loreString = """
                    |
                    |<line> <gray>Click to exit the editor.
                    |$sneakingLine
                """.trimMargin()
                }
            }
        } else {
            ItemStack(Material.END_CRYSTAL).apply {
                editMeta { meta ->
                    meta.name = "<yellow><bold>Previous Editor"
                    meta.loreString = """
                    |
                    |<line> <gray>Click to go back to the previous editor.
                    |$sneakingLine
                """.trimMargin()
                }
            }
        }

        return 8 to item {
            ContentPopTrigger.triggerFor(player, context())
        }
    }
}