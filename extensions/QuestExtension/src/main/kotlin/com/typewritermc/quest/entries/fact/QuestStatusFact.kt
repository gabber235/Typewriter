package com.typewritermc.quest.entries.fact

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.GroupEntry
import com.typewritermc.engine.paper.entry.entries.ReadableFactEntry
import com.typewritermc.engine.paper.facts.FactData
import com.typewritermc.quest.entries.QuestEntry
import com.typewritermc.quest.isQuestActive
import com.typewritermc.quest.isQuestCompleted
import com.typewritermc.quest.isQuestTracked
import org.bukkit.entity.Player

@Entry(
    "quest_status_fact",
    "The status of a specific quest",
    Colors.PURPLE,
    "solar:mailbox-bold"
)
/**
 * The `QuestStatusFact` is a fact that returns the status of a specific quest.
 *
 * <fields.ReadonlyFactInfo />
 *
 * | Status | Value |
 * |--------|-------|
 * | Inactive | 0 |
 * | Active | 1 |
 * | Active and Tracked | 2 |
 * | Completed | -1 |
 *
 * :::warning
 * The __completed__ status has a value of **-1**, this is to make it easy to query if the quest is active by `>= 1`.
 * :::
 *
 * ## How could this be used?
 *
 * This can be used to abstract the status of a quest.
 * If a quest has multiple criteria, you can check for this fact instead of checking for each criterion.
 */
class QuestStatusFact(
    override val id: String = "",
    override val name: String = "",
    override val comment: String = "",
    override val group: Ref<GroupEntry> = emptyRef(),
    val quest: Ref<QuestEntry> = emptyRef(),
) : ReadableFactEntry {
    override fun readSinglePlayer(player: Player): FactData {
        val status = when {
            player.isQuestCompleted(quest) -> -1
            player.isQuestActive(quest) -> if (player.isQuestTracked(quest)) 2 else 1
            else -> 0
        }
        return FactData(status)
    }
}