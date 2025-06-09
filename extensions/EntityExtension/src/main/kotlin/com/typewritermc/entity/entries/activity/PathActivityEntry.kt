package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityActivityEntry
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.roadnetwork.*
import com.typewritermc.roadnetwork.gps.PointToPointGPS
import org.koin.java.KoinJavaComponent

@Entry("path_activity", "Moving along a predefined path", Colors.BLUE, "material-symbols:conversion-path")
/**
 * The `Path Activity` is an activity that moves along a predefined path.
 * The entity will move to each location in the set in order.
 * Once the entity reaches the last location, it will do the idle activity.
 *
 * ## How could this be used?
 * This could be used to have a tour guide that moves along the post-important paths.
 */
class PathActivityEntry(
    override val id: String = "",
    override val name: String = "",
    override val roadNetwork: Ref<RoadNetworkEntry> = emptyRef(),
    override val nodes: List<RoadNodeId> = emptyList(),
    @Help("The activity that will be used when the entity is at the final location.")
    val idleActivity: Ref<out EntityActivityEntry> = emptyRef(),
) : GenericEntityActivityEntry, RoadNodeCollectionEntry {
    override fun create(context: ActivityContext, currentLocation: PositionProperty): EntityActivity<ActivityContext> {
        if (nodes.isEmpty()) return IdleActivity.create(context, currentLocation)
        return PathActivity(roadNetwork, nodes, currentLocation, idleActivity)
    }
}

private class PathActivity(
    private val roadNetwork: Ref<RoadNetworkEntry>,
    private val nodes: List<RoadNodeId>,
    startLocation: PositionProperty,
    private val idleActivity: Ref<out EntityActivityEntry>,
) : GenericEntityActivity {
    private var network: RoadNetwork? = null
    private var currentLocationIndex = 0
    private var activity: EntityActivity<in ActivityContext> = IdleActivity(startLocation)

    fun refreshActivity(context: ActivityContext, network: RoadNetwork) {
        if (nodes.size <= currentLocationIndex) {
            activity.dispose(context)
            activity = idleActivity.get()?.create(context, currentPosition) ?: IdleActivity(currentPosition)
            activity.initialize(context)
            return
        }

        val targetNodeId = nodes.getOrNull(currentLocationIndex)
            ?: return
        val targetNode = network.nodes.find { it.id == targetNodeId }
            ?: return

        activity.dispose(context)
        activity = NavigationActivity(
            PointToPointGPS(
                roadNetwork,
                { currentPosition.toPosition() }) {
                targetNode.position
            }, currentPosition
        )
        activity.initialize(context)
    }

    override fun initialize(context: ActivityContext) = setup(context)

    private fun setup(context: ActivityContext) {
        network =
            KoinJavaComponent.get<RoadNetworkManager>(RoadNetworkManager::class.java).getNetworkOrNull(roadNetwork)
                ?: return

        // Get the closest node to the start location
        val closestNode = network!!.nodes
            .filter { it.id in nodes }
            .minByOrNull { it.position.distanceSquared(currentPosition.toPosition()) }
            ?: return

        val index = nodes.indexOf(closestNode.id)
        currentLocationIndex = (index + 1)
        refreshActivity(context, network!!)
    }


    override fun tick(context: ActivityContext): TickResult {
        if (network == null) {
            setup(context)
            return TickResult.CONSUMED
        }

        val result = activity.tick(context)
        if (result == TickResult.IGNORED) {
            currentLocationIndex = (currentLocationIndex + 1)
            refreshActivity(context, network!!)
            // If we refreshed to nothing, we are done.
            if (activity is IdleActivity) {
                return TickResult.IGNORED
            }
        }

        return TickResult.CONSUMED
    }

    override fun dispose(context: ActivityContext) {
        val oldPosition = currentPosition
        activity.dispose(context)
        activity = IdleActivity(oldPosition)
    }

    override val currentPosition: PositionProperty
        get() = activity.currentPosition

    override val currentProperties: List<EntityProperty>
        get() = activity.currentProperties
}