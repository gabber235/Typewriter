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
import java.util.*
import kotlin.reflect.KClass

@Entry(
    "quest_status_update_event",
    "Triggered when a quest status is updated for a player",
    Colors.YELLOW,
    "mdi:notebook-edit"
)
@ContextKeys(QuestStatusUpdateEventContextKeys::class)
/**
 * The `Quest Status Update Event` entry is triggered when a quest status is updated for a player.
 *
 * When no quest is referenced, it will trigger for all quests.
 *
 * ## How could this be used?
 * This could be used to show a title or notification to a player when a quest status is updated.
 */
class QuestStatusUpdateEventEntry(
    override val id: String = "",
    override val name: String = "",
    override val triggers: List<Ref<TriggerableEntry>> = emptyList(),
    @Help("When not set, it will trigger for all quests.")
    val quest: Ref<QuestEntry> = emptyRef(),
    @Help("When not set, it will trigger for all statuses.")
    val from: Optional<QuestStatus> = Optional.empty(),
    val to: QuestStatus = QuestStatus.INACTIVE,
) : EventEntry

enum class QuestStatusUpdateEventContextKeys(override val klass: KClass<*>) : EntryContextKey {
    @KeyType(Ref::class)
    QUEST(Ref::class),

    @KeyType(String::class)
    QUEST_DISPLAY_NAME(String::class),

    @KeyType(QuestStatus::class)
    OLD_STATUS(QuestStatus::class),

    @KeyType(QuestStatus::class)
    NEW_STATUS(QuestStatus::class),
}

@EntryListener(QuestStatusUpdateEventEntry::class)
fun onQuestStatusUpdate(event: AsyncQuestStatusUpdate, query: Query<QuestStatusUpdateEventEntry>) {
    query.findWhere {
        (!it.quest.isSet || it.quest == event.quest) &&
                (!it.from.isPresent || it.from.get() == event.from) &&
                it.to == event.to
    }.triggerAllFor(event.player) {
        QuestStatusUpdateEventContextKeys.QUEST += event.quest
        QuestStatusUpdateEventContextKeys.QUEST_DISPLAY_NAME += event.quest.get()?.displayName?.get(event.player, context())
            ?: ""
        QuestStatusUpdateEventContextKeys.OLD_STATUS += event.from
        QuestStatusUpdateEventContextKeys.NEW_STATUS += event.to
    }
}