package com.typewritermc.roadnetwork.pathfinding.pathetic.processors

import com.typewritermc.engine.paper.entry.entity.EntityPathingCapabilities
import com.typewritermc.roadnetwork.RoadNode
import com.typewritermc.roadnetwork.content.debug.DebugRecorderSupplier
import com.typewritermc.roadnetwork.content.debug.PathfindingDebugEvent
import com.typewritermc.roadnetwork.content.debug.PathfindingDebugRecorder
import com.typewritermc.roadnetwork.gps.distanceSqTo
import de.bsommerfeld.pathetic.api.pathing.processing.ValidationProcessor
import de.bsommerfeld.pathetic.api.pathing.processing.context.EvaluationContext
import kotlin.math.pow

/**
 * A stateless and thread-safe node processor.
 *
 * Validates nodes by ensuring they don't fall within exclusion zones around
 * negative nodes.
 *
 * The exclusion radius for each negative node is calculated as:
 * `node.radius + (capabilities.width / 2.0)`, ensuring the entity's bounding
 * box won't intersect with the negative node's area. This accounts for both
 * the node's inherent radius and half of the entity's width.
 *
 * This processor has no ordering requirements and can be placed anywhere in
 * the validation chain.
 */
class AvoidNegativeNodesProcessor(
    negativeNodes: List<RoadNode>,
    capabilities: EntityPathingCapabilities = EntityPathingCapabilities.DEFAULT
) : ValidationProcessor {

    private val negativeNodeChecks = negativeNodes.map { node ->
        Pair(
            Triple(node.position.x, node.position.y, node.position.z),
            (node.radius + (capabilities.width / 2.0)).pow(2.0)
        )
    }

    override fun isValid(context: EvaluationContext): Boolean {
        if (negativeNodeChecks.isEmpty()) {
            return true
        }

        val currentPos = context.currentPathPosition
        val collidingNode = negativeNodeChecks.firstOrNull { (nodeCoords, radiusSq) ->
            currentPos.distanceSqTo(nodeCoords.first, nodeCoords.second, nodeCoords.third) <= radiusSq
        }

        if (collidingNode != null) {
            val debugRecorder = context.sharedData[DebugRecorderSupplier.RECORDER_KEY] as? PathfindingDebugRecorder
            debugRecorder?.let {
                val distance = currentPos.distanceSqTo(
                    collidingNode.first.first,
                    collidingNode.first.second,
                    collidingNode.first.third
                )

                it.recordEvent(
                    position = currentPos,
                    parentPosition = context.previousPathPosition,
                    event = PathfindingDebugEvent.NodeRejected(
                        position = currentPos,
                        reason = "Inside negative node exclusion zone (${
                            String.format(
                                "%.1f",
                                distance
                            )
                        }m from center)",
                        processorName = "AvoidNegativeNodesProcessor"
                    )
                )
            }
        }

        return collidingNode == null
    }
}