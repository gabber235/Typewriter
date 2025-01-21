package com.typewritermc.roadnetwork.entries

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.utils.point.Position
import com.typewritermc.engine.paper.entry.entries.*
import com.typewritermc.roadnetwork.gps.PathStreamDisplay
import com.typewritermc.engine.paper.utils.toBukkitLocation
import com.typewritermc.roadnetwork.RoadNetworkEntry

@Entry(
    "direct_location_path_stream",
    "A Path Stream to a Direct Location",
    Colors.GREEN,
    "material-symbols:conversion-path"
)
/**
 * The `Direct Location Path Stream` entry is a path stream that shows the path to a specific location.
 * When the player has this entry, a path stream will be displayed to the specified location.
 *
 * ## How could this be used?
 * This could be used to show a path to a specific location in the world.
 */
class DirectLocationPathStream(
    override val id: String = "",
    override val name: String = "",
    val road: Ref<RoadNetworkEntry> = emptyRef(),
    val targetLocation: Var<Position> = ConstVar(Position.ORIGIN),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = PathStreamDisplay(road, endLocation = { targetLocation.get(it).toBukkitLocation() })
}