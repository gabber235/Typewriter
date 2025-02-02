package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.command.dsl.playersResolver
import com.typewritermc.engine.paper.command.dsl.sender
import com.typewritermc.engine.paper.command.dsl.withPermission
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.CustomCommandEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.engine.paper.utils.msg
import io.papermc.paper.command.brigadier.CommandSourceStack
import org.bukkit.entity.Player

@Entry("on_run_command", "When a player runs a custom command", Colors.YELLOW, "mingcute:terminal-fill")
/**
 * The `Run Command Event` event is triggered when a command is run. This event can be used to add custom commands to the server.
 *
 * It allows any player to run the command.
 * And allows you to target a specific player if you have the permission `typewriter.<command>.other`.
 *
 * :::caution
 * This event is used for commands that **do not** already exist. If you are trying to detect when a player uses an already existing command, use the [`Detect Command Ran Event`](on_detect_command_ran) instead.
 * :::
 */
class RunCommandEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("The command to register. Do not include the leading slash.")
    val command: String = "",
) : CustomCommandEntry, EventEntry {
    @Suppress("UnstableApiUsage")
    override fun command() = com.typewritermc.engine.paper.command.dsl.command<CommandSourceStack>(command) {
        executes {
            val player = (source.executor as? Player) ?: (sender as? Player)
            if (player == null) {
                sender.msg("You must be a player to run this command.")
                return@executes
            }
            triggerAllFor(player, context())
        }
        playersResolver("target") { resolver ->
            withPermission("typewriter.${command}.other")
            executes {
                val players = resolver().resolve(source)
                if (players.isEmpty()) {
                    sender.msg("<red>No players found to run this command for.")
                    return@executes
                }
                players.forEach { player ->
                    triggerAllFor(player, context())
                }
                sender.msg("Triggered $command for <green>${players.joinToString(", ") { it.name }}</green>.")
            }
        }
    }
}

