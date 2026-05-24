package com.typewritermc.roadnetwork.pathfinding.pathetic.processors.cost

import de.bsommerfeld.pathetic.api.pathing.processing.Cost
import de.bsommerfeld.pathetic.api.pathing.processing.CostProcessor
import de.bsommerfeld.pathetic.api.pathing.processing.context.EvaluationContext
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.api.wrapper.PathVector
import de.bsommerfeld.pathetic.bukkit.context.BukkitEnvironmentContext
import de.bsommerfeld.pathetic.bukkit.mapper.BukkitMapper
import kotlin.math.abs
import kotlin.math.ceil

/**
 * Encourages pathfinding to stay centered in open spaces by penalizing positions
 * that are too close to walls.
 *
 * It calculates the distance to the nearest walls horizontally and applies a
 * penalty that scales with both the available width and the node's distance from the center.
 *
 * @param intensity Multiplier for the centering penalty. Higher values create stronger
 *                  preference for center positions, lower values allow more wall-hugging
 * @param maxScanDistance Maximum blocks to scan when looking for walls. Prevents
 *                        excessive computation in large open areas
 * @param minPassageWidth Minimum total width below which no penalty is applied.
 *                        Essential for allowing navigation through tight corridors
 * @param entityHeight Height of the entity in blocks. Used to check for walls at
 *                     multiple vertical levels to ensure proper clearance
 */
class SpaceAwareCostProcessor(
    private val intensity: Double = 1.9,
    private val maxScanDistance: Int = 8,
    private val minPassageWidth: Int = 2,
    private val entityHeight: Double
) : CostProcessor {

    companion object {
        private val X_AXIS = PathVector(1.0, 0.0, 0.0)
        private val Z_AXIS = PathVector(0.0, 0.0, 1.0)
        private val NEGATIVE_X_AXIS = PathVector(-1.0, 0.0, 0.0)
        private val NEGATIVE_Z_AXIS = PathVector(0.0, 0.0, -1.0)
    }

    override fun calculateCostContribution(context: EvaluationContext): Cost {
        val heightLevels = ceil(entityHeight).toInt()

        var totalPenalty = 0.0
        for (yOffset in 0 until heightLevels) {
            val checkPosition = context.currentPathPosition.add(0.0, yOffset.toDouble(), 0.0)
            totalPenalty += calculateAxisPenalty(checkPosition, X_AXIS, context) +
                    calculateAxisPenalty(checkPosition, Z_AXIS, context)
        }

        val averagePenalty = if (entityHeight > 0) totalPenalty / entityHeight else totalPenalty
        return Cost.of(averagePenalty)
    }

    private fun calculateAxisPenalty(
        position: PathPosition,
        axis: PathVector,
        context: EvaluationContext
    ): Double {
        val negativeAxis = when (axis) {
            X_AXIS -> NEGATIVE_X_AXIS
            Z_AXIS -> NEGATIVE_Z_AXIS
            else -> axis.multiply(-1.0)
        }

        val distanceToPositiveWall = scanForWall(position, axis, context)
        val distanceToNegativeWall = scanForWall(position, negativeAxis, context)
        val totalWidth = distanceToPositiveWall + distanceToNegativeWall

        // Skip penalty for narrow passages to allow corridor navigation
        if (totalWidth < minPassageWidth) return 0.0

        val offsetFromCenter = abs(distanceToPositiveWall - distanceToNegativeWall)

        // Penalty formula: (offset / totalWidth) * intensity
        // Normalizes imbalance to 0-1 range - being 1 block off-center in a 10-wide hall
        // is less problematic than in a 4-wide corridor
        return (offsetFromCenter.toDouble() / totalWidth) * intensity
    }

    private fun scanForWall(
        startPosition: PathPosition,
        direction: PathVector,
        context: EvaluationContext
    ): Int {
        var currentPosition = startPosition

        for (distance in 1..maxScanDistance) {
            currentPosition = currentPosition.add(direction)
            if (isWall(currentPosition, context)) {
                return distance - 1
            }
        }
        return maxScanDistance
    }

    private fun isWall(position: PathPosition, context: EvaluationContext): Boolean {
        val environmentContext = context.environmentContext as BukkitEnvironmentContext
        val location = BukkitMapper.toLocation(position, environmentContext.world)
        return location.block.isSolid
    }
}