package com.typewritermc.quest

import com.typewritermc.core.entries.*
import com.typewritermc.core.extension.annotations.Colored
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.extension.annotations.Placeholder
import com.typewritermc.core.extension.annotations.Tags
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.engine.paper.extensions.placeholderapi.parsePlaceholders
import com.typewritermc.engine.paper.facts.FactListenerSubscription
import com.typewritermc.engine.paper.facts.listenForFacts
import com.typewritermc.engine.paper.snippets.snippet
import com.typewritermc.engine.paper.utils.asMini
import com.typewritermc.engine.paper.utils.asMiniWithResolvers
import com.typewritermc.engine.paper.utils.server
import com.typewritermc.quest.events.AsyncQuestStatusUpdate
import net.kyori.adventure.text.minimessage.tag.resolver.Placeholder.parsed
import org.bukkit.entity.Player
import org.bukkit.event.EventHandler
import java.util.*
import java.util.concurrent.ConcurrentHashMap

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

        return text.asMiniWithResolvers(parsed("display", display)).asMini().parsePlaceholders(player)
    }

    override fun parser(): PlaceholderParser = placeholderParser {
        supply { player -> display(player) }
    }
}


class ObjectiveAudienceFilter(
    private val objective: Ref<ObjectiveEntry>,
    private val criteria: List<Criteria>,
) : AudienceFilter(objective) {
    private val factWatcherSubscriptions = ConcurrentHashMap<UUID, FactListenerSubscription>()

    override fun filter(player: Player): Boolean =
        criteria.matches(player)

    override fun onPlayerAdd(player: Player) {
        factWatcherSubscriptions.compute(player.uniqueId) { _, subscription ->
            subscription?.cancel(player)
            return@compute player.listenForFacts(
                (criteria).map { it.fact },
                ::onFactChange,
            )
        }

        super.onPlayerAdd(player)
    }

    private fun onFactChange(player: Player, fact: Ref<ReadableFactEntry>) {
        player.refresh()
    }

    override fun onPlayerRemove(player: Player) {
        super.onPlayerRemove(player)
        factWatcherSubscriptions.remove(player.uniqueId)?.cancel(player)
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
        // If the player has a tracked quest, we only want to override it if the new quest has a higher priority.
        val highestObjectivePriority = player.trackedShowingObjectives().maxOfOrNull { it.priority } ?: 0
        if (objective.priority < highestObjectivePriority) {
            return
        }

        player.trackQuest(quest)
    }

    override fun dispose() {
        super.dispose()
        factWatcherSubscriptions.forEach { (playerId, subscription) ->
            val player = server.getPlayer(playerId) ?: return@forEach
            subscription.cancel(player)
        }
    }
}

interface LocatableObjective : ObjectiveEntry {
    fun positions(player: Player?): List<Position>
}


fun Player.trackedShowingObjectives() = trackedQuest()?.let { questShowingObjectives(it) } ?: emptySequence()

fun Player.questShowingObjectives(quest: Ref<QuestEntry>) = Query.findWhere<ObjectiveEntry> { objectiveEntry ->
    objectiveEntry.quest == quest && inAudience(objectiveEntry.ref())
}