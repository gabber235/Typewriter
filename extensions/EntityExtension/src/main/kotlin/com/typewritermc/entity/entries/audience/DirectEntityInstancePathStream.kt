package com.typewritermc.entity.entries.audience

import com.typewritermc.core.books.pages.Colors
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
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.position
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.entries.PathStreamDisplayEntry
import com.typewritermc.roadnetwork.entries.SinglePathStreamDisplay
import com.typewritermc.roadnetwork.entries.highestPathStreamDisplayEntry

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
    val display: Ref<PathStreamDisplayEntry> = emptyRef(),
    val target: Ref<EntityInstanceEntry> = emptyRef(),
) : AudienceEntry {
    // As displays and references can't change (except between reloads) we can just cache all relevant ones here for quick access.
    private val pathStreamDisplays: List<Ref<PathStreamDisplayEntry>> by lazy(LazyThreadSafetyMode.NONE) {
        target.descendants(PathStreamDisplayEntry::class) + display
    }

    // As displays and references can't change (except between reloads) we can just cache all relevant ones here for quick access.
    private val entityDisplay: AudienceEntityDisplay? by lazy(LazyThreadSafetyMode.NONE) {
        val entityDisplay = target.findDisplay<AudienceEntityDisplay>()
        if (entityDisplay == null) {
            logger.warning("Could not find target entity instance $target to show path stream ${ref()}")
            return@lazy null
        }
        return@lazy entityDisplay
    }

    override suspend fun display(): AudienceDisplay {
        return SinglePathStreamDisplay(
            road,
            { pathStreamDisplays.highestPathStreamDisplayEntry(it) ?: display },
            endPosition = { entityDisplay?.position(it.uniqueId) ?: it.position },
        )
    }
}