package com.typewritermc.quest.entries

import com.typewritermc.core.entries.*
import com.typewritermc.core.extension.annotations.Colored
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.plugin
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.replaceTagPlaceholders
import com.typewritermc.quest.*
import com.typewritermc.quest.events.AsyncQuestStatusUpdate
import lirand.api.extensions.events.listen
import org.bukkit.entity.Player
import org.bukkit.event.Event
import org.bukkit.event.EventHandler
import org.bukkit.event.player.PlayerEvent
import kotlin.reflect.KClass

@Tags("quest")
interface QuestEntry : AudienceFilterEntry, PlaceholderEntry {
    @Help("The name to display to the player.")
    @Colored
    @Placeholder
    val displayName: Var<String>

    val facts: List<Ref<ReadableFactEntry>> get() = emptyList()
    fun questStatus(player: Player): QuestStatus

    fun display(player: Player): String {
        return displayName.get(player).parsePlaceholders(player)
    }

    override fun parser(): PlaceholderParser = placeholderParser {
        supplyPlayer { player -> display(player) }
    }

    override suspend fun display(): AudienceFilter = QuestAudienceFilter(
        ref()
    )
}

class QuestAudienceFilter(
    private val quest: Ref<QuestEntry>
) : AudienceFilter(quest) {
    override fun filter(player: Player): Boolean = player isQuestActive quest

    @EventHandler
    fun onQuestStatusUpdate(event: AsyncQuestStatusUpdate) {
        if (event.quest != quest) return
        event.player.updateFilter(event.to == QuestStatus.ACTIVE)
    }
}

val inactiveObjectiveDisplay by snippet("quest.objective.inactive", "<gray><display></gray>")
val showingObjectiveDisplay by snippet("quest.objective.showing", "<white><display></white>")

@Tags("objective")
interface ObjectiveEntry : AudienceFilterEntry, PlaceholderEntry, PriorityEntry {
    @Help("The quest that the objective is a part of.")
    val quest: Ref<QuestEntry>

    @Help("The criteria need to be met for the objective to be able to be shown.")
    val criteria: List<Criteria>

    @Help("The name to display to the player.")
    @Colored
    @Placeholder
    val display: Var<String>

    override suspend fun display(): AudienceFilter {
        return ObjectiveAudienceFilter(
            ref(),
            criteria,
        )
    }

    fun display(player: Player?): String {
        val text = when {
            player == null -> inactiveObjectiveDisplay
            criteria.matches(player) -> showingObjectiveDisplay
            else -> inactiveObjectiveDisplay
        }
        val display = display.get(player) ?: ""

        return text.replaceTagPlaceholders("display", display).parsePlaceholders(player)
    }

    override fun parser(): PlaceholderParser = placeholderParser {
        supply { player -> display(player) }
    }
}


class ObjectiveAudienceFilter(
    private val objective: Ref<ObjectiveEntry>,
    private val criteria: List<Criteria>,
) : AudienceFilter(objective), TickableDisplay {
    private val listenersCallbacks = mutableMapOf<KClass<Event>, (Event) -> Unit>()

    // TODO: This should probably be moved later on to the AudienceDisplay.
    fun <E : Event> listenToEvent(klass: KClass<E>, callback: (E) -> Unit): ObjectiveAudienceFilter {
        @Suppress("UNCHECKED_CAST", "ReplacePutWithAssignment")
        listenersCallbacks.put(klass as KClass<Event>) { event ->
            if (event is PlayerEvent) {
                val player = event.player
                if (player !in this) {
                    return@put
                }
            }
            if (klass.isInstance(event)) {
                callback(event as E)
            }
        }
        return this
    }

    override fun initialize() {
        super.initialize()
        for (callback in listenersCallbacks) {
            listen(plugin, callback.key, block = callback.value)
        }
    }

    override fun filter(player: Player): Boolean =
        criteria.matches(player)

    override fun tick() {
        consideredPlayers.forEach { it.refresh() }
    }

    override fun onPlayerFilterAdded(player: Player) {
        super.onPlayerFilterAdded(player)
        val quest = objective.get()?.quest ?: return

        if (!player.isQuestActive(quest)) {
            return
        }

        if (player.trackedQuest() == null) {
            player.trackQuest(quest)
            return
        }
        // If the player has a tracked quest, we only want to override it if the new quest has a higher or equal priority.
        val highestQuestPriority = player.activeQuests().maxByOrNull { it.priority } ?: return
        if (quest.priority < highestQuestPriority.priority) return

        player.trackQuest(quest)
    }
}

fun Player.trackedShowingObjectives() = trackedQuest()?.let { questShowingObjectives(it) } ?: emptySequence()

fun Player.questShowingObjectives(quest: Ref<QuestEntry>) = Query.findWhere<ObjectiveEntry> { objectiveEntry ->
    objectiveEntry.quest == quest && inAudience(objectiveEntry.ref())
}