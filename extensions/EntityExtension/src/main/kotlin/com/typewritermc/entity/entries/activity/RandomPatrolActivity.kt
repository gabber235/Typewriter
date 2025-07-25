package com.typewritermc.entity.entries.activity

import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.point.distanceSqrt
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.roadnetwork.RoadNetwork
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.RoadNetworkManager
import com.typewritermc.roadnetwork.gps.PointToPointGPS
import org.koin.core.component.KoinComponent
import org.koin.java.KoinJavaComponent

@Entry("random_patrol_activity", "Randomly patrol nodes in the network", Colors.BLUE, "fa6-solid:shuffle")
/**
 * The `RandomPatrolActivity` is an activity that makes the entity randomly patrol nodes in the network.
 * The entity will randomly select a node within the specified radius and navigate to it.
 * Once the entity reaches the target node, it will select another random node and continue.
 *
 * ## How could this be used?
 * This could be used to make guards patrol randomly around an area.
 */
class RandomPatrolActivityEntry(
    override val id: String = "",
    override val name: String = "",
    val roadNetwork: Ref<RoadNetworkEntry> = emptyRef(),
    @Help("The maximum distance (in blocks) from the entity's current position to consider nodes for random selection.")
    @Default("100.0")
    val radius: Double = 100.0,
) : GenericEntityActivityEntry {
    override fun create(
        context: ActivityContext,
        currentLocation: PositionProperty
    ): EntityActivity<ActivityContext> {
        return RandomPatrolActivity(roadNetwork, radius * radius, currentLocation)
    }
}

class RandomPatrolActivity(
    private val roadNetwork: Ref<RoadNetworkEntry>,
    private val radiusSquared: Double,
    startLocation: PositionProperty,
) : EntityActivity<ActivityContext>, KoinComponent {
    private var network: RoadNetwork? = null
    private var activity: EntityActivity<in ActivityContext> = IdleActivity(startLocation)

    fun refreshActivity(context: ActivityContext, network: RoadNetwork): TickResult {
        val currentPos = currentPosition.toPosition()
        val nextNode = network.nodes
            .filter { (it.position.distanceSqrt(currentPos) ?: Double.MAX_VALUE) <= radiusSquared }
            .randomOrNull()
            ?: return TickResult.IGNORED

        activity.dispose(context)
        activity = NavigationActivity(
            PointToPointGPS(
                roadNetwork,
                { currentPosition.toPosition() }) {
                nextNode.position
            }, currentPosition
        )
        activity.initialize(context)
        return TickResult.CONSUMED
    }

    override fun initialize(context: ActivityContext) = setup(context)

    private fun setup(context: ActivityContext) {
        network =
            KoinJavaComponent.get<RoadNetworkManager>(RoadNetworkManager::class.java).getNetworkOrNull(roadNetwork)
                ?: return

        refreshActivity(context, network!!)
    }

    override fun tick(context: ActivityContext): TickResult {
        if (network == null) {
            setup(context)
            return TickResult.CONSUMED
        }

        val result = activity.tick(context)
        if (result == TickResult.IGNORED) {
            return refreshActivity(context, network!!)
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
