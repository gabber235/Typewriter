package com.typewritermc.quest.entries.interfaces

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entries.CachableFactEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.facts.FactData
import com.typewritermc.engine.paper.interaction.interactionContext
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.replaceTagPlaceholders
import com.typewritermc.quest.entries.ObjectiveEntry
import com.typewritermc.quest.entries.inactiveObjectiveDisplay
import com.typewritermc.quest.entries.showingObjectiveDisplay
import org.bukkit.entity.Player

val objectiveDisplay by snippet(
    "quest.objectives.cachable.completed",
    "<green>✔</green> <gray><display></gray>"
)

interface CachableFactObjective : ObjectiveEntry {

    @Help("The display supports the <value> and <target> tags for showing progress.")
    @Colored
    @Placeholder
    @Default("\"<value>/<target>\"")
    override val display: Var<String>

    val progressTracking: CacheableFactObjectiveProgressTracking

    @Help("The entries that will trigger once the objective is completed.")
    val completionTriggers: List<TriggerableEntry>

    fun incrementFact(player: Player, amount: Int = 0) {
        if (!player.inAudience(this)) return

        // Before values
        // TODO: Some 1.0 thingy: Let Fact handle the increment for proper synchronization.
        var current = progressTracking.value.get()?.readForPlayersGroup(player) ?: return
        val completedBefore = progressTracking.isValid(current, player, player.interactionContext ?: context())

        // update values
        progressTracking.value.get()?.write(player, current.value + amount)

        // After values
        current = progressTracking.value.get()?.readForPlayersGroup(player) ?: return
        val completedAfter = progressTracking.isValid(current, player, player.interactionContext ?: context())

        // Check if completed
        if (!completedBefore && completedAfter) {
            completionTriggers.triggerAllFor(player, player.interactionContext ?: context())
        }
    }

    override fun parser(): PlaceholderParser = placeholderParser {
        include(super.parser())

        literal("value") {
            supplyPlayer { player ->
                progressTracking.value.get()?.readForPlayersGroup(player)?.value?.toString() ?: "0"
            }
        }

        literal("target") {
            supplyPlayer { player ->
                progressTracking.target.get(player).toString()
            }
        }
    }

    override fun display(player: Player?): String {
        if (player == null) {
            return inactiveObjectiveDisplay
        }
        val value = progressTracking.value.get()?.readForPlayersGroup(player)?.value ?: 0
        val target = progressTracking.target.get(player)
        val text = when {
            progressTracking.operator.isValid(
                value,
                target
            ) -> objectiveDisplay

            criteria.matches(player) -> showingObjectiveDisplay
            else -> inactiveObjectiveDisplay
        }
        return text
            .replaceTagPlaceholders("display", display.get(player))
            .replaceTagPlaceholders("value", value.toString())
            .replaceTagPlaceholders("target", target.toString())
            .parsePlaceholders(player)
    }
}

data class CacheableFactObjectiveProgressTracking(
    @Help("The fact that is being updated with the value towards the target.")
    val value: Ref<CachableFactEntry> = emptyRef(),
    @Help("The operator to use when comparing the fact value to the target value for completion.")
    val operator: CriteriaOperator = CriteriaOperator.GREATER_THAN_OR_EQUAL,
    @Help("The target value to reach for completion.")
    @Negative
    val target: Var<Int> = ConstVar(0),
) {
    fun isValid(fact: FactData?, player: Player, context: InteractionContext): Boolean {
        val value = fact?.value ?: 0
        return operator.isValid(value, this.target.get(player, context))
    }
}