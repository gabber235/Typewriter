package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import java.time.Duration

@Entry("delayed_action", "Delay an action for a certain amount of time", Colors.RED, "fa-solid:hourglass")
/**
 * The `Delayed Action Entry` is an entry that fires its triggers after a specified duration. This entry provides you with the ability to create time-based actions and events.
 *
 * ## How could this be used?
 *
 * This entry can be useful in a variety of situations where you need to delay an action or event.
 * You can use it to create countdown timers, to perform actions after a certain amount of time has elapsed, or to schedule events in the future.
 */
class DelayedActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("The duration before the next triggers are fired.")
    private val duration: Var<Duration> = ConstVar(Duration.ZERO),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        disableAutomaticTriggering()
        Dispatchers.UntickedAsync.launch {
            delay(duration.get(player, context).toMillis())
            triggerManually()
        }
    }
}