package com.typewritermc.quest.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.entry.matches
import com.typewritermc.quest.entries.QuestEntry
import com.typewritermc.quest.QuestStatus
import org.bukkit.entity.Player

@Entry("quest", "A quest definition", Colors.MEDIUM_PURPLE, "material-symbols:book-2")
/**
 * The `Quest` entry is a collection of tasks that the player can complete.
 * It is mainly for displaying the progress to a player.
 *
 * It is **not** necessary to use this entry for quests.
 * It is just a visual novelty.
 *
 * The entry filters the audience based on if the quest is active.
 *
 * ## How could this be used?
 * This could be used to show the progress of a quest to a player.
 * Connect objectives to the quest to show a player what they need to do.
 */
class SimpleQuestEntry(
    override val id: String = "",
    override val name: String = "",
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val displayName: Var<String> = ConstVar(""),
    @Help("When the criteria is met, it considers the quest to be active.")
    val activeCriteria: List<Criteria> = emptyList(),

    @Help("When the criteria is met, it considers the quest to be completed.")
    val completedCriteria: List<Criteria> = emptyList(),
) : QuestEntry {
    override val facts: List<Ref<ReadableFactEntry>>
        get() = (activeCriteria + completedCriteria).map { it.fact }

    override fun questStatus(player: Player): QuestStatus {
        return when {
            completedCriteria.matches(player) -> QuestStatus.COMPLETED
            activeCriteria.matches(player)-> QuestStatus.ACTIVE
            else -> QuestStatus.INACTIVE
        }
    }
}
