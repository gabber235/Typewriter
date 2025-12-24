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
import org.bukkit.event.player.PlayerShearEntityEvent
import java.util.*

@Entry("shear_entity_objective", "A shear entity objective definition", Colors.BLUE_VIOLET, "mdi:sheep")
/**
 * The `ShearEntityObjective` entry is a task that the player can complete by shearing a specific amount of entities.
 *
 * ## How could this be used?
 * This could be used to create objectives where players need to shear certain entities.
 */
class ShearEntityObjective(
    override val id: String = "",
    override val name: String = "",
    override val quest: Ref<QuestEntry> = emptyRef(),
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val criteria: List<Criteria> = emptyList(),
    @Help("The specific entity type that needs to be sheared. If not set, any entity type will count.")
    val entity: Optional<Var<EntityType>> = Optional.empty(),
    @Help("Track the progress of the ShearEntityObjective using a fact and set its target value.")
    override val progressTracking: CacheableFactObjectiveProgressTracking = CacheableFactObjectiveProgressTracking(),
    override val display: Var<String> = ConstVar(""),
    override val completionTriggers: List<TriggerableEntry> = emptyList(),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : CachableFactObjective {

    override suspend fun display(): AudienceFilter {
        return ObjectiveAudienceFilter(
            ref(),
            criteria,
        ).listenToEvent(PlayerShearEntityEvent::class) { event ->
            if (entity.isPresent) {
                val expectedType = entity.get().get(event.player)
                if (event.entity.type != expectedType) return@listenToEvent
            }

            incrementFact(event.player, 1)
        }
    }
}