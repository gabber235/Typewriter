package com.typewritermc.roadnetwork.pathfinding.pathetic

import com.typewritermc.core.utils.point.World
import de.bsommerfeld.pathetic.api.pathing.result.Path

/**
 * Result of a pathfinding calculation between two positions in the road network.
 *
 * Callers should expect [Success] when a navigable path exists between the start and end positions,
 * considering the entity's pathfinding capabilities and the road network structure.
 * [Failure] is returned when no valid path can be found or when the calculation is cancelled.
 *
 * @see Success
 * @see Failure
 */
sealed interface PathCalculationResult {
    /**
     * A valid navigable path was successfully found between the requested positions.
     *
     * This result indicates that the pathfinding algorithm identified a traversable route
     * that respects the entity's movement capabilities.
     *
     * @property path The calculated path containing the sequence of nodes to follow
     * @property world The world in which the path exists
     * @property length The total geometric distance of the path in blocks. This represents
     *                  the actual distance traveled along the path's nodes.
     * @property weight The computed cost of traversing this path.
     * @property isFallback Whether the pathfinder fell back. The path does not reach the
     *                      requested target.
     */
    data class Success(
        val path: Path,
        val world: World,
        val length: Double,
        val weight: Double,
        val isFallback: Boolean = false,
    ) : PathCalculationResult

    /** Indicates no valid path could be found, or it was intentionally cancelled */
    data object Failure : PathCalculationResult
}