package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.toTicks
import java.time.Duration

@Entry("burn_player_action", "Burns the player for a certain amount of time", Colors.RED, "mdi:fire")
/**
 * The `Burn Player Action` is an action that burns the player for a certain amount of time.
 *
 * ## How could this be used?
 * To simulate the player burning their hands on something hot.
 * Or to punish players when they are naughty ;)
 */
class BurnPlayerActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    val duration: Var<Duration> = ConstVar(Duration.ofSeconds(1)),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        player.fireTicks = duration.get(player, context).toTicks().toInt()
    }
}