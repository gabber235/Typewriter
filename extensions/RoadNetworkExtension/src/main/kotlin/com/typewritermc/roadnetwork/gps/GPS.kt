package com.typewritermc.roadnetwork.gps

import com.extollit.gaming.ai.path.HydrazinePathFinder
import com.extollit.gaming.ai.path.model.*
import com.typewritermc.core.entries.Ref
import com.typewritermc.core.utils.point.Position
import com.typewritermc.core.utils.point.Vector
import com.typewritermc.core.utils.point.distanceSqrt
import com.typewritermc.engine.paper.entry.entity.toProperty
import com.typewritermc.roadnetwork.RoadNetworkEntry
import com.typewritermc.roadnetwork.RoadNode
import com.typewritermc.roadnetwork.pathfinding.PFEmptyEntity
import com.typewritermc.roadnetwork.pathfinding.PFInstanceSpace
import com.typewritermc.roadnetwork.pathfinding.instanceSpace
import com.typewritermc.roadnetwork.roadNetworkMaxDistance

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

fun roadNetworkFindPath(
    start: RoadNode,
    end: RoadNode,
    entity: IPathingEntity = PFEmptyEntity(start.position.toProperty(), searchRange = roadNetworkMaxDistance.toFloat()),
    instance: PFInstanceSpace = start.position.world.instanceSpace,
    nodes: List<RoadNode> = emptyList(),
    negativeNodes: List<RoadNode> = emptyList(),
): IPath? {
    return roadNetworkFindPath(start, end, HydrazinePathFinder(entity, instance), nodes, negativeNodes)
}

fun roadNetworkFindPath(
    start: RoadNode,
    end: RoadNode,
    pathfinder: HydrazinePathFinder,
    nodes: List<RoadNode> = emptyList(),
    negativeNodes: List<RoadNode> = emptyList(),
): IPath? {
    val interestingNodes = nodes.filter {
        if (it.id == start.id) return@filter false
        if (it.id == end.id) return@filter false
        true
    }
    val interestingNegativeNodes = negativeNodes.filter {
        val distance = start.position.distanceSqrt(it.position) ?: 0.0
        distance > it.radius * it.radius && distance < roadNetworkMaxDistance * roadNetworkMaxDistance
    }

    val additionalRadius = pathfinder.subject().width().toDouble()

    // We want to avoid going through negative nodes
    if (interestingNegativeNodes.isNotEmpty()) {
        pathfinder.withGraphNodeFilter { node ->
            if (node.isInRangeOf(interestingNegativeNodes, additionalRadius)) {
                return@withGraphNodeFilter Passibility.dangerous
            }
            node.passibility()
        }
    }

    // When the pathfinder wants to go through another intermediary node, we know that we probably want to use that.
    // So we don't want this edge to be used.
    val path = pathfinder.computePathTo(end.position.x, end.position.y, end.position.z) ?: return null
    if (interestingNodes.isNotEmpty() && path.any { it.isInRangeOf(interestingNodes, additionalRadius) }) {
        return null
    }

    return path
}

fun INode.isInRangeOf(roadNodes: List<RoadNode>, additionalRadius: Double = 0.0): Boolean {
    return roadNodes.any { roadNode ->
        val point = this.coordinates().toVector().mid()
        val radius = roadNode.radius + additionalRadius
        roadNode.position.toProperty().distanceSquared(point) <= radius * radius
    }
}

fun Coords.toVector() = Vector(x.toDouble(), y.toDouble(), z.toDouble())
