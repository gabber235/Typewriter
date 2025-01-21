package com.typewritermc.entity.entries.audience

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.*
import com.typewritermc.engine.paper.entry.entity.ActivityEntityDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.EntityInstanceEntry
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.gps.PathStreamDisplay
import com.typewritermc.engine.paper.utils.toBukkitLocation
import org.koin.java.KoinJavaComponent

@Entry(
    "direct_entity_instance_path_stream",
    "A Path Stream to a Direct Entity Instance",
    Colors.GREEN,
    "material-symbols:conversion-path"
)
/**
 * The `Direct Entity Instance Path Stream` entry is a path stream that shows the path to a specific entity instance.
 * When the player has this entry, a path stream will be displayed to the specified entity instance.
 *
 * ## How could this be used?
 * This could be used to show a path to a specific entity instance in the world.
 */
class DirectEntityInstancePathStream(
    override val id: String = "",
    override val name: String = "",
    val road: Ref<RoadNetworkEntry> = emptyRef(),
    val target: Ref<EntityInstanceEntry> = emptyRef(),
) : AudienceEntry {
    override suspend fun display(): AudienceDisplay {
        val manager = KoinJavaComponent.get<AudienceManager>(AudienceManager::class.java)
        val entityDisplay = manager[target] as? ActivityEntityDisplay
        return PathStreamDisplay(road, endLocation = { entityDisplay?.position(it.uniqueId)?.toBukkitLocation() ?: it.location })
    }
}