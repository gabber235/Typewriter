package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.engine.paper.utils.distanceSqrt
import com.typewritermc.engine.paper.utils.toBukkitLocation
import com.typewritermc.roadnetwork.*
import com.typewritermc.roadnetwork.gps.PointToPointGPS
import org.koin.core.component.KoinComponent
import org.koin.java.KoinJavaComponent


@Entry("patrol_activity", "Moving around a set of locations", Colors.BLUE, "fa6-solid:route")
/**
 * The `PatrolActivity` is an activity that makes the entity move around a set of locations.
 * The entity will move to each location in the set in order.
 * Once the entity reaches the last location, it will start back at the first location.
 *
 * ## How could this be used?
 * This could be used to make guards patrol around a set of locations.
 */
class PatrolActivityEntry(
    override val id: String = "",
    override val name: String = "",
    override val roadNetwork: Ref<RoadNetworkEntry> = emptyRef(),
    override val nodes: List<RoadNodeId> = emptyList(),
) : GenericEntityActivityEntry, RoadNodeCollectionEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<ActivityContext> {
        if (nodes.isEmpty()) return IdleActivity.create(context, currentLocation)
        return PatrolActivity(roadNetwork, nodes, currentLocation) { nodes, index ->
            (index + 1) % nodes.size
        }
    }
}

class PatrolActivity(
    private val roadNetwork: Ref<RoadNetworkEntry>,
    private val nodes: List<RoadNodeId>,
    private val startLocation: PositionProperty,
    private val nextNodeIndexFetcher: (List<RoadNodeId>, Int) -> Int,
) : EntityActivity<ActivityContext>, KoinComponent {
    private var currentLocationIndex = 0
    private var activity: EntityActivity<in ActivityContext>? = null

    fun refreshActivity(context: ActivityContext, network: RoadNetwork) {
        val targetNodeId = nodes.getOrNull(currentLocationIndex)
            ?: return
        val targetNode = network.nodes.find { it.id == targetNodeId }
            ?: return

        activity?.dispose(context)
        activity = NavigationActivity(
            PointToPointGPS(
                roadNetwork,
                { currentPosition.toBukkitLocation() }) {
                targetNode.location
            }, currentPosition
        )
        activity?.initialize(context)
    }

    override fun initialize(context: ActivityContext) = setup(context)

    private fun setup(context: ActivityContext) {
        val network =
            KoinJavaComponent.get<RoadNetworkManager>(RoadNetworkManager::class.java).getNetworkOrNull(roadNetwork)
                ?: return

        // Get the closest node to the start location
        val closestNode = network.nodes
            .filter { it.id in nodes }
            .minByOrNull { it.location.distanceSqrt(startLocation.toBukkitLocation()) ?: Double.MAX_VALUE }
            ?: return

        val index = nodes.indexOf(closestNode.id)
        currentLocationIndex = nextNodeIndexFetcher(nodes, index)
        refreshActivity(context, network)
    }


    override fun tick(context: ActivityContext): TickResult {
        if (activity == null) {
            setup(context)
            return TickResult.CONSUMED
        }

        val network =
            KoinJavaComponent.get<RoadNetworkManager>(RoadNetworkManager::class.java).getNetworkOrNull(roadNetwork)
                ?: return TickResult.IGNORED

        val result = activity?.tick(context)
        if (result == TickResult.IGNORED) {
            currentLocationIndex = nextNodeIndexFetcher(nodes, currentLocationIndex)
            refreshActivity(context, network)
        }

        return TickResult.CONSUMED
    }

    override fun dispose(context: ActivityContext) {
        activity?.dispose(context)
        activity = null
    }

    override val currentPosition: PositionProperty
        get() = activity?.currentPosition ?: startLocation
}
