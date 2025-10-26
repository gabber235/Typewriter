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

@Entry(
    "on_detect_commands_ran",
    "When a player runs one of multiple commands",
    Colors.YELLOW,
    "mdi:account-eye",
)
/**
 * The `Multiple Detect Command Ran Event` is triggered when an **already existing** command that matches
 * any of the configured patterns is ran.
 *
 * :::caution
 * This event only works if the command already exists. If you are trying to make a new command that does not exist
 * already, use the [`Run Command Event`](on_run_command) instead.
 * :::
 *
 * ## How could this be used?
 *
 * This event can be used to trigger a response when any command from a curated list has been run.
 * For example, you could monitor a collection of administrative commands and log whenever one of them is executed.
 */
class MultipleDetectCommandRanEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Regex
    @Help("Commands to listen for. Each entry accepts a regular expression without the leading slash.")
    val commands: List<String> = emptyList(),
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

@EntryListener(MultipleDetectCommandRanEventEntry::class)
fun onRunMultipleCommands(
    event: PlayerCommandPreprocessEvent,
    query: Query<MultipleDetectCommandRanEventEntry>,
) {
    val message = event.message.removePrefix("/")

    val entries = query.findWhere { entry ->
        entry.commands.asSequence()
            .map(String::trim)
            .filter(String::isNotEmpty)
            .any { pattern -> KotlinRegex(pattern).matches(message) }
    }.toList()

    if (entries.isEmpty()) return
    entries.triggerAllFor(event.player, context())
    if (entries.shouldCancel(event.player)) event.isCancelled = true
}
