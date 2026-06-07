package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.LabelKey
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.triggerEntriesFor
import java.util.*

@Entry(
    "group_trigger_action",
    "Trigger the next entries for everyone in the same group as the player",
    Colors.RED,
    "fluent:globe-arrow-forward-16-filled"
)
/**
 * The `Group Trigger Action` is an action that triggers the next entries for everyone in the same group as the player.
 *
 * :::caution
 * The modifiers will only be applied to the player that triggered the action.
 * If you want to modify the other players, you will need to do it in the next entries.
 * :::
 *
 * ## How could this be used?
 * This could be used to trigger the next entries for everyone in the same group as the player,
 * when a player joins a faction, all the other players in the same faction could be notified.
 */
class GroupTriggerActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val group: Ref<GroupEntry> = emptyRef(),
    @LabelKey("basic.group_trigger_action.fields.forceGroup.label")
    @Help(key = "basic.group_trigger_action.fields.forceGroup.help")
    val forceGroup: Optional<Var<String>> = Optional.empty(),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        val groupEntry = group.get() ?: return

        val group = forceGroup
            .map { groupEntry.group(GroupId(it.get(player, context))) }
            .orElseGet { groupEntry.group(player) } ?: return

        group.players
            // Since we are still just triggering this for the player, we don't want to trigger it twice.
            .filter { it.uniqueId != player.uniqueId }
            .forEach {
                triggers.triggerEntriesFor(it, context)
            }
    }
}