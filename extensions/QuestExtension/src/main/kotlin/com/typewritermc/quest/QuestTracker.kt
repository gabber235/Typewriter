package com.typewritermc.quest

import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Factory
import com.typewritermc.core.extension.annotations.Parameter
import com.typewritermc.core.interaction.SessionTracker
import com.typewritermc.engine.paper.facts.FactListenerSubscription
import com.typewritermc.engine.paper.facts.listenForFacts
import com.typewritermc.engine.paper.interaction.PlayerSessionManager
import com.typewritermc.engine.paper.utils.ThreadType.DISPATCHERS_ASYNC
import com.typewritermc.quest.events.AsyncQuestStatusUpdate
import com.typewritermc.quest.events.AsyncTrackedQuestUpdate
import org.bukkit.entity.Player
import org.koin.java.KoinJavaComponent.get
import java.util.concurrent.ConcurrentHashMap

@Factory
class QuestTracker(
    @Parameter
    val player: Player,
) : SessionTracker {
    private val quests = ConcurrentHashMap<Ref<QuestEntry>, QuestStatus>()
    private var trackedQuest: Ref<QuestEntry>? = null

    private var factWatchSubscription: FactListenerSubscription? = null

    override fun setup() {
        Query.find<QuestEntry>().forEach { refresh(it.ref()) }

        refreshWatchedFacts()
    }

    private fun refreshWatchedFacts() {
        factWatchSubscription?.cancel(player)
        val facts = Query.find<QuestEntry>().flatMap { it.facts }.toList()
        factWatchSubscription = player.listenForFacts(
            facts,
            listener = { _, ref ->
                Query.findWhere<QuestEntry> { quest ->
                    quest.facts.contains(ref)
                }.forEach {
                    refresh(it.ref())
                }
            }
        )
    }

    override fun tick() {
        Query.find<QuestEntry>().forEach { refresh(it.ref()) }
    }

    override fun teardown() {
        factWatchSubscription?.cancel(player)
    }

    private fun refresh(ref: Ref<QuestEntry>) {
        val quest = ref.get() ?: return
        val status = quest.questStatus(player)

        val oldStatus = quests[ref]
        quests[ref] = status
        if (oldStatus == status) return

        if (oldStatus != QuestStatus.ACTIVE && status == QuestStatus.ACTIVE) {
            // We always want to track the quest if it becomes active
            // Even if the previous quest priority was higher
            // Because this is responding to the player's action more accurately
            trackQuest(ref)
        }

        if (oldStatus == null) return
        DISPATCHERS_ASYNC.launch {
            AsyncQuestStatusUpdate(player, ref, oldStatus, status).callEvent()

            if (trackedQuest == ref && status != QuestStatus.ACTIVE) {
                unTrackQuest()
            }
        }
    }

    fun inactiveQuests() = quests.filterValues { it == QuestStatus.INACTIVE }.keys.toList()
    fun activeQuests() = quests.filterValues { it == QuestStatus.ACTIVE }.keys.toList()
    fun completedQuests() = quests.filterValues { it == QuestStatus.COMPLETED }.keys.toList()
    fun isQuestInactive(quest: Ref<QuestEntry>) = quests[quest] == QuestStatus.INACTIVE
    fun isQuestActive(quest: Ref<QuestEntry>) = quests[quest] == QuestStatus.ACTIVE
    fun isQuestCompleted(quest: Ref<QuestEntry>) = quests[quest] == QuestStatus.COMPLETED
    fun trackedQuest() = trackedQuest

    fun trackQuest(quest: Ref<QuestEntry>) {
        val from = trackedQuest
        trackedQuest = quest
        DISPATCHERS_ASYNC.launch {
            AsyncTrackedQuestUpdate(player, from, quest).callEvent()
        }
    }

    fun unTrackQuest() {
        val from = trackedQuest
        trackedQuest = null
        DISPATCHERS_ASYNC.launch {
            AsyncTrackedQuestUpdate(player, from, null).callEvent()
        }
    }

    companion object {
        @JvmStatic
        fun inactiveQuests(player: Player) = player.inactiveQuests()

        @JvmStatic
        fun activeQuests(player: Player) = player.activeQuests()

        @JvmStatic
        fun completedQuests(player: Player) = player.completedQuests()

        @JvmStatic
        fun isQuestInactive(player: Player, quest: Ref<QuestEntry>) = player isQuestInactive quest

        @JvmStatic
        fun isQuestActive(player: Player, quest: Ref<QuestEntry>) = player isQuestActive quest

        @JvmStatic
        fun isQuestCompleted(player: Player, quest: Ref<QuestEntry>) = player isQuestCompleted quest

        @JvmStatic
        fun trackedQuest(player: Player) = player.trackedQuest()

        @JvmStatic
        fun isQuestTracked(player: Player, quest: Ref<QuestEntry>) = player isQuestTracked quest

        @JvmStatic
        fun trackQuest(player: Player, quest: Ref<QuestEntry>) = player trackQuest quest

        @JvmStatic
        fun unTrackQuest(player: Player) = player.unTrackQuest()
    }
}

enum class QuestStatus {
    INACTIVE,
    ACTIVE,
    COMPLETED
}

private val Player.tracker: QuestTracker?
    get() = with(get<PlayerSessionManager>(PlayerSessionManager::class.java)) {
        session?.tracker(QuestTracker::class)
    }

fun Player.inactiveQuests() = tracker?.inactiveQuests() ?: emptyList()
fun Player.activeQuests() = tracker?.activeQuests() ?: emptyList()
fun Player.completedQuests() = tracker?.completedQuests() ?: emptyList()
infix fun Player.isQuestInactive(quest: Ref<QuestEntry>) = tracker?.isQuestInactive(quest) ?: true
infix fun Player.isQuestActive(quest: Ref<QuestEntry>) = tracker?.isQuestActive(quest) ?: false
infix fun Player.isQuestCompleted(quest: Ref<QuestEntry>) = tracker?.isQuestCompleted(quest) ?: false
fun Player.trackedQuest() = tracker?.trackedQuest()
infix fun Player.isQuestTracked(quest: Ref<QuestEntry>): Boolean {
    val trackedQuest = trackedQuest()
    if (!quest.isSet) return trackedQuest != null
    return trackedQuest == quest
}

infix fun Player.trackQuest(quest: Ref<QuestEntry>) = tracker?.trackQuest(quest)
fun Player.unTrackQuest() = tracker?.unTrackQuest()

