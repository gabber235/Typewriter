package com.typewritermc.basic.entries.action

import com.google.gson.annotations.SerializedName
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
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
import kotlin.random.Random

@Entry("weighted_random_trigger_gate", "A weighted random trigger gate", Colors.PINK, "jam:dices-f")
/**
 * The `Weighted Random Trigger Gate` is a gate that triggers a specified number of entries randomly.
 *
 * ## How could this be used?
 * This gate can be used for drops, loot, or other random events.
 * Where some events are more likely to occur than others.
 */
class WeightedRandomTriggerGateEntry(
    override val id: String = "",
    override val name: String = "",
    override val criteria: List<Criteria> = emptyList(),
    override val modifiers: List<Modifier> = emptyList(),
    @SerializedName("triggers")
    val customTriggers: Map<Ref<TriggerableEntry>, Int> = emptyMap(),
    @Help("The number of triggers to fire next.")
    @Default("1")
    private val amount: Var<Int> = ConstVar(1),
) : ActionEntry {
    // Disable the normal triggers. So that the action can manually trigger the next actions.
    override val triggers: List<Ref<TriggerableEntry>>
        get() = emptyList()

    override fun ActionTrigger.execute() {
        disableAutomaticTriggering()
        val selectedTriggers = mutableListOf<Ref<TriggerableEntry>>()

        if (customTriggers.isNotEmpty()) {
            for (i in 1..amount.get(player, context)) {
                selectedTriggers.add(customTriggers.weightedRandom())
            }
        }

        applyModifiers()
        selectedTriggers.triggerFor(player)
    }
}

private fun Map<Ref<TriggerableEntry>, Int>.weightedRandom(): Ref<TriggerableEntry> {
    if (isEmpty()) return emptyRef()
    if (size == 1) return this.keys.first()

    val discreteCumulativeWeights =
        this.entries.scan(0.0) { acc, entry -> acc + entry.value.toDouble() }.toList().drop(1)

    val random = Random.nextDouble() * discreteCumulativeWeights.last()
    return this.entries.zip(discreteCumulativeWeights).first { (_, cumulativeWeight) ->
        cumulativeWeight > random
    }.first.key
}