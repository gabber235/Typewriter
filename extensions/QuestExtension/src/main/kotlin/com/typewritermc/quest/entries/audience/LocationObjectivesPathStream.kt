package com.typewritermc.quest.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.descendants
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.quest.trackedShowingObjectives
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.entries.MultiPathStreamDisplay
import com.typewritermc.roadnetwork.entries.PathStreamDisplayEntry
import com.typewritermc.roadnetwork.entries.StreamProducer
import com.typewritermc.roadnetwork.entries.highestPathStreamDisplayEntry

@Entry(
    "location_objectives_path_stream",
    "A Path Stream to tracked Location Objectives",
    Colors.GREEN,
    "material-symbols:conversion-path"
)
/**
 * The `Location Objectives Path Stream` entry is a path stream that shows the path to each tracked location objective.
 * When the player has a location objective, and the quest for the objective is tracked, a path stream will be displayed.
 *
 * ## How could this be used?
 * This could be used to show a path to each location objective in a quest.
 */
class LocationObjectivesPathStream(
    override val id: String = "",
    override val name: String = "",
    val display: Ref<PathStreamDisplayEntry> = emptyRef(),
    val road: Ref<RoadNetworkEntry> = emptyRef(),
) : AudienceEntry {
    private val objectiveDisplays: Map<Ref<LocationObjectiveEntry>, List<Ref<PathStreamDisplayEntry>>> by lazy(
        LazyThreadSafetyMode.NONE
    ) {
        Query.findWhere<LocationObjectiveEntry>() { true }.associate { objective ->
            val displays = mutableListOf<Ref<PathStreamDisplayEntry>>()

            displays.addAll(objective.descendants(PathStreamDisplayEntry::class))
            displays.addAll(objective.quest.descendants(PathStreamDisplayEntry::class))
            displays.add(display)

            objective.ref() to displays
        }
    }

    override suspend fun display(): AudienceDisplay = MultiPathStreamDisplay(road, streams = { player ->
        player.trackedShowingObjectives().filterIsInstance<LocationObjectiveEntry>()
            .map { objective ->
                StreamProducer(
                    objective.id,
                    objectiveDisplays[objective.ref()]?.highestPathStreamDisplayEntry(player) ?: display,
                    endPosition = objective.targetLocation::get
                )
            }.toList()
    })
}