package com.typewritermc.entity.entries.activity

import com.google.common.collect.Sets
import com.typewritermc.core.books.pages.Colors
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.entries.emptyRef
import com.typewritermc.core.extension.annotations.Default
import com.typewritermc.core.extension.annotations.Entry
import com.typewritermc.core.extension.annotations.Help
import com.typewritermc.core.utils.UntickedAsync
import com.typewritermc.core.utils.launch
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.distanceSquared
import com.typewritermc.engine.paper.entry.entity.*
import com.typewritermc.engine.paper.entry.entries.EntityProperty
import com.typewritermc.engine.paper.entry.entries.GenericEntityActivityEntry
import com.typewritermc.engine.paper.logger
import com.typewritermc.engine.paper.utils.firstWalkableLocationBelow
import com.typewritermc.engine.paper.utils.logErrorIfNull
import com.typewritermc.engine.paper.utils.toBukkitLocation
import com.typewritermc.roadnetwork.RoadNetwork
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.RoadNetworkManager
import com.typewritermc.roadnetwork.RoadNodeId
import com.typewritermc.roadnetwork.gps.PointToPointGPS
import kotlinx.coroutines.*
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import org.koin.core.component.KoinComponent
import org.koin.java.KoinJavaComponent
import kotlin.time.Duration.Companion.seconds

private const val MIN_MOVED_DISTANCE_SQUARED = 1.0

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
    private val searchMutex = Mutex()
    private var searchJob: Job? = null

    @Volatile
    private var destination: RoadNodeId? = null

    // The network only says its nodes are connected. Whether the entity can walk there is decided per
    // edge against the terrain it stands on, so a node it cannot reach from this spot is passed over
    // until it has moved, after which a route from there may well get to it.
    private val triedDestinations: MutableSet<RoadNodeId> = Sets.newConcurrentHashSet()

    private var lastAttemptPosition: Position? = null

    fun refreshActivity(context: ActivityContext, network: RoadNetwork): TickResult {
        if (searchMutex.isLocked) return TickResult.CONSUMED

        val candidateNodes = network.nodes
            .filter { (it.position.distanceSquared(currentPosition) ?: Double.MAX_VALUE) <= radiusSquared }
            .toMutableList()

        if (candidateNodes.isEmpty()) return TickResult.IGNORED

        val job = Dispatchers.UntickedAsync.launch {
            try {
                withTimeout(30.seconds) {
                    searchMutex.withLock {
                        if (!isActive) return@withLock

                        val gps = findReachableNode(network, currentPosition.toPosition())

                        if (gps != null) {
                            setNavigationActivity(context, gps)
                        } else {
                            setIdleFallbackActivity(context, network, currentPosition.toPosition())
                        }
                    }
                }
            } catch (_: TimeoutCancellationException) {
                logger.warning("Path search timed out after 30 seconds from position: $currentPosition")
            }
        }

        searchJob = job
        job.invokeOnCompletion { if (searchJob === job) searchJob = null }

        return TickResult.CONSUMED
    }

    override fun activate(context: ActivityContext, position: PositionProperty) {
        searchJob?.cancel()
        searchJob = null
        activity.dispose()
        activity = IdleActivity(position)
        setup(context)
    }

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

        if (searchMutex.isLocked) return TickResult.CONSUMED

        val result = activity.tick(context)
        if (result == TickResult.IGNORED) {
            rememberAttempt()
            return refreshActivity(context, network!!)
        }

        return TickResult.CONSUMED
    }

    private fun rememberAttempt() {
        val destination = destination ?: return
        val position = currentPosition.toPosition()
        if (hasMovedSinceLastAttempt(position)) triedDestinations.clear()
        lastAttemptPosition = position
        triedDestinations += destination
    }

    private fun hasMovedSinceLastAttempt(position: Position): Boolean {
        val distance = lastAttemptPosition?.distanceSquared(position) ?: return true
        return distance > MIN_MOVED_DISTANCE_SQUARED
    }

    override fun deactivate(context: ActivityContext) {
        searchJob?.cancel()
        searchJob = null
        activity.deactivate(context)
    }

    override fun dispose() {
        activity.dispose()
    }

    override val currentPosition: PositionProperty
        get() = activity.currentPosition

    override val currentProperties: List<EntityProperty>
        get() = activity.currentProperties

    private suspend fun findReachableNode(
        network: RoadNetwork,
        currentPos: Position
    ): PointToPointGPS? {
        destination = null

        val nodesInRange = network.nodes
            .filter { (it.position.distanceSquared(currentPos) ?: Double.MAX_VALUE) <= radiusSquared }

        // Everything in range has been tried from here, so the notes only hold the entity back now.
        val untriedNodes = nodesInRange.filterNot { it.id in triedDestinations }
        if (untriedNodes.isEmpty()) triedDestinations.clear()

        val candidateNodes = untriedNodes.ifEmpty { nodesInRange }.toMutableList()

        var attemptCount = 0

        while (candidateNodes.isNotEmpty()) {
            val nextNode = candidateNodes.removeAt(candidateNodes.indices.random())
            attemptCount++

            val gps = PointToPointGPS(roadNetwork, {
                val raised = if (currentPosition.toBukkitLocation().block.isSolid) {
                    currentPosition.withY { it + 1 }
                } else {
                    currentPosition
                }.toPosition()
                raised.firstWalkableLocationBelow() ?: raised
            }) { nextNode.position }

            try {
                val pathResult = gps.findPath()
                if (pathResult.isSuccess) {
                    destination = nextNode.id
                    return gps
                }
            } catch (_: Exception) {
                // Try next node
            }
        }

        logger.severe("No reachable nodes found after trying $attemptCount attempts from position: $currentPosition")
        return null
    }

    private fun setNavigationActivity(context: ActivityContext, gps: PointToPointGPS) {
        activity.deactivate(context)
        activity.dispose()
        activity = NavigationActivity(gps, currentPosition).also { it.activate(context, currentPosition) }
    }

    private fun setIdleFallbackActivity(
        context: ActivityContext,
        network: RoadNetwork,
        currentPos: Position
    ) {
        val teleportNode = network.nodes
            .filter { (it.position.distanceSquared(currentPos) ?: Double.MAX_VALUE) <= radiusSquared }
            .randomOrNull()
            .logErrorIfNull("No reachable nodes found")

        activity.deactivate(context)
        activity.dispose()
        val newPosition = teleportNode?.position?.toProperty() ?: currentPosition
        activity = IdleActivity(newPosition).also {
            it.activate(context, newPosition)
        }
    }
}
