package com.typewritermc.entity.entries.quest

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.descendants
import com.typewritermc.engine.paper.entry.entity.AudienceEntityDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.EntityInstanceEntry
import com.typewritermc.engine.paper.entry.findDisplay
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.quest.trackedShowingObjectives
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.entries.MultiPathStreamDisplay
import com.typewritermc.roadnetwork.entries.PathStreamDisplayEntry
import com.typewritermc.roadnetwork.entries.StreamProducer
import com.typewritermc.roadnetwork.entries.highestPathStreamDisplayEntry

@Entry(
    "interact_entity_objectives_path_stream",
    "A Path Stream to Interact Entity Objectives",
    Colors.GREEN,
    "material-symbols:conversion-path"
)
/**
 * The `Interact Entity Objectives Path Stream` entry is a path stream that shows the path to each interact entity objective.
 * When the player has an interact entity objective, and the quest for the objective is tracked, a path stream will be displayed.
 *
 * The `Ignore Instances` field is a list of entity instances that should be ignored when showing the path.
 *
 * ## How could this be used?
 * This could be used to show a path to each interacting entity objective in a quest.
 */
class InteractEntityObjectivesPathStream(
    override val id: String = "",
    override val name: String = "",
    val road: Ref<RoadNetworkEntry> = emptyRef(),
    val display: Ref<PathStreamDisplayEntry> = emptyRef(),
    val ignoreInstances: List<Ref<EntityInstanceEntry>> = emptyList(),
) : AudienceEntry {
    private val displays by lazy(LazyThreadSafetyMode.NONE) {
        // As displays and references can't change (except between reloads) we can just cache all relevant ones here for quick access.
        Query.findWhere<EntityInstanceEntry> { it.ref() !in ignoreInstances }
            .groupBy { it.definition }
            .mapValues { (_, value) ->
                value
                    .mapNotNull { it.ref().findDisplay<AudienceEntityDisplay>() }
            }
    }

    private val objectiveDisplays: Map<Ref<InteractEntityObjective>, List<Ref<PathStreamDisplayEntry>>> by lazy(
        LazyThreadSafetyMode.NONE
    ) {
        Query.findWhere<InteractEntityObjective>() { it.entity in displays.keys }.associate { objective ->
            val displays = mutableListOf<Ref<PathStreamDisplayEntry>>()

            displays.addAll(objective.descendants(PathStreamDisplayEntry::class))
            displays.addAll(objective.quest.descendants(PathStreamDisplayEntry::class))
            this.displays[objective.entity]?.map { it.instanceEntryRef }?.descendants(PathStreamDisplayEntry::class)
                ?.let {
                    displays.addAll(it)
                }
            displays.add(display)

            objective.ref() to displays
        }
    }

    override suspend fun display(): AudienceDisplay {
        return MultiPathStreamDisplay(road, streams = { player ->
            val streams = mutableListOf<StreamProducer>()
            val entityObjectives = player.trackedShowingObjectives().filterIsInstance<InteractEntityObjective>()

            for (objective in entityObjectives) {
                val entity = objective.entity
                val displays = displays[entity] ?: continue

                for (entityDisplay in displays) {
                    if (!entityDisplay.canView(player.uniqueId)) continue
                    streams.add(
                        StreamProducer(
                            entityDisplay.instanceEntryRef.id,
                            objectiveDisplays[objective.ref()]?.highestPathStreamDisplayEntry(player) ?: display,
                            endPosition = { entityDisplay.position(it.uniqueId) ?: it.position }
                        ),
                    )
                }
            }
            streams
        })
    }
}