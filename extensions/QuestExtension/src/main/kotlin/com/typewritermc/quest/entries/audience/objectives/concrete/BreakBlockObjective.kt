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
import org.bukkit.Material
import org.bukkit.event.block.BlockBreakEvent
import java.util.*

@Entry("break_block_objective", "A break block objective definition", Colors.BLUE_VIOLET, "mdi:pickaxe")
/**
 * The `BreakBlockObjective` entry is a task that the player can complete by breaking a specific amount of blocks.
 *
 * ## How could this be used?
 * This could be used to create objectives where players need to break certain blocks.
 */
class BreakBlockObjective(
    override val id: String = "",
    override val name: String = "",
    override val quest: Ref<QuestEntry> = emptyRef(),
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val criteria: List<Criteria> = emptyList(),
    @Help("The specific block type that needs to be broken. If not set, any block type will count.")
    val block: Optional<Var<Material>> = Optional.empty(),
    @Help("Track the progress of the BreakBlockObjective using a fact and set its target value.")
    override val progressTracking: CacheableFactObjectiveProgressTracking = CacheableFactObjectiveProgressTracking(),
    override val display: Var<String> = ConstVar(""),
    override val completionTriggers: List<TriggerableEntry> = emptyList(),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : CachableFactObjective {

    override suspend fun display(): AudienceFilter {
        return ObjectiveAudienceFilter(
            ref(),
            criteria,
        ).listenToEvent(BlockBreakEvent::class) { event ->
            if (block.isPresent) {
                val expectedType = block.get().get(event.player)
                if (event.block.type != expectedType) return@listenToEvent
            }

            incrementFact(event.player, 1)
        }
    }
}