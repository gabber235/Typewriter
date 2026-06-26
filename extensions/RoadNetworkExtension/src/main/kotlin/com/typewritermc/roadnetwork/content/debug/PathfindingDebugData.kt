package com.typewritermc.roadnetwork.content.debug

import com.typewritermc.core.utils.point.Position
import com.typewritermc.roadnetwork.RoadNode
import de.bsommerfeld.pathetic.api.wrapper.PathPosition

/**
 * Information about an intermediate node collision during pathfinding.
 *
 * @property collidingNode The road node that caused the collision
 * @property collisionPathIndex The index in the path where the collision occurred
 * @property collisionPosition The exact position where the collision was detected
 */
data class IntermediateNodeCollision(
    val collidingNode: RoadNode,
    val collisionPathIndex: Int,
    val collisionPosition: PathPosition
)

/**
 * A complete debug session containing all recorded pathfinding information.
 *
 * @property startPosition The starting position of the pathfinding request
 * @property targetPosition The target position of the pathfinding request
 * @property steps All recorded debug steps during pathfinding
 * @property finalPath The calculated path if pathfinding was successful
 * @property successful Whether the pathfinding operation completed successfully
 * @property totalDurationMs Total time taken for the pathfinding operation in milliseconds
 * @property intermediateNodeCollision Information about any collision with intermediate nodes
 */
data class PathfindingDebugSession(
    val startPosition: Position,
    val targetPosition: Position,
    val steps: List<PathfindingDebugStep>,
    val finalPath: List<PathPosition>?,
    val successful: Boolean,
    val totalDurationMs: Long,
    val intermediateNodeCollision: IntermediateNodeCollision? = null
) {
    /**
     * Returns only the important steps, filtering out verbose debug information.
     */
    fun getImportantSteps(): List<PathfindingDebugStep> = steps.filter { !it.isVerbose }

    /**
     * Returns all debug steps including verbose information.
     */
    fun getAllSteps(): List<PathfindingDebugStep> = steps
}

/**
 * A single step in the pathfinding debugging process.
 *
 * @property stepIndex The sequential index of this step
 * @property timestampMs Relative timestamp when this step occurred
 * @property position The position where this step occurred
 * @property parentPosition The position this step originated from, if any
 * @property event The specific debug event that occurred at this step
 * @property isVerbose Whether this step contains verbose debug information
 */
data class PathfindingDebugStep(
    val stepIndex: Int,
    val timestampMs: Long,
    val position: PathPosition,
    val parentPosition: PathPosition?,
    val event: PathfindingDebugEvent,
    val isVerbose: Boolean = false
)

/**
 * Represents different types of events that can occur during pathfinding.
 */
sealed class PathfindingDebugEvent {

    /**
     * A node was successfully explored by the pathfinding algorithm.
     */
    data class NodeExplored(
        val position: PathPosition,
        val gCost: Double
    ) : PathfindingDebugEvent()

    /**
     * A node was rejected by a validation processor.
     */
    data class NodeRejected(
        val position: PathPosition,
        val reason: String,
        val processorName: String
    ) : PathfindingDebugEvent()

    /**
     * The pathfinding algorithm completed successfully.
     */
    data class PathCompleted(val pathLength: Int) : PathfindingDebugEvent()

    /**
     * The pathfinding algorithm failed.
     */
    data class PathFailed(val reason: String) : PathfindingDebugEvent()

    /**
     * An intermediate node collision was detected in the calculated path.
     */
    data class IntermediateNodeCollision(
        val collidingNode: RoadNode,
        val collisionPosition: PathPosition
    ) : PathfindingDebugEvent()
}

/**
 * Records pathfinding events for debug analysis.
 * Each debug session uses its own isolated recorder instance.
 *
 * @property startPosition The starting position for this debug session
 * @property targetPosition The target position for this debug session
 */
class PathfindingDebugRecorder(
    val startPosition: Position,
    val targetPosition: Position
) {
    private val steps = mutableListOf<PathfindingDebugStep>()
    private val startTime = System.currentTimeMillis()

    /**
     * Records a pathfinding event with optional verbosity flag.
     *
     * @param position The position where the event occurred
     * @param parentPosition The parent position from the search tree
     * @param event The debug event to record
     * @param verbose Whether this event should be considered verbose debug information
     */
    fun recordEvent(
        position: PathPosition,
        parentPosition: PathPosition?,
        event: PathfindingDebugEvent,
        verbose: Boolean = false
    ) {
        synchronized(steps) {
            val step = PathfindingDebugStep(
                stepIndex = steps.size,
                timestampMs = System.currentTimeMillis() - startTime,
                position = position,
                parentPosition = parentPosition,
                event = event,
                isVerbose = verbose
            )
            steps.add(step)
        }
    }

    /**
     * Returns a copy of all currently recorded steps.
     * Used for collision timeline injection.
     */
    fun getSteps(): List<PathfindingDebugStep> = synchronized(steps) { steps.toList() }

    /**
     * Returns the recording start time for timestamp calculations.
     */
    fun getStartTime(): Long = startTime

    /**
     * Creates a complete debug session from the recorded information.
     *
     * @param finalPath The calculated path, if any
     * @param successful Whether pathfinding completed successfully
     * @param intermediateNodeCollision Information about any node collision
     */
    fun createSession(
        finalPath: List<PathPosition>?,
        successful: Boolean,
        intermediateNodeCollision: IntermediateNodeCollision? = null
    ): PathfindingDebugSession {
        return PathfindingDebugSession(
            startPosition = startPosition,
            targetPosition = targetPosition,
            steps = synchronized(steps) { steps.toList() },
            finalPath = finalPath,
            successful = successful,
            totalDurationMs = System.currentTimeMillis() - startTime,
            intermediateNodeCollision = intermediateNodeCollision
        )
    }
}