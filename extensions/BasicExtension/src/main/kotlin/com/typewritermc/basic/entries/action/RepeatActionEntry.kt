package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Min
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

@Entry("repeat_action", "Repeat an action multiple times", Colors.RED, "fluent:arrow-repeat-all-16-filled")
/**
 * The `Repeat Action Entry` is an entry that triggers its connected triggers multiple times.
 * You can specify the amount of repetitions and an optional delay between each repetition.
 *
 * :::note
 * To prevent deduplication and ensure each repetition is processed correctly,
 * there is a minimum delay of one server tick (50ms) between repetitions.
 * :::
 *
 * ## How could this be used?
 *
 * This entry can be useful when you want to perform a set of actions multiple times,
 * such as spawning multiple particles over time, sending multiple messages, or creating a repeating effect.
 */
class RepeatActionEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Default("1")
    private val amount: Var<Int> = ConstVar(1),
    @Help("The delay between each repetition. Minimum delay is 50ms.")
    @Default("50")
    @Min(50)
    private val interval: Var<Duration> = ConstVar(Duration.ofMillis(50)),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        disableAutomaticTriggering()
        val repeatAmount = amount.get(player, context)
        if (repeatAmount <= 0) return

        val repeatInterval = interval.get(player, context).toMillis()
        val delayMillis = repeatInterval.coerceAtLeast(50)

        Dispatchers.UntickedAsync.launch {
            repeat(repeatAmount) {
                triggerManually()
                delay(delayMillis)
            }
        }
    }
}
