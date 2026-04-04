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
import com.typewritermc.quest.entries.interfaces.LocatableObjective
import com.typewritermc.quest.entries.trackedShowingObjectives
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.entries.MultiPathStreamDisplay
import com.typewritermc.roadnetwork.entries.PathStreamDisplayEntry
import com.typewritermc.roadnetwork.entries.highestPathStreamDisplayEntry

@Entry(
    "locatable_objectives_path_stream",
    "Unified automatic path stream to any tracked locatable objective",
    Colors.GREEN,
    "material-symbols:conversion-path"
)
/**
 * The `Locatable Objectives Path Stream` entry is a path stream that shows the path to each tracked locatable objective.
 * When the player has a locatable objective, like `LocationObjective` or `InteractEntityObjective`, and the quest for the objective is tracked, a path stream will be displayed.
 *
 * ## How could this be used?
 * This could be used to show a path to each locatable objective in a quest.
 */
class LocatableObjectivesPathStream(
    override val id: String = "",
    override val name: String = "",
    val display: Ref<PathStreamDisplayEntry> = emptyRef(),
    val road: Ref<RoadNetworkEntry> = emptyRef(),
) : AudienceEntry {
    // As displays and references can't change (except between reloads) we can just cache all relevant ones here for quick access.
    private val objectiveDisplays: Map<Ref<LocatableObjective>, List<Ref<PathStreamDisplayEntry>>> by lazy(
        LazyThreadSafetyMode.NONE
    ) {
        Query.findWhere<LocatableObjective>() { true }.associate { objective ->
            val displays = mutableListOf<Ref<PathStreamDisplayEntry>>()

            displays.addAll(objective.descendants(PathStreamDisplayEntry::class))
            displays.addAll(objective.quest.descendants(PathStreamDisplayEntry::class))
            displays.add(display)

            objective.ref() to displays
        }
    }

    override suspend fun display(): AudienceDisplay = MultiPathStreamDisplay(road, streams = { player ->
        player.trackedShowingObjectives().filterIsInstance<LocatableObjective>()
            .flatMap { objective ->
                objective.streamProducers(
                    player,
                    objectiveDisplays[objective.ref()]?.highestPathStreamDisplayEntry(player) ?: display
                )
            }.toList()
    })
}