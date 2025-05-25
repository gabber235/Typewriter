package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.MultiLine
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.utils.Sync
import com.typewritermc.engine.paper.utils.server
import kotlinx.coroutines.Dispatchers
import org.bukkit.Bukkit

@Entry("console_run_command", "Run command from console", Colors.RED, "mingcute:terminal-fill")
/**
 * The Console Command Action is an action that sends a command to the server console. This action provides you with the ability to execute console commands on the server in response to specific events.
 *
 * ## How could this be used?
 *
 * This action can be useful in a variety of situations. You can use it to perform administrative tasks, such as sending a message to all players on the server, or to automate server tasks, such as setting the time of day or weather conditions. The possibilities are endless!
 */
class ConsoleCommandActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Placeholder
    @MultiLine
    @Help("Every line is a different command. Commands should not be prefixed with <code>/</code>.")
    private val command: Var<String> = ConstVar(""),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        val command = command.get(player, context)
        // Run in the main thread
        if (command.isBlank()) return
        Dispatchers.Sync.launch {
            val commands = command.parsePlaceholders(player).lines()
            for (cmd in commands) {
                server.dispatchCommand(Bukkit.getConsoleSender(), cmd)
            }
        }
    }
}