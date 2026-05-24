package com.typewritermc.roadnetwork.content.debug

import com.typewritermc.core.utils.point.Position
import de.bsommerfeld.pathetic.api.pathing.processing.ValidationProcessor
import de.bsommerfeld.pathetic.api.pathing.processing.context.EvaluationContext
import de.bsommerfeld.pathetic.api.pathing.processing.context.SearchContext

/**
 * Initializes and provides a [PathfindingDebugRecorder] for tracking pathfinding operations.
 *
 * This processor creates a recorder instance during search initialization and makes it
 * available to other debug processors via shared context data. It must be added to the
 * pathfinding pipeline before any other debug processors that depend on the recorder.
 *
 * The recorder instance can be retrieved after pathfinding completes using [getRecorder].
 *
 * @param startPosition The starting position of the pathfinding operation
 * @param targetPosition The target position of the pathfinding operation
 * @see PathfindingDebugRecorder
 * @see DebugRecorderNodeExplored
 */
class DebugRecorderSupplier(
    private val startPosition: Position,
    private val targetPosition: Position
) : ValidationProcessor {

    companion object {
        /** Key used to store and retrieve the recorder from search context shared data. */
        const val RECORDER_KEY = "typewriter.roadnetwork.debug.recorder"
    }

    private var recorder: PathfindingDebugRecorder? = null

    override fun initializeSearch(context: SearchContext) {
        recorder = PathfindingDebugRecorder(startPosition, targetPosition)
        context.sharedData[RECORDER_KEY] = recorder
    }

    override fun isValid(context: EvaluationContext): Boolean = true

    /**
     * Retrieves the recorder instance created during search initialization.
     *
     * @return The [PathfindingDebugRecorder] instance, or null if search has not been initialized
     */
    fun getRecorder(): PathfindingDebugRecorder? = recorder
}

/**
 * Records node exploration events during pathfinding for debugging purposes.
 *
 * This processor captures each node as it's explored during the pathfinding algorithm,
 * recording the node's position, its parent, and the associated cost. It requires
 * [DebugRecorderSupplier] to be added to the pipeline first to initialize the recorder.
 *
 * For each explored node, records:
 * - Current node position
 * - Parent node position (the node from which this node was reached)
 * - G-cost (base transition cost from start to current node)
 *
 * @see DebugRecorderSupplier
 * @see PathfindingDebugRecorder
 * @see PathfindingDebugEvent.NodeExplored
 */
class DebugRecorderNodeExplored : ValidationProcessor {

    override fun isValid(context: EvaluationContext): Boolean {
        val recorder = context.sharedData[DebugRecorderSupplier.RECORDER_KEY] as? PathfindingDebugRecorder
        recorder?.recordEvent(
            position = context.currentPathPosition,
            parentPosition = context.previousPathPosition,
            event = PathfindingDebugEvent.NodeExplored(
                position = context.currentPathPosition,
                gCost = context.baseTransitionCost
            )
        )
        return true
    }
}