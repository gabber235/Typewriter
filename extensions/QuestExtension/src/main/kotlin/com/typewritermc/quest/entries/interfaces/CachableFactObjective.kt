package com.typewritermc.quest.entries.interfaces

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Colored
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Negative
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.interaction.InteractionContext
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entries.CachableFactEntry
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.entries.get
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.facts.FactData
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.replaceTagPlaceholders
import com.typewritermc.quest.entries.ObjectiveEntry
import com.typewritermc.quest.entries.inactiveObjectiveDisplay
import com.typewritermc.quest.entries.showingObjectiveDisplay
import org.bukkit.entity.Player
import kotlin.math.absoluteValue

val objectiveDisplay by snippet(
    "quest.objectives.cachable.completed",
    "<green>✔</green> <gray><display></gray>"
)

interface CachableFactObjective : ObjectiveEntry {

    @Help("The display supports the <value> and <target> tags for showing progress.")
    @Colored
    @Placeholder
    override val display: Var<String>

    @Help("The fact that is being updated with the value towards the target.")
    val value: Ref<CachableFactEntry>

    @Help("The target value to reach for completion.")
    val target: Var<Int>

    fun changeFact(player: Player, amount: Int = 0) {
        val current = value.get()?.readForPlayersGroup(player)?.value ?: 0
        value.get()?.write(player, current + amount)
    }

    override fun parser(): PlaceholderParser = placeholderParser {
        include(super.parser())

        literal("value") {
            supplyPlayer { player ->
                value.get()?.readForPlayersGroup(player)?.value?.toString() ?: "0"
            }
        }

        literal("target") {
            supplyPlayer { player ->
                target.get(player).toString()
            }
        }
    }

    override fun display(player: Player?): String {
        val text = when {
            player == null -> inactiveObjectiveDisplay
            progressTracking.operator.isValid(
                progressTracking.value.get()?.readForPlayersGroup(player)?.value ?: 0,
                progressTracking.target.get(player).absoluteValue
            ) -> objectiveDisplay

            criteria.matches(player) -> showingObjectiveDisplay
            else -> inactiveObjectiveDisplay
        }
        return text
            .replaceTagPlaceholders("display", display.get(player) ?: "")
            .replaceTagPlaceholders(
                "value",
                progressTracking.value.get()?.readForPlayersGroup(player!!)?.value?.toString() ?: "0"
            )
            .replaceTagPlaceholders("target", progressTracking.target.get(player).toString())
            .parsePlaceholders(player)
    }
}
}