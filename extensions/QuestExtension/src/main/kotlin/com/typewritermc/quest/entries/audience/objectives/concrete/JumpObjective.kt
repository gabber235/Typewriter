package com.typewritermc.quest.entries.audience.objectives.concrete

import com.destroystokyo.paper.event.player.PlayerJumpEvent
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
import java.util.*

@Entry("jump_objective", "A jump objective definition", Colors.BLUE_VIOLET, "game-icons:jump-across")
/**
 * The `JumpObjective` entry is a task that the player can complete by jumping a specific amount of times.
 *
 * ## How could this be used?
 * This could be used to create objectives where players need to jump, such as "Jump 10 times" as a tutorial
 * step teaching the jump control, or as part of a parkour course.
 */
class JumpObjective(
    override val id: String = "",
    override val name: String = "",
    override val quest: Ref<QuestEntry> = emptyRef(),
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val criteria: List<Criteria> = emptyList(),
    @Help("Track the progress of the JumpObjective using a fact and set its target value.")
    override val progressTracking: CacheableFactObjectiveProgressTracking = CacheableFactObjectiveProgressTracking(),
    override val display: Var<String> = ConstVar(""),
    override val completionTriggers: List<Ref<TriggerableEntry>> = emptyList(),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : CachableFactObjective {

    override suspend fun display(): AudienceFilter {
        return ObjectiveAudienceFilter(
            ref(),
            criteria,
        ).listenToEvent(PlayerJumpEvent::class) { event ->
            // A cancelled jump never happens, so it must not count.
            if (event.isCancelled) return@listenToEvent

            incrementFact(event.player, 1)
        }
    }
}
