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
import org.bukkit.event.player.PlayerMoveEvent
import org.bukkit.event.player.PlayerTeleportEvent
import java.util.Optional

enum class TravelType {
    /** Any ground movement that is not sprinting, sneaking, swimming, flying, or gliding. */
    WALK,
    SPRINT,
    SNEAK,
    SWIM,
    FLY,
    GLIDE,
}

@Entry("travel_objective", "A travel distance objective definition", Colors.BLUE_VIOLET, "fa6-solid:person-walking")
/**
 * The `TravelObjective` entry is a task that the player can complete by travelling a specific distance in blocks.
 *
 * ## How could this be used?
 * This could be used to create objectives where players need to walk, sprint, swim, or fly a set number of blocks,
 * such as "Walk 200 blocks" or "Swim 50 blocks across the river".
 */
class TravelObjective(
    override val id: String = "",
    override val name: String = "",
    override val quest: Ref<QuestEntry> = emptyRef(),
    override val children: List<Ref<AudienceEntry>> = emptyList(),
    override val criteria: List<Criteria> = emptyList(),
    @Help("The movement types to track. If empty, any movement (walk, sprint, swim, fly, etc.) will count.")
    val movementTypes: List<TravelType> = emptyList(),
    @Help("Track the progress of the TravelObjective using a fact and set its target value.")
    override val progressTracking: CacheableFactObjectiveProgressTracking = CacheableFactObjectiveProgressTracking(),
    override val display: Var<String> = ConstVar(""),
    override val completionTriggers: List<Ref<TriggerableEntry>> = emptyList(),
    override val priorityOverride: Optional<Int> = Optional.empty(),
) : CachableFactObjective {

    override suspend fun display(): AudienceFilter {
        return ObjectiveAudienceFilter(
            ref(),
            criteria,
        ).listenToEvent(PlayerMoveEvent::class) { event ->
            // Teleports must not count as travelled distance.
            if (event is PlayerTeleportEvent) return@listenToEvent
            if (!event.hasChangedBlock()) return@listenToEvent

            if (movementTypes.isNotEmpty()) {
                val active = when {
                    event.player.isGliding -> TravelType.GLIDE
                    event.player.isFlying -> TravelType.FLY
                    event.player.isSwimming -> TravelType.SWIM
                    event.player.isSneaking -> TravelType.SNEAK
                    event.player.isSprinting -> TravelType.SPRINT
                    else -> TravelType.WALK
                }
                if (active !in movementTypes) return@listenToEvent
            }

            val blocks = event.from.distance(event.to).toInt().coerceAtLeast(1)
            incrementFact(event.player, blocks)
        }
    }
}
