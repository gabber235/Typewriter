package com.typewritermc.quest.entries.audience.objectives.concrete

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.Criteria
import com.typewritermc.engine.paper.entry.TriggerableEntry
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.AudienceFilter
import com.typewritermc.engine.paper.entry.entries.ConstVar
import com.typewritermc.engine.paper.entry.entries.Var
import com.typewritermc.engine.paper.utils.item.Item
import com.typewritermc.quest.entries.ObjectiveAudienceFilter
import com.typewritermc.quest.entries.QuestEntry
import com.typewritermc.quest.entries.interfaces.CachableFactObjective
import com.typewritermc.quest.entries.interfaces.CacheableFactObjectiveProgressTracking
import org.bukkit.event.player.PlayerFishEvent
import java.util.*

@Entry("fish_objective", "A fish objective definition", Colors.BLUE_VIOLET, "icon-park-outline:fishing")
/**
 * The `FishObjective` entry is a task that the player can complete by fishing a specific amount of fish or item.
 *
 * ## How could this be used?
 * This could be used to create objectives where players need to fish certain fish or item.
 */
class FishObjective(
    override val id: String = "",
    override val name: String = "",
    override val quest: Ref<QuestEntry> = emptyRef(),
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val criteria: List<Criteria> = emptyList(),
    @Help("The specific fish or item type that needs to be fished. If not set, any fish or item type will count.")
    val caught: Optional<Var<Item>> = Optional.empty(),
    @Help("Track the progress of the FishObjective using a fact and set its target value.")
    override val progressTracking: CacheableFactObjectiveProgressTracking = CacheableFactObjectiveProgressTracking(),
    override val display: Var<String> = ConstVar("<value>/<target>"),
    override val completionTriggers: List<TriggerableEntry> = emptyList(),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : CachableFactObjective {

    override suspend fun display(): AudienceFilter {
        return ObjectiveAudienceFilter(
            ref(),
            criteria,
        ).listenToEvent(PlayerFishEvent::class) { event ->
            if (event.state != PlayerFishEvent.State.CAUGHT_FISH) return@listenToEvent

            if (caught.isPresent) {
                val caughtItem = event.caught as? org.bukkit.entity.Item ?: return@listenToEvent
                val expectedType = caught.get().get(event.player)
                if (!expectedType.isSameAs(event.player, caughtItem.itemStack)) return@listenToEvent
            }

            incrementFact(event.player, 1)
        }
    }
}