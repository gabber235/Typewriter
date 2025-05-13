package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.MultiLine
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.utils.ThreadType.SYNC
import com.typewritermc.core.utils.server

@Entry("player_run_command", "Make player run command", Colors.RED, "mingcute:terminal-fill")
/**
 * The `Player Command Action` is an action that runs a command as if the player entered it.
 * This action provides you with the ability to execute commands on behalf of the player in response to specific events.
 *
 * ## How could this be used?
 *
 * This action can be useful in a variety of situations.
 * You can use it to provide players with a custom command that triggers a specific action,
 * such as teleporting the player to a specific location or giving them an item.
 * You can also use it to automate repetitive tasks,
 * such as sending a message to the player when they complete a quest or achievement.
 * The possibilities are endless!
 */
class PlayerCommandActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Placeholder
    @MultiLine
    @Help("Every line is a different command. Commands should not be prefixed with <code>/</code>.")
    val command: Var<String> = ConstVar(""),
    val sudo: Boolean = false,
) : ActionEntry {
    override fun ActionTrigger.execute() {
        val command = command.get(player, context)
        // Run in main thread
        if (command.isBlank()) return
        SYNC.launch {
            val attachment = if (sudo) {
                player.addAttachment(plugin)
            } else null
            attachment?.setPermission("*", true)
            val commands = command.parsePlaceholders(player).lines()
            for (cmd in commands) {
                server.dispatchCommand(player, cmd)
            }
            attachment?.remove()
        }
    }
}