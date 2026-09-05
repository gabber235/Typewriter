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
    "visibility_viewers_count_fact",
    "Number of players that have an active visibility rule on this player",
    Colors.PURPLE,
    "mdi:eye-arrow-left"
)
/**
 * The `Visibility Viewers Count Fact` is the number of other players that currently see this player
 * with an active visibility effect. An effect on this player's own view of themselves is not
 * counted, so the count still reaches zero while they see themselves changed.
 *
 * The count can be narrowed down to the rules of a specific visibility rule entry.
 *
 * ## How could this be used?
 * Check whether a vanished player is fully hidden from everyone, or count how many players
 * currently see a disguised imposter.
 */
class VisibilityViewersCountFact(
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
        return FactData(engine.targetRuleCount(player.uniqueId, entryId))
    }
}
