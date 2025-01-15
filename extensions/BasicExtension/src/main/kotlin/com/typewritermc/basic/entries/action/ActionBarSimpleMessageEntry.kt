package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Colored
import com.typewritermc.core.extension.annotations.Entry
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
import com.typewritermc.engine.paper.utils.asMini

@Entry("action_bar_simple_message", "Send an action bar message to a player", Colors.RED, "bxs:message-square-detail")
/**
 * The `Action Bar Simple Message` is an action that sends a message to the player using the action bar.
 * This allows you to send an action bar message **without** a speaker.
 *
 * ## How could this be used?
 * Send a simple message to a player using the action bar without a speaker.
 */
class ActionBarSimpleMessageEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Placeholder
    @Colored
    @MultiLine
    val message: Var<String> = ConstVar(""),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        player.sendActionBar(message.get(player, context).parsePlaceholders(player).asMini())
    }
}