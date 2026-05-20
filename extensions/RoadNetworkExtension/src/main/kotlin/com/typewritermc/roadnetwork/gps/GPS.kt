package com.typewritermc.roadnetwork.gps

import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.core.utils.point.distanceSquared
import com.typewritermc.engine.paper.entry.entity.EntityPathingCapabilities
import com.typewritermc.engine.paper.utils.toBukkitLocation
import com.typewritermc.engine.paper.utils.toBukkitWorld
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.RoadNetworkManager
import com.typewritermc.roadnetwork.RoadNode
import com.typewritermc.roadnetwork.pathfinding.pathetic.PathCalculationResult
import com.typewritermc.roadnetwork.pathfinding.pathetic.processors.AvoidNegativeNodesProcessor
import com.typewritermc.roadnetwork.pathfinding.pathetic.processors.NodeTypeProcessor
import com.typewritermc.roadnetwork.pathfinding.pathetic.processors.ObstructionProcessor
import com.typewritermc.roadnetwork.pathfinding.pathetic.processors.ReachabilityProcessor
import com.typewritermc.roadnetwork.pathfinding.pathetic.processors.cost.JumpAwareCostProcessor
import com.typewritermc.roadnetwork.pathfinding.pathetic.processors.cost.SpaceAwareCostProcessor
import com.typewritermc.roadnetwork.roadNetworkMaxDistance
import de.bsommerfeld.pathetic.api.pathing.Pathfinder
import de.bsommerfeld.pathetic.api.pathing.result.PathfinderResult
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.bukkit.context.BukkitEnvironmentContext
import de.bsommerfeld.pathetic.bukkit.mapper.BukkitMapper
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlinx.coroutines.suspendCancellableCoroutine
import org.koin.core.parameter.parametersOf
import org.koin.java.KoinJavaComponent
import kotlin.math.pow

interface GPS {
    val roadNetwork: Ref<RoadNetworkEntry>
    suspend fun findPath(): Result<List<GPSEdge>>
}

data class GPSEdge(
    val start: Position,
    val end: Position,
    val weight: Double,
    /**
     * The number of blocks the path is long.
     */
    val length: Double,
) {
    val isFastTravel: Boolean
        get() = weight == 0.0
}

suspend fun roadNetworkFindPath(
    start: RoadNode,
    end: RoadNode,
    capabilities: EntityPathingCapabilities = EntityPathingCapabilities.DEFAULT,
    nodes: List<RoadNode> = emptyList(),
    negativeNodes: List<RoadNode> = emptyList(),
): PathCalculationResult {
    val world = checkSameWorld(start.position, end.position) ?: return PathCalculationResult.Failure

    val relevantIntermediateNodes = nodes.filter { it.position.world == world && it.id != start.id && it.id != end.id }
    val relevantNegativeNodes = negativeNodes.filter { it.position.world == world }

    return findPathCore(
        start.position,
        end.position,
        relevantIntermediateNodes,
        relevantNegativeNodes,
        capabilities
    )
}

suspend fun findPathBetweenPosition(
    startPosition: Position,
    endPosition: Position,
    capabilities: EntityPathingCapabilities = EntityPathingCapabilities.DEFAULT,
    roadNetworkRef: Ref<RoadNetworkEntry>,
    roadNetworkManager: RoadNetworkManager = KoinJavaComponent.get(RoadNetworkManager::class.java),
    checkIntermediateNodes: Boolean = true,
    allowFallback: Boolean = false,
): PathCalculationResult {
    val world = checkSameWorld(startPosition, endPosition) ?: return PathCalculationResult.Failure

    val network = roadNetworkManager.getNetwork(roadNetworkRef)

    val maxDistSq = roadNetworkMaxDistance * roadNetworkMaxDistance
    val relevantIntermediateNodes = network.nodes.filter { node ->
        node.position.world == world &&
                (node.position.distanceSquared(startPosition)!! < maxDistSq || node.position.distanceSquared(endPosition)!! < maxDistSq)
    }

    val relevantNegativeNodes = network.negativeNodes.filter { node ->
        node.position.world == world &&
                (node.position.distanceSquared(startPosition)!! < maxDistSq || node.position.distanceSquared(endPosition)!! < maxDistSq)
    }

    return findPathCore(
        startPosition,
        endPosition,
        relevantIntermediateNodes,
        relevantNegativeNodes,
        capabilities,
        checkIntermediateNodes,
        allowFallback,
    )
}

private suspend fun findPathCore(
    startPosition: Position,
    targetPosition: Position,
    intermediateNodes: List<RoadNode>,
    negativeNodes: List<RoadNode>,
    capabilities: EntityPathingCapabilities,
    checkIntermediateNodes: Boolean = true,
    allowFallback: Boolean = false,
): PathCalculationResult {
    val startPathPos: PathPosition = BukkitMapper.toPathPosition(startPosition.toBukkitLocation())
    val targetPathPos: PathPosition = BukkitMapper.toPathPosition(targetPosition.toBukkitLocation())

    val nodeCostProcessor = buildList {
        add(SpaceAwareCostProcessor(entityHeight = capabilities.height))
        add(JumpAwareCostProcessor(capabilities))
    }

    val nodeValidationProcessor = buildList {
        if (negativeNodes.isNotEmpty()) {
            add(AvoidNegativeNodesProcessor(negativeNodes, capabilities))
        }
        add(NodeTypeProcessor(capabilities))
        add(ObstructionProcessor(capabilities))
        add(ReachabilityProcessor(capabilities))
    }

    val pathfinder = KoinJavaComponent.get<Pathfinder>(
        Pathfinder::class.java,
        null
    ) { parametersOf(nodeValidationProcessor, nodeCostProcessor) }

    val calculatedPath = suspendCancellableCoroutine<PathfinderResult?> { continuation ->
        val search = pathfinder
            .findPath(startPathPos, targetPathPos, BukkitEnvironmentContext(startPosition.world.toBukkitWorld()))
            .ifPresent { continuation.resume(it.takeIf { result -> result.successful() || (allowFallback && result.hasFallenBack()) }) }
            .orElse { continuation.resume(null) }
            .exceptionally { continuation.resumeWithException(it) }

        continuation.invokeOnCancellation { search.abort() }
    } ?: return PathCalculationResult.Failure

    if (checkIntermediateNodes) {
        val collidesWithIntermediate = intermediateNodes.any { intermediateNode ->
            val intermediateRadiusSq = (intermediateNode.radius + (capabilities.width / 2.0)).pow(2.0)
            calculatedPath.path.any { pathPos ->
                pathPos.distanceSqTo(
                    intermediateNode.position.x,
                    intermediateNode.position.y,
                    intermediateNode.position.z
                ) <= intermediateRadiusSq
            }
        }

        if (collidesWithIntermediate) {
            return PathCalculationResult.Failure
        }
    }

    val lengthInBlocks = calculatedPath.path.length().toDouble()
    return PathCalculationResult.Success(
        calculatedPath.path,
        startPosition.world,
        lengthInBlocks,
        lengthInBlocks,
        calculatedPath.hasFallenBack(),
    )
}

private fun checkSameWorld(location1: Position, location2: Position): World? {
    if (location1.world != location2.world) {
        return null
    }
    return location1.world
}

fun PathPosition.distanceSqTo(x: Double, y: Double, z: Double): Double {
    val dx = this.x - x
    val dy = this.y - y
    val dz = this.z - z
    return dx * dx + dy * dy + dz * dz
}
