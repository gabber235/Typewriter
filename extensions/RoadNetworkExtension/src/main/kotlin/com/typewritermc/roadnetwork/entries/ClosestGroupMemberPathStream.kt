package com.typewritermc.roadnetwork.entries

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.GroupEntry
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.gps.PathStreamDisplay

@Entry(
    "closest_group_member_path_stream",
    "A Path Stream to the Closest Group Member",
    Colors.GREEN,
    "material-symbols:conversion-path"
)
/**
 * The `Closest Group Member Path Stream` entry is a path stream that shows the path to the closest group member.
 * The 'Closest Group Member' is determined by the group member that is closest to the player geographically,
 * **Not based on the path distance.**
 *
 * When the group is not set, the path stream will not display anything.
 * Players must be in the same world for the path stream to consider them.
 *
 * ## How could this be used?
 * This could be used to show a path to the closest group member in a group of players.
 * When a player is lost, they can follow the path to the closest group member.
 */
class ClosestGroupMemberPathStream(
    override val id: String = "",
    override val name: String = "",
    val road: Ref<RoadNetworkEntry> = emptyRef(),
    val group: Ref<out GroupEntry> = emptyRef(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay = PathStreamDisplay(road) { player ->
        group.get()?.group(player)?.players
            ?.asSequence()
            ?.filter { it != player }
            ?.filter { player.world == it.world }
            ?.minByOrNull { it.location.distanceSquared(player.location) }
            ?.location
            ?: player.location
    }
}