package com.typewritermc.entity.entries.quest

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Query
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.entries.ref
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.AudienceManager
import com.typewritermc.engine.paper.entry.entity.AudienceEntityDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceDisplay
import com.typewritermc.engine.paper.entry.entries.AudienceEntry
import com.typewritermc.engine.paper.entry.entries.EntityInstanceEntry
import com.typewritermc.engine.paper.entry.findDisplay
import com.typewritermc.engine.paper.utils.toBukkitLocation
import com.typewritermc.quest.trackedShowingObjectives
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.gps.MultiPathStreamDisplay
import org.koin.java.KoinJavaComponent

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
    val ignoreInstances: List<Ref<EntityInstanceEntry>> = emptyList(),
) : AudienceEntry {
    private val displays by lazy(LazyThreadSafetyMode.NONE) {
        val manager = KoinJavaComponent.get<AudienceManager>(AudienceManager::class.java)
        // As displays and references can't change (except between reloads) we can just cache all relevant ones here for quick access.
        Query.findWhere<EntityInstanceEntry> { it.ref() !in ignoreInstances }
            .groupBy { it.definition }
            .mapValues { (_, value) ->
                value
                    .mapNotNull { it.ref().findDisplay<AudienceEntityDisplay>() }
            }
    }

    override suspend fun display(): AudienceDisplay {
        return MultiPathStreamDisplay(road, endLocations = { player ->
            player.trackedShowingObjectives()
                .filterIsInstance<InteractEntityObjective>()
                .map { it.entity }
                .flatMap { displays[it]?.asSequence() ?: emptySequence() }
                .filter { it.canView(player.uniqueId) }
                .mapNotNull { it.position(player.uniqueId)?.toBukkitLocation() }
                .toList()
        })
    }
}