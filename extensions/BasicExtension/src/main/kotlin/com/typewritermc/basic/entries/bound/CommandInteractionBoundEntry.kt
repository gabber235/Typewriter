package com.typewritermc.basic.entries.bound

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.priority
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.interaction.InteractionBound
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.InteractionBoundEntry
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.CustomCommandEntry
import com.typewritermc.engine.paper.interaction.ListenerInteractionBound
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import org.bukkit.event.EventPriority
import org.bukkit.event.player.PlayerCommandPreprocessEvent

@Entry(
    "command_interaction_bound",
    "Interaction Bound for when the player types a command",
    Colors.MEDIUM_PURPLE,
    "gravity-ui:square-dashed-text"
)
/**
 * The `Command Interaction Bound` entry is an interaction bound that triggers when the player types a command.
 *
 * ## How could this be used?
 * This could be used to allow the player to cancel the interaction if they type a command.
 */
class CommandInteractionBoundEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
) : InteractionBoundEntry {
    override fun build(player: Player): InteractionBound = PlayerCommandInteractionBound(player, priority)
}

class PlayerCommandInteractionBound(
    private val player: Player,
    override val priority: Int,
) : ListenerInteractionBound {

    @EventHandler(priority = EventPriority.MONITOR, ignoreCancelled = true)
    private fun onCommand(event: PlayerCommandPreprocessEvent) {
        if (event.player.uniqueId != player.uniqueId) return
        val command = event.message.removePrefix("/")
        // We don't want to end the dialogue if the player is running a typewriter command
        if (command.startsWith("typewriter")) return
        if (command.startsWith("tw")) return


        // If this is a custom command, we don't want to end the dialogue
        val entry = Query.firstWhere<CustomCommandEntry> {
            command.startsWith(it.command)
        }
        if (entry != null) return

        handleEvent(event)
    }
}