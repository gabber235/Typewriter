package com.typewritermc.basic.entries.action

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.Modifier
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.ActionEntry
import com.typewritermc.engine.paper.entry.entries.ActionTrigger
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var

@Entry("random_trigger", "Randomly selects its connected triggers", Colors.PINK, "mdi:clover")
/**
 * The `Random Trigger Gate` is a gate that triggers a specified number of entries randomly. This gate provides you with the ability to randomly select and trigger a set number of entries in response to a specific event.
 *
 * ## How could this be used?
 *
 * This gate can be useful in a variety of situations. You can use it to create a mini-game that randomly selects events to occur, or to trigger a set number of actions randomly in response to a specific event. The possibilities are endless!
 */
class RandomTriggerGateEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    @Help("The number of triggers to fire next.")
    @Default("1")
    private val amount: Var<Int> = ConstVar(1),
) : ActionEntry {
    override fun ActionTrigger.execute() {
        disableAutomaticTriggering()
        val selectedTriggers = mutableListOf<Ref<TriggerableEntry>>()

        if (triggers.isNotEmpty()) {
            val randomIndices = (triggers.indices).shuffled().take(amount.get(player, context))
            for (index in randomIndices) {
                selectedTriggers.add(triggers[index])
            }
        }

        applyModifiers()
        selectedTriggers.triggerFor(player)
    }
}