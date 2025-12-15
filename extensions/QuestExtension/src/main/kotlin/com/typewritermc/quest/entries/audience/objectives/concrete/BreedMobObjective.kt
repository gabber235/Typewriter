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
import com.typewritermc.quest.entries.ObjectiveAudienceFilter
import com.typewritermc.quest.entries.QuestEntry
import com.typewritermc.quest.entries.interfaces.CachableFactObjective
import com.typewritermc.quest.entries.interfaces.CacheableFactObjectiveProgressTracking
import org.bukkit.entity.EntityType
import org.bukkit.entity.Player
import org.bukkit.event.entity.EntityBreedEvent
import java.util.*

@Entry("breed_mob_objective", "A breed mob objective definition", Colors.BLUE_VIOLET, "mingcute:baby-fill")
/**
 * The `BreedMobObjective` entry is a task that the player can complete by breeding a specific amount of mobs.
 *
 * ## How could this be used?
 * This could be used to create objectives where players need to breed certain mobs.
 */
class BreedMobObjective(
    override val id: String = "",
    override val name: String = "",
    override val quest: Ref<QuestEntry> = emptyRef(),
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val criteria: List<Criteria> = emptyList(),
    @Help("The specific mob type that needs to be bred. If not set, any mob type will count.")
    val mob: Optional<Var<EntityType>> = Optional.empty(),
    @Help("Track the progress of the BreedMobObjective using a fact and set its target value.")
    override val progressTracking: CacheableFactObjectiveProgressTracking = CacheableFactObjectiveProgressTracking(),
    override val display: Var<String> = ConstVar(""),
    override val completionTriggers: List<TriggerableEntry> = emptyList(),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : CachableFactObjective {

    override suspend fun display(): AudienceFilter {
        return ObjectiveAudienceFilter(
            ref(),
            criteria,
        ).listenToEvent(EntityBreedEvent::class) { event ->
            val player = event.breeder as? Player ?: return@listenToEvent

            if (mob.isPresent) {
                val expectedType = mob.get().get(player)
                if (event.entity.type != expectedType) return@listenToEvent
            }

            incrementFact(player, 1)
        }
    }
}