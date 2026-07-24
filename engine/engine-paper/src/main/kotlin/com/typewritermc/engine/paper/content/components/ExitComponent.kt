package com.typewritermc.engine.paper.content.components

import com.typewritermc.engine.paper.content.ContentMode
import com.typewritermc.engine.paper.content.ContentPopTrigger
import com.typewritermc.engine.paper.content.inLastContentMode
import com.typewritermc.engine.paper.entry.entries.InteractionEndTrigger
import com.typewritermc.engine.paper.entry.triggerFor
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.loreString
import com.typewritermc.engine.paper.utils.name
import lirand.api.extensions.events.unregister
import lirand.api.extensions.server.registerEvents
import org.bukkit.Material
import org.bukkit.Sound
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.Listener
import org.bukkit.event.player.PlayerToggleSneakEvent
import org.bukkit.inventory.ItemStack
import java.util.*

/**
 * Adds the exit item. When [needsConfirmation] reports pending work, the first exit
 * attempt only warns; a second attempt shortly after actually exits. Content modes with
 * unapplied changes pass their dirty check here so a stray click cannot discard them.
 */
fun ContentMode.exit(doubleShiftExits: Boolean = false, needsConfirmation: (Player) -> Boolean = { false }) =
    +ExitComponent(doubleShiftExits, needsConfirmation)

class ExitComponent(
    private val doubleShiftExits: Boolean,
    private val needsConfirmation: (Player) -> Boolean = { false },
) : ItemComponent, Listener {
    private var playerId: UUID? = null
    private var lastShift = 0L
    private var confirmDeadline = 0L

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
            attemptExit(event.player)
        }
        lastShift = System.currentTimeMillis()
    }

    private fun attemptExit(player: Player) {
        val now = System.currentTimeMillis()
        if (needsConfirmation(player) && now > confirmDeadline) {
            confirmDeadline = now + CONFIRM_WINDOW_MILLIS
            player.playSound(player.location, Sound.BLOCK_NOTE_BLOCK_BASS, 0.6f, 0.8f)
            player.sendActionBar(
                "<yellow>You have unapplied changes; exiting discards them. Exit again to confirm.".asMini(),
            )
            return
        }
        ContentPopTrigger.triggerFor(player, context())
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
        val warningLine = if (needsConfirmation(player)) {
            "<line> <yellow>Unapplied changes are discarded on exit."
        } else {
            ""
        }
        val confirming = System.currentTimeMillis() <= confirmDeadline
        val item = if (player.inLastContentMode) {
            ItemStack(Material.BARRIER).apply {
                editMeta { meta ->
                    meta.name = if (confirming) "<red><bold>Confirm Exit" else "<red><bold>Exit Editor"
                    meta.loreString = """
                    |
                    |<line> <gray>Click to exit the editor.
                    |$warningLine
                    |$sneakingLine
                """.trimMargin()
                }
            }
        } else {
            ItemStack(Material.END_CRYSTAL).apply {
                editMeta { meta ->
                    meta.name = if (confirming) "<red><bold>Confirm Exit" else "<yellow><bold>Previous Editor"
                    meta.loreString = """
                    |
                    |<line> <gray>Click to go back to the previous editor.
                    |$warningLine
                    |$sneakingLine
                """.trimMargin()
                }
            }
        }

        return 8 to item {
            attemptExit(player)
        }
    }

    private companion object {
        const val CONFIRM_WINDOW_MILLIS = 5000L
    }
}
