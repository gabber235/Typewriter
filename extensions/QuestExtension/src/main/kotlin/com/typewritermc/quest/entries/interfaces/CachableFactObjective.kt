package com.typewritermc.quest.entries.interfaces

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Colored
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.engine.paper.entry.PlaceholderParser
import com.typewritermc.engine.paper.entry.entries.CachableFactEntry
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.entry.include
import com.typewritermc.engine.paper.entry.literal
import com.typewritermc.engine.paper.entry.placeholderParser
import com.typewritermc.engine.paper.entry.supplyPlayer
import com.typewritermc.quest.entries.ObjectiveEntry
import org.bukkit.entity.Player

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
}