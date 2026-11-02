package com.typewritermc.visibility.fact

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entries.GroupEntry
import com.typewritermc.engine.paper.entry.entries.ReadableFactEntry
import com.typewritermc.engine.paper.facts.FactData
import com.typewritermc.visibility.VisibilityEngine
import com.typewritermc.visibility.entry.rule.VisibilityRuleProvider
import org.bukkit.entity.Player
import org.koin.core.component.KoinComponent
import org.koin.core.component.inject

@Entry(
    "visibility_targets_count_fact",
    "Number of players a viewer has active visibility rules for",
    Colors.PURPLE,
    "mdi:eye-arrow-right"
)
/**
 * The `Visibility Targets Count Fact` is the number of other players that this player currently
 * sees with an active visibility effect. An effect this player has on their own view of themselves
 * is not counted.
 *
 * The count can be narrowed down to the rules of a specific visibility rule entry.
 *
 * ## How could this be used?
 * Show a status line while a player has detection powers active, or trigger dialogue when a
 * player can see at least one hidden spirit.
 */
class VisibilityTargetsCountFact(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
    @Help("Count only rules of this visibility rule entry. Leave empty to count all rules.")
    val ruleEntry: Ref<VisibilityRuleProvider> = emptyRef(),
) : ReadableFactEntry, KoinComponent {
    private val engine: VisibilityEngine by inject()

    override fun readSinglePlayer(player: Player): FactData {
        val entryId = if (ruleEntry.isSet) ruleEntry.id else null
        return FactData(engine.viewerRuleCount(player.uniqueId, entryId))
    }
}
