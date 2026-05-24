package com.typewritermc.roadnetwork.pathfinding.pathetic.processors.cost

import com.typewritermc.engine.paper.entry.entity.EntityPathingCapabilities
import de.bsommerfeld.pathetic.api.pathing.processing.Cost
import de.bsommerfeld.pathetic.api.pathing.processing.CostProcessor
import de.bsommerfeld.pathetic.api.pathing.processing.context.EvaluationContext
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.bukkit.context.BukkitEnvironmentContext
import de.bsommerfeld.pathetic.bukkit.mapper.BukkitMapper
import org.bukkit.util.BoundingBox
import kotlin.math.max

/**
 * Applies cost penalties for vertical movement to create more natural pathfinding
 * that prefers horizontal routes when possible.
 *
 * The processor distinguishes between steps and jumps, applying different penalty scales
 * to each. This prevents pathfinding from choosing unnecessarily vertical routes while still
 * allowing navigation through terrain with height variations.
 *
 * @param capabilities Entity movement capabilities including step height, jump ability, and dimensions.
 *                     Used to determine whether vertical movement requires jumping or is just stepping
 * @param stepPenalty Penalty multiplier for step movement. Should be > 1.0 to discourage
 *                    vertical movement while keeping it viable for necessary terrain navigation
 * @param jumpPenalty Penalty multiplier for jump movement. Should be higher than stepPenalty
 *                    to strongly discourage jumping when alternatives exist
 */
class JumpAwareCostProcessor(
    private val capabilities: EntityPathingCapabilities = EntityPathingCapabilities.DEFAULT,
    private val stepPenalty: Double = 1.5,
    private val jumpPenalty: Double = 3.7
) : CostProcessor {

    override fun calculateCostContribution(context: EvaluationContext): Cost {
        val parentPos = context.previousPathPosition ?: return Cost.ZERO
        val currentPos = context.currentPathPosition

        val verticalDelta = currentPos.y - parentPos.y
        if (verticalDelta <= 0.0) return Cost.ZERO

        val effectiveHeight = calculateEffectiveHeight(parentPos, currentPos, context)

        return when {
            effectiveHeight <= capabilities.maxStepHeight -> Cost.of(stepPenalty)
            capabilities.canJump && effectiveHeight <= capabilities.maxJumpHeight -> Cost.of(jumpPenalty)
            else -> Cost.ZERO
        }
    }

    private fun calculateEffectiveHeight(
        fromPos: PathPosition,
        toPos: PathPosition,
        context: EvaluationContext
    ): Double {
        val environmentContext = context.environmentContext as BukkitEnvironmentContext
        val toLocation = BukkitMapper.toLocation(toPos, environmentContext.world)
        val targetBlock = toLocation.block.getRelative(0, -1, 0)
        val collisionShape = targetBlock.collisionShape

        if (collisionShape.boundingBoxes.isEmpty()) {
            return toPos.y - fromPos.y
        }

        val entityFootprint = createEntityFootprint(toPos)
        val relevantCollisions = collisionShape.boundingBoxes.filter { collisionBox ->
            intersectsEntityFootprint(collisionBox, entityFootprint)
        }

        if (relevantCollisions.isEmpty()) {
            return toPos.y - fromPos.y
        }

        val obstacleTop = relevantCollisions.maxOf { it.maxY }
        val effectiveTopY = targetBlock.y.toDouble() + obstacleTop

        return max(0.0, effectiveTopY - fromPos.y)
    }

    private fun createEntityFootprint(position: PathPosition): BoundingBox {
        val halfWidth = capabilities.width / 2.0
        val centerX = position.x - position.flooredX + 0.5
        val centerZ = position.z - position.flooredZ + 0.5

        return BoundingBox(
            centerX - halfWidth, 0.0, centerZ - halfWidth,
            centerX + halfWidth, 1.0, centerZ + halfWidth
        )
    }

    private fun intersectsEntityFootprint(collisionBox: BoundingBox, entityFootprint: BoundingBox): Boolean {
        return !(collisionBox.maxX <= entityFootprint.minX ||
                collisionBox.minX >= entityFootprint.maxX ||
                collisionBox.maxZ <= entityFootprint.minZ ||
                collisionBox.minZ >= entityFootprint.maxZ)
    }
}