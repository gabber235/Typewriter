package com.typewritermc.quest.entries.event

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.*
import com.typewritermc.core.interaction.EntryContextKey
import com.typewritermc.core.interaction.context
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.EventEntry
import com.typewritermc.engine.paper.entry.triggerAllFor
import com.typewritermc.quest.entries.QuestEntry
import com.typewritermc.quest.QuestStatus
import com.typewritermc.quest.events.AsyncQuestStatusUpdate
import kotlin.reflect.KClass

@Entry("quest_complete_event", "Triggered when a quest is completed for a player", Colors.YELLOW, "mdi:notebook-check")
@ContextKeys(QuestCompleteEventContextKeys::class)
/**
 * The `Quest Complete Event` entry is triggered when a quest is completed for a player.
 *
 * When no quest is referenced, it will trigger for all quests.
 *
 * ## How could this be used?
 * This could be used to show a title or notification to a player when a quest is completed.
 */
class QuestCompleteEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("When not set, it will trigger for all quests.")
    val quest: Ref<QuestEntry> = emptyRef()
) : EventEntry

enum class QuestCompleteEventContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Ref::class)
    QUEST(Ref::class),

    @KeyType(String::class)
    QUEST_DISPLAY_NAME(String::class),
}

@EntryListener(QuestCompleteEventEntry::class)
fun onQuestComplete(event: AsyncQuestStatusUpdate, query: Query<QuestCompleteEventEntry>) {
    if (event.to != QuestStatus.COMPLETED) return

    query.findWhere {
        !it.quest.isSet || it.quest == event.quest
    }.triggerAllFor(event.player) {
        QuestCompleteEventContextKeys.QUEST += event.quest
        QuestCompleteEventContextKeys.QUEST_DISPLAY_NAME += event.quest.get()?.displayName?.get(event.player, context())
            ?: ""
    }
}