package com.typewritermc.roadnetwork.pathfinding.pathetic.processors

import com.typewritermc.engine.paper.entry.entity.EntityPathingCapabilities
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import org.bukkit.World
import org.bukkit.block.Block
import org.bukkit.util.BoundingBox
import org.bukkit.util.Vector
import kotlin.math.abs
import kotlin.math.floor

/**
 * Information about a required sidestep movement for an entity.
 */
data class SidestepInfo(
    val direction: Vector,
    val distance: Double
)

/**
 * Decides where an entity fits when standing on a path node.
 *
 * The pathfinder accepts a node only when the entity fits on it, possibly after a sidestep, and a
 * walking entity has to stand on the same spot to avoid getting caught on the blocks around it.
 * Both use this class so they agree on that spot.
 */
class NodeClearance(
    private val world: World,
    private val capabilities: EntityPathingCapabilities,
) {
    companion object {
        private const val EPSILON = 0.1
        private const val MAX_SIDEWAYS_SHIFT = 0.5
    }

    private val halfWidth = capabilities.width / 2.0
    private val halfHeight = capabilities.height / 2.0

    fun groundY(position: PathPosition): Double {
        val groundBlock = world.getBlockAt(position.flooredX, position.flooredY - 1, position.flooredZ)
        val surfaceHeight = groundBlock.collisionShape.boundingBoxes.maxOfOrNull { it.maxY } ?: 0.0
        return groundBlock.y + surfaceHeight
    }

    fun entityCenter(position: PathPosition, groundY: Double = groundY(position)): Vector =
        Vector(position.flooredX + 0.5, groundY + halfHeight, position.flooredZ + 0.5)

    /**
     * Checks if an entity's center point is obstructed by any solid world geometry.
     *
     * Instead of overlapping the entity's bounding box with world geometry, each block box is
     * expanded by the entity's half-dimensions, creating a "no-go zone" for the entity's center.
     */
    fun isObstructed(entityCenter: Vector): Boolean = obstructions(entityCenter).any()

    /**
     * The sidestep needed to stand on [node] when arriving from [previous], or null when the entity
     * fits without one or no sidestep of at most [MAX_SIDEWAYS_SHIFT] frees it.
     */
    fun sidestep(node: PathPosition, previous: PathPosition): SidestepInfo? =
        sidestep(entityCenter(node), Vector(node.x - previous.x, 0.0, node.z - previous.z))

    fun sidestep(entityCenter: Vector, movement: Vector): SidestepInfo? {
        if (movement.lengthSquared() == 0.0) return null
        val obstructions = obstructions(entityCenter).toList()
        if (obstructions.isEmpty()) return null

        val escapeDirection = determineEscapeDirection(obstructions, entityCenter, movement.clone().normalize())
        val requiredDistance = obstructions.maxOf { box -> calculateEscapeDistance(entityCenter, box, escapeDirection) }
        if (requiredDistance <= 0 || requiredDistance + EPSILON > MAX_SIDEWAYS_SHIFT) return null

        val distance = requiredDistance + EPSILON
        val shiftedCenter = entityCenter.clone().add(escapeDirection.clone().multiply(distance))
        if (isObstructed(shiftedCenter)) return null

        return SidestepInfo(escapeDirection, distance)
    }

    /**
     * Finds all inflated bounding boxes that contain the entity center.
     */
    private fun obstructions(entityCenter: Vector): Sequence<BoundingBox> {
        val searchBox = BoundingBox.of(entityCenter, halfWidth, halfHeight, halfWidth)
        return blocksWithin(searchBox)
            .filterNot { capabilities.canInteract && NodeTypeProcessor.isOpenable(it) }
            .flatMap { block ->
                val collisionBoxes = block.collisionShape.boundingBoxes
                if (NodeTypeProcessor.isSurfaceFeature(collisionBoxes)) return@flatMap emptySequence()
                collisionBoxes.asSequence().map { box ->
                    box.clone()
                        .shift(block.x.toDouble(), block.y.toDouble(), block.z.toDouble())
                        .expand(halfWidth, halfHeight, halfWidth)
                }
            }
            .filter { it.contains(entityCenter) }
    }

    private fun blocksWithin(box: BoundingBox): Sequence<Block> = sequence {
        for (x in floor(box.minX).toInt()..floor(box.maxX).toInt()) {
            for (y in floor(box.minY).toInt()..floor(box.maxY).toInt()) {
                for (z in floor(box.minZ).toInt()..floor(box.maxZ).toInt()) {
                    yield(world.getBlockAt(x, y, z))
                }
            }
        }
    }

    /**
     * Determines the best escape direction based on obstruction positions relative to entity center.
     */
    private fun determineEscapeDirection(
        obstructions: List<BoundingBox>,
        entityCenter: Vector,
        movementDirection: Vector
    ): Vector {
        val obstructionCenter = calculateWeightedObstructionCenter(obstructions, entityCenter)
        val leftDirection = Vector(-movementDirection.z, 0.0, movementDirection.x)

        // If weighted obstruction center is on the left, escape right and vice versa
        val dotProduct = obstructionCenter.dot(leftDirection)
        return if (dotProduct > 0) leftDirection.clone().multiply(-1.0) else leftDirection
    }

    /**
     * Calculates the weighted center of mass of all obstructions relative to entity center.
     */
    private fun calculateWeightedObstructionCenter(
        obstructions: List<BoundingBox>,
        entityCenter: Vector
    ): Vector {
        val weightedSum = Vector(0.0, 0.0, 0.0)
        var totalWeight = 0.0

        for (box in obstructions) {
            val boxCenter = Vector(
                (box.minX + box.maxX) / 2.0,
                0.0,
                (box.minZ + box.maxZ) / 2.0
            )

            val toObstruction = boxCenter.subtract(entityCenter)
            // Weight by inverse distance (closer obstructions have more influence)
            val weight = 1.0 / (toObstruction.length() + 0.1)

            weightedSum.add(toObstruction.multiply(weight))
            totalWeight += weight
        }

        return if (totalWeight > 0) weightedSum.multiply(1.0 / totalWeight) else Vector(0.0, 0.0, 0.0)
    }

    /**
     * Calculates the minimum distance to move in a given direction to escape from an inflated bounding box.
     */
    private fun calculateEscapeDistance(
        entityCenter: Vector,
        inflatedBox: BoundingBox,
        direction: Vector
    ): Double {
        val xDistance = calculateAxisEscapeDistance(
            entityCenter.x, direction.x, inflatedBox.minX, inflatedBox.maxX
        )
        val zDistance = calculateAxisEscapeDistance(
            entityCenter.z, direction.z, inflatedBox.minZ, inflatedBox.maxZ
        )

        return listOfNotNull(xDistance, zDistance).minOrNull() ?: 0.0
    }

    private fun calculateAxisEscapeDistance(
        centerCoord: Double,
        directionComp: Double,
        minBound: Double,
        maxBound: Double
    ): Double? {
        if (abs(directionComp) <= 0.0001) return null

        val distance = if (directionComp < 0) {
            (centerCoord - minBound) / abs(directionComp)
        } else {
            (maxBound - centerCoord) / directionComp
        }

        return if (distance > 0) distance else null
    }
}
