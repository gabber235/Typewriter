package com.typewritermc.basic.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.EntryListener
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Regex
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.CancelableEventEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.shouldCancel
import com.typewritermc.engine.paper.entry.triggerAllFor
import org.bukkit.event.player.PlayerCommandPreprocessEvent
import kotlin.text.Regex as KotlinRegex

@Entry("on_detect_command_ran", "When a player runs an existing command", Colors.YELLOW, "mdi:account-eye")
/**
 * The `Detect Command Ran Event` event is triggered when an **already existing** command is ran.
 *
 * :::caution
 * This event only works if the command already exists. If you are trying to make a new command that does not exist already, use the [`Run Command Event`](on_run_command) instead.
 * :::
 *
 * ## How could this be used?
 *
 * This event could be used to trigger a response when a specific command has been run.
 * For example, you could have a command that sends a message to a channel when a command has been run,
 * which could be used as an audit log for your admins.
 */
class DetectCommandRanEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Regex
    @Help("The command that was ran. Can be a regular expression.")
    /**
     * The command to listen for.
     * This can be partial, so if you wanted to listen for any warp command,
     * you could use <code>warp</code> as the command.
     * However, this can also include parameters, so if you
     * wanted to listen if the player warps to spawn, you could use
     * <code>warp spawn</code> as the command.
     * <br />
     * <Admonition type="caution">
     *     Do not include the <code>/</code> at the start of the command.
     *     This will be added automatically.
     * </Admonition>
     */
    val command: String = "",
    /**
     * Cancel the event when triggered.
     * It will only cancel the event if all the criteria are met.
     * If set to false, it will not modify the event.
     *
     * <Admonition type="tip">
     *     You should always set this to true if any dialog is triggered after this.
     *     To prevent the dialog from immediately being closed.
     * </Admonition>
     */
    override val cancel: Var<Boolean> = ConstVar(false),
) : CancelableEventEntry

@EntryListener(DetectCommandRanEventEntry::class)
fun onRunCommand(event: PlayerCommandPreprocessEvent, query: Query<DetectCommandRanEventEntry>) {
    val message = event.message.removePrefix("/")

    val entries = query.findWhere { KotlinRegex(it.command).matches(message) }.toList()
    if (entries.isEmpty()) return
    entries.triggerAllFor(event.player, context())
    if (entries.shouldCancel(event.player)) event.isCancelled = true
}