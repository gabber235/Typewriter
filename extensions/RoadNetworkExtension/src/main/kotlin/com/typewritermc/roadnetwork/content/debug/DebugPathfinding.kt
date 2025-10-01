package com.typewritermc.roadnetwork.content.debug

import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.World
import com.typewritermc.engine.paper.entry.entity.EntityPathingCapabilities
import com.typewritermc.engine.paper.utils.toBukkitLocation
import com.typewritermc.engine.paper.utils.toBukkitWorld
import com.typewritermc.roadnetwork.RoadNode
import com.typewritermc.roadnetwork.gps.distanceSqTo
import com.typewritermc.roadnetwork.pathfinding.pathetic.PathCalculationResult
import com.typewritermc.roadnetwork.pathfinding.pathetic.processors.AvoidNegativeNodesProcessor
import com.typewritermc.roadnetwork.pathfinding.pathetic.processors.NodeTypeProcessor
import com.typewritermc.roadnetwork.pathfinding.pathetic.processors.ObstructionProcessor
import com.typewritermc.roadnetwork.pathfinding.pathetic.processors.ReachabilityProcessor
import com.typewritermc.roadnetwork.pathfinding.pathetic.processors.cost.JumpAwareCostProcessor
import com.typewritermc.roadnetwork.pathfinding.pathetic.processors.cost.SpaceAwareCostProcessor
import de.bsommerfeld.pathetic.api.pathing.Pathfinder
import de.bsommerfeld.pathetic.api.pathing.processing.CostProcessor
import de.bsommerfeld.pathetic.api.pathing.processing.ValidationProcessor
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.bukkit.context.BukkitEnvironmentContext
import de.bsommerfeld.pathetic.bukkit.mapper.BukkitMapper
import kotlinx.coroutines.suspendCancellableCoroutine
import org.koin.core.parameter.parametersOf
import org.koin.java.KoinJavaComponent
import kotlin.coroutines.resume
import kotlin.coroutines.resumeWithException
import kotlin.math.pow

suspend fun findPathWithDebug(
    start: RoadNode,
    end: RoadNode,
    capabilities: EntityPathingCapabilities = EntityPathingCapabilities.DEFAULT,
    nodes: List<RoadNode> = emptyList(),
    negativeNodes: List<RoadNode> = emptyList(),
): Pair<PathCalculationResult, PathfindingDebugSession?> {

    val world = validateSameWorld(start.position, end.position)
        ?: return PathCalculationResult.Failure to null

    val intermediateNodes = nodes.filter {
        it.position.world == world && it.id != start.id && it.id != end.id
    }
    val relevantNegativeNodes = negativeNodes.filter {
        it.position.world == world
    }

    val startPos = BukkitMapper.toPathPosition(start.position.toBukkitLocation())
    val targetPos = BukkitMapper.toPathPosition(end.position.toBukkitLocation())

    return try {
        executePathfindingWithDebug(
            startPos, targetPos, start.position.world,
            intermediateNodes, relevantNegativeNodes, capabilities
        )
    } catch (exception: Exception) {
        handlePathfindingException(start.position, end.position, exception)
    }
}

private suspend fun executePathfindingWithDebug(
    startPos: PathPosition,
    targetPos: PathPosition,
    world: World,
    intermediateNodes: List<RoadNode>,
    negativeNodes: List<RoadNode>,
    capabilities: EntityPathingCapabilities
): Pair<PathCalculationResult, PathfindingDebugSession?> {

    val recorderSupplier = DebugRecorderSupplier(
        Position(world, startPos.x, startPos.y, startPos.z),
        Position(world, targetPos.x, targetPos.y, targetPos.z)
    )
    val nodeExploredRecorder = DebugRecorderNodeExplored()

    val processors = listOf(recorderSupplier) +
            createValidationProcessors(negativeNodes, capabilities) +
            nodeExploredRecorder
    val costProcessors = createCostProcessors(capabilities)

    val pathfinder = KoinJavaComponent.get<Pathfinder>(
        Pathfinder::class.java, null
    ) { parametersOf(processors, costProcessors) }

    val result = suspendCancellableCoroutine { continuation ->
        val search = pathfinder
            .findPath(startPos, targetPos, BukkitEnvironmentContext(world.toBukkitWorld()))
            .ifPresent { continuation.resume(it.takeIf { result -> result.successful() }) }
            .orElse { continuation.resume(null) }
            .exceptionally { continuation.resumeWithException(it) }

        continuation.invokeOnCancellation { search.abort() }
    }

    val recorder = recorderSupplier.getRecorder()

    if (result == null) {
        recorder?.recordEvent(
            targetPos, null,
            PathfindingDebugEvent.PathFailed("Pathfinder returned unsuccessful result")
        )
        return PathCalculationResult.Failure to recorder?.createSession(null, false)
    }

    val path = result.path.toList()
    val collision = detectIntermediateNodeCollision(path, intermediateNodes, capabilities)

    if (collision != null) {
        val session = recorder?.let { injectCollisionEvent(it, path, collision) }
        return PathCalculationResult.Failure to session
    }

    recorder?.recordEvent(
        targetPos, null,
        PathfindingDebugEvent.PathCompleted(path.size)
    )

    val session = recorder?.createSession(path, true)
    val pathLength = result.path.length().toDouble()

    return PathCalculationResult.Success(
        result.path,
        world,
        pathLength,
        pathLength
    ) to session
}

private fun injectCollisionEvent(
    recorder: PathfindingDebugRecorder,
    finalPath: List<PathPosition>,
    collision: IntermediateNodeCollision
): PathfindingDebugSession {

    val originalSteps = recorder.getSteps()
    val collisionPos = collision.collisionPosition

    val collisionStepIndex = originalSteps.indexOfFirst { step ->
        step.event is PathfindingDebugEvent.NodeExplored &&
                isSamePosition(step.position, collisionPos)
    }

    val modifiedSteps = if (collisionStepIndex >= 0) {
        val insertIndex = collisionStepIndex + 1
        val collisionStep = PathfindingDebugStep(
            stepIndex = insertIndex,
            timestampMs = originalSteps[collisionStepIndex].timestampMs + 1,
            position = collisionPos,
            event = PathfindingDebugEvent.IntermediateNodeCollision(
                collidingNode = collision.collidingNode,
                collisionPosition = collision.collisionPosition
            ),
            parentPosition = null,
            isVerbose = false
        )
        originalSteps.take(insertIndex) + collisionStep
    } else {
        val cutoffIndex = (originalSteps.size * 0.7).toInt().coerceAtLeast(1)
        val collisionStep = PathfindingDebugStep(
            stepIndex = cutoffIndex,
            timestampMs = originalSteps.getOrNull(cutoffIndex - 1)?.timestampMs ?: 0,
            position = collisionPos,
            event = PathfindingDebugEvent.IntermediateNodeCollision(
                collidingNode = collision.collidingNode,
                collisionPosition = collision.collisionPosition
            ),
            parentPosition = null,
            isVerbose = false
        )
        originalSteps.take(cutoffIndex) + collisionStep
    }

    return PathfindingDebugSession(
        startPosition = recorder.startPosition,
        targetPosition = recorder.targetPosition,
        steps = modifiedSteps,
        finalPath = finalPath,
        successful = false,
        totalDurationMs = System.currentTimeMillis() - recorder.getStartTime(),
        intermediateNodeCollision = collision
    )
}

private fun isSamePosition(pos1: PathPosition, pos2: PathPosition): Boolean {
    return pos1.flooredX == pos2.flooredX &&
            pos1.flooredY == pos2.flooredY &&
            pos1.flooredZ == pos2.flooredZ
}

private fun createValidationProcessors(
    negativeNodes: List<RoadNode>,
    capabilities: EntityPathingCapabilities
): List<ValidationProcessor> {
    val processors = mutableListOf<ValidationProcessor>()

    if (negativeNodes.isNotEmpty()) {
        processors.add(AvoidNegativeNodesProcessor(negativeNodes, capabilities))
    }

    processors.add(NodeTypeProcessor(capabilities))
    processors.add(ObstructionProcessor(capabilities))
    processors.add(ReachabilityProcessor(capabilities))

    return processors
}

private fun createCostProcessors(
    capabilities: EntityPathingCapabilities
): List<CostProcessor> {
    return listOf(
        SpaceAwareCostProcessor(entityHeight = capabilities.height),
        JumpAwareCostProcessor(capabilities)
    )
}

private fun detectIntermediateNodeCollision(
    path: List<PathPosition>,
    intermediateNodes: List<RoadNode>,
    capabilities: EntityPathingCapabilities
): IntermediateNodeCollision? {

    path.forEachIndexed { pathIndex, pathPos ->
        intermediateNodes.forEach { node ->
            val collisionRadius = (node.radius + (capabilities.width / 2.0)).pow(2.0)
            val distanceSquared = pathPos.distanceSqTo(
                node.position.x,
                node.position.y,
                node.position.z
            )

            if (distanceSquared <= collisionRadius) {
                return IntermediateNodeCollision(
                    collidingNode = node,
                    collisionPathIndex = pathIndex,
                    collisionPosition = pathPos
                )
            }
        }
    }
    return null
}

private fun validateSameWorld(pos1: Position, pos2: Position): World? {
    return if (pos1.world == pos2.world) pos1.world else null
}

private fun handlePathfindingException(
    startPos: Position,
    endPos: Position,
    exception: Exception
): Pair<PathCalculationResult, PathfindingDebugSession?> {
    val recorder = PathfindingDebugRecorder(startPos, endPos)
    val startPathPos = BukkitMapper.toPathPosition(startPos.toBukkitLocation())

    recorder.recordEvent(
        startPathPos, null,
        PathfindingDebugEvent.PathFailed("Exception: ${exception.message}")
    )

    return PathCalculationResult.Failure to recorder.createSession(null, false)
}