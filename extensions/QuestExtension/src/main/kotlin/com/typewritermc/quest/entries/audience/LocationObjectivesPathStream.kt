package com.typewritermc.quest.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.utils.toBukkitLocation
import com.typewritermc.quest.trackedShowingObjectives
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.gps.MultiPathStreamDisplay

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
    val road: Ref<RoadNetworkEntry> = emptyRef(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = MultiPathStreamDisplay(road, endLocations = { player ->
        player.trackedShowingObjectives().filterIsInstance<LocationObjectiveEntry>()
            .map { it.targetLocation.get(player).toBukkitLocation() }.toList()
    })
}