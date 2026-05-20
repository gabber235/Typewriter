package com.typewritermc.roadnetwork.pathfinding.pathetic.processors

import com.typewritermc.engine.paper.entry.entity.EntityPathingCapabilities
import com.typewritermc.roadnetwork.content.debug.DebugRecorderSupplier
import com.typewritermc.roadnetwork.content.debug.PathfindingDebugEvent
import com.typewritermc.roadnetwork.content.debug.PathfindingDebugRecorder
import com.typewritermc.roadnetwork.pathfinding.pathetic.properties.PathNodeProperty
import de.bsommerfeld.pathetic.api.pathing.processing.ValidationProcessor
import de.bsommerfeld.pathetic.api.pathing.processing.context.EvaluationContext
import de.bsommerfeld.pathetic.api.pathing.processing.context.SearchContext
import de.bsommerfeld.pathetic.api.wrapper.PathPosition
import de.bsommerfeld.pathetic.bukkit.context.BukkitEnvironmentContext
import de.bsommerfeld.pathetic.bukkit.mapper.BukkitMapper
import it.unimi.dsi.fastutil.longs.Long2DoubleMap
import it.unimi.dsi.fastutil.longs.Long2DoubleOpenHashMap
import it.unimi.dsi.fastutil.longs.Long2ObjectMap
import it.unimi.dsi.fastutil.longs.Long2ObjectOpenHashMap
import org.bukkit.util.BoundingBox
import org.bukkit.util.Vector
import kotlin.math.abs
import kotlin.math.floor
import kotlin.math.max

/**
 * Information about a required sidestep movement for an entity.
 */
data class SidestepInfo(
    val direction: Vector,
    val distance: Double
)

/**
 * A stateless and thread-safe node processor.
 *
 * Checks if an entity can physically fit at a node by testing for collision with
 * solid blocks using the entity bounding boxes. When direct placement isn't possible,
 * calculates and caches sidestep information for use by other processors.
 *
 * This processor must run after the `NodeTypeProcessor`
 */
class ObstructionProcessor(private val capabilities: EntityPathingCapabilities = EntityPathingCapabilities.DEFAULT) :
    ValidationProcessor {

    companion object {
        private val GROUND_Y_CACHE_KEY = ObstructionProcessor::class.java.packageName + ".groundYCache"
        private val SIDESTEP_CACHE_KEY = ObstructionProcessor::class.java.packageName + ".sidestepCache"
        private const val EPSILON = 0.1
        private const val MAX_SIDEWAYS_SHIFT = 0.5

        /**
         * Gets the cached ground Y-coordinate for a given node from the current search.
         *
         * @param context The active search context.
         * @param position The position of the node.
         * @return The cached ground Y-coordinate, or `Double.NaN` if the node has not been processed yet.
         */
        fun cachedGroundY(context: EvaluationContext, position: PathPosition): Double {
            val cache = groundYCache(context)
            val packedXYZ = packXYZ(position.flooredX, position.flooredY, position.flooredZ)
            return cache.get(packedXYZ)
        }

        /**
         * Gets the cached sidestep information for a given node from the current search.
         *
         * @param context The active search context.
         * @param position The position of the node.
         * @return The cached sidestep information, or null if no sidestep is required or the node hasn't been processed.
         */
        fun cachedSidestepInfo(context: EvaluationContext, position: PathPosition): SidestepInfo? {
            val cache = sidestepCache(context)
            val packedXYZ = packXYZ(position.flooredX, position.flooredY, position.flooredZ)
            return cache.get(packedXYZ)
        }

        @Suppress("UNCHECKED_CAST") // Cache is initialized with correct type in initializeSearch()
        private fun groundYCache(context: EvaluationContext): Long2DoubleMap {
            return context.sharedData[GROUND_Y_CACHE_KEY] as Long2DoubleMap
        }

        @Suppress("UNCHECKED_CAST") // Cache is initialized with correct type in initializeSearch()
        private fun sidestepCache(context: EvaluationContext): Long2ObjectMap<SidestepInfo> {
            return context.sharedData[SIDESTEP_CACHE_KEY] as Long2ObjectMap<SidestepInfo>
        }

        /**
         * Packs X, Y, Z coordinates into a single long for use as a cache key.
         * Uses 26 bits for X, 12 bits for Y, 26 bits for Z.
         * This supports coordinates from -33,554,432 to 33,554,431 for X/Z and -2,048 to 2,047 for Y.
         * Minecraft world borders are at ±30,000,000, so this provides sufficient range.
         */
        private fun packXYZ(x: Int, y: Int, z: Int): Long =
            (((x + 33554432L) and 0x3FFFFFF) shl 38) or          // 26 bits for X (33M range)
                    (((z + 33554432L) and 0x3FFFFFF) shl 12) or  // 26 bits for Z (33M range)
                    ((y + 2048L) and 0xFFF)                      // 12 bits for Y (2K range)
    }

    /**
     * Called once at the start of a pathfinding operation to prepare the caches.
     */
    override fun initializeSearch(context: SearchContext) {
        context.sharedData[GROUND_Y_CACHE_KEY] = Long2DoubleOpenHashMap().apply {
            defaultReturnValue(Double.NaN)
        }
        context.sharedData[SIDESTEP_CACHE_KEY] = Long2ObjectOpenHashMap<SidestepInfo>()
    }

    override fun isValid(context: EvaluationContext): Boolean {
        val currentPos = context.currentPathPosition
        val properties = NodeTypeProcessor.cachedProperties(context, currentPos) ?: return false

        // A node is a valid standing position only if it has a walkable surface directly below it.
        if (!properties.contains(PathNodeProperty.WALKABLE_SURFACE)) {
            val debugRecorder = context.sharedData[DebugRecorderSupplier.RECORDER_KEY] as? PathfindingDebugRecorder
            debugRecorder?.recordEvent(
                position = currentPos,
                parentPosition = context.previousPathPosition,
                event = PathfindingDebugEvent.NodeRejected(
                    position = currentPos,
                    reason = "No walkable surface below this position",
                    processorName = "ObstructionProcessor"
                ),
                verbose = true
            )
            return false
        }

        val groundY = findAndCacheGroundY(context, currentPos)
        if (groundY.isNaN()) {
            // This case should theoretically not be hit if WALKABLE_SURFACE is present.
            val debugRecorder = context.sharedData[DebugRecorderSupplier.RECORDER_KEY] as? PathfindingDebugRecorder
            debugRecorder?.recordEvent(
                position = currentPos,
                parentPosition = context.previousPathPosition,
                event = PathfindingDebugEvent.NodeRejected(
                    position = currentPos,
                    reason = "Cannot determine ground level",
                    processorName = "ObstructionProcessor"
                )
            )
            return false
        }

        val entityCenter = Vector(
            currentPos.x + 0.5,
            groundY + (capabilities.height / 2.0),
            currentPos.z + 0.5
        )

        if (!isObstructed(context, entityCenter)) {
            return true
        }

        val canSidestep = calculateAndCacheSidestep(context, currentPos, entityCenter)

        if (context.previousPathPosition == null) return true

        if (!canSidestep) {
            val debugRecorder = context.sharedData[DebugRecorderSupplier.RECORDER_KEY] as? PathfindingDebugRecorder
            debugRecorder?.let {
                val sidestepInfo = cachedSidestepInfo(context, currentPos)
                val reason = if (sidestepInfo != null) {
                    "Entity collision (sidestep needed: ${String.format("%.2f", sidestepInfo.distance)}m)"
                } else {
                    "Entity collision with no valid sidestep possible"
                }

                it.recordEvent(
                    position = currentPos,
                    parentPosition = context.previousPathPosition,
                    event = PathfindingDebugEvent.NodeRejected(
                        position = currentPos,
                        reason = reason,
                        processorName = "ObstructionProcessor"
                    )
                )
            }
        }

        return canSidestep
    }

    /**
     * Calculates sidestep information and caches it for later use by other processors.
     * Returns true if a valid sidestep was found, false otherwise.
     */
    private fun calculateAndCacheSidestep(
        context: EvaluationContext,
        currentPos: PathPosition,
        entityCenter: Vector
    ): Boolean {
        val previousPos = context.previousPathPosition ?: return false
        val movement = Vector(
            currentPos.x - previousPos.x,
            0.0,
            currentPos.z - previousPos.z
        )
        val movementDirection = if (movement.lengthSquared() > 0.0) movement.normalize() else return false

        val obstructions = findObstructions(context, entityCenter)
        if (obstructions.isEmpty()) {
            // Should not happen since isObstructed returned true
            return false
        }

        val escapeDirection = determineEscapeDirection(obstructions, entityCenter, movementDirection)
        val requiredDistance = obstructions.maxOfOrNull { box ->
            calculateEscapeDistance(entityCenter, box, escapeDirection)
        } ?: 0.0

        if (requiredDistance <= 0 || requiredDistance + EPSILON > MAX_SIDEWAYS_SHIFT) return false

        val finalDistance = requiredDistance + EPSILON
        val shiftedCenter = entityCenter.clone().add(
            escapeDirection.clone().multiply(finalDistance)
        )

        if (isObstructed(context, shiftedCenter)) {
            return false
        }

        val sidestepInfo = SidestepInfo(
            direction = escapeDirection.clone(),
            distance = finalDistance
        )

        val sidestepCache = sidestepCache(context)
        val packedXYZ = packXYZ(currentPos.flooredX, currentPos.flooredY, currentPos.flooredZ)
        sidestepCache.put(packedXYZ, sidestepInfo)

        return true
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
     * Finds all inflated bounding boxes that contain the entity center.
     */
    private fun findObstructions(
        context: EvaluationContext,
        entityCenter: Vector
    ): List<BoundingBox> {
        return blocksInEntityBounds(context, entityCenter)
            .mapNotNull { (blockPos, block) ->
                val properties = NodeTypeProcessor.cachedProperties(context, blockPos)
                properties?.let { props ->
                    if (PathNodeProperty.OPENABLE in props && capabilities.canInteract) {
                        return@mapNotNull null
                    }
                }

                block.collisionShape.boundingBoxes.mapNotNull { blockBox ->
                    val worldBox = blockBox.clone().shift(blockPos.x, blockPos.y, blockPos.z)
                    val inflatedBox = createInflatedBox(worldBox)

                    if (inflatedBox.contains(entityCenter)) inflatedBox else null
                }
            }
            .flatten()
    }

    /**
     * Gets all blocks that could potentially intersect with the entity's bounds.
     */
    private fun blocksInEntityBounds(
        context: EvaluationContext,
        entityCenter: Vector
    ): List<Pair<PathPosition, org.bukkit.block.Block>> {
        val halfWidth = capabilities.width / 2.0
        val halfHeight = capabilities.height / 2.0
        val searchBox = BoundingBox.of(entityCenter, halfWidth, halfHeight, halfWidth)
        val environmentContext = context.environmentContext as BukkitEnvironmentContext

        val (xPair, yPair, zPair) = flooredBounds(searchBox)
        val (minBx, maxBx) = xPair
        val (minBy, maxBy) = yPair
        val (minBz, maxBz) = zPair

        val blocks = mutableListOf<Pair<PathPosition, org.bukkit.block.Block>>()

        for (bx in minBx..maxBx) {
            for (by in minBy..maxBy) {
                for (bz in minBz..maxBz) {
                    val blockPos = PathPosition(bx.toDouble(), by.toDouble(), bz.toDouble())
                    val block = BukkitMapper.toLocation(blockPos, environmentContext.world).block
                    blocks.add(blockPos to block)
                }
            }
        }

        return blocks
    }

    /**
     * Calculates the minimum distance to move in a given direction to escape from an inflated bounding box.
     * This is used to determine how far sideways the entity needs to shift to avoid an obstruction.
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

    /**
     * Calculates escape distance along a single axis.
     */
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

    private fun findAndCacheGroundY(context: EvaluationContext, position: PathPosition): Double {
        val cache = groundYCache(context)
        val packedXYZ = packXYZ(position.flooredX, position.flooredY, position.flooredZ)

        val cachedY = cache.get(packedXYZ)
        if (!cachedY.isNaN()) {
            return cachedY
        }

        // On a cache miss, calculate the ground Y.
        // We know WALKABLE_SURFACE is present, so the block below the current position is the ground.
        val environmentContext = context.environmentContext as BukkitEnvironmentContext
        val groundBlock = BukkitMapper.toLocation(position, environmentContext.world).block.getRelative(0, -1, 0)
        var maxY = 0.0
        groundBlock.collisionShape.boundingBoxes.forEach { box -> maxY = max(maxY, box.maxY) }

        val calculatedY = groundBlock.y + maxY
        cache.put(packedXYZ, calculatedY)
        return calculatedY
    }

    /**
     * Checks if an entity's logical center point is obstructed by any solid world geometry.
     *
     * This method employs an "inflated box" technique to ensure proper clearance. Instead
     * of checking for overlaps between the entity's full bounding box and world geometry,
     * it conceptually expands each solid block's bounding box by the entity's half-dimensions.
     * This creates a "no-go zone" for the entity's center.
     *
     * The check is then simplified to whether the `entityCenter` point lies within any of
     * these inflated zones.
     *
     * @param context The node evaluation context, used to retrieve cached block properties.
     * @param entityCenter The center point of the entity's bounding box at its standing position.
     * @return `true` if the entity's center is inside an inflated obstacle's bounding box, `false` otherwise.
     */
    private fun isObstructed(context: EvaluationContext, entityCenter: Vector): Boolean {
        val halfWidth = capabilities.width / 2.0
        val halfHeight = capabilities.height / 2.0
        val searchBox = BoundingBox.of(entityCenter, halfWidth, halfHeight, halfWidth)
        val environmentContext: BukkitEnvironmentContext = context.environmentContext as BukkitEnvironmentContext

        val (xPair, yPair, zPair) = flooredBounds(searchBox)
        val (minBx, maxBx) = xPair
        val (minBy, maxBy) = yPair
        val (minBz, maxBz) = zPair

        for (bx in minBx..maxBx) {
            for (by in minBy..maxBy) {
                for (bz in minBz..maxBz) {
                    val blockPos = PathPosition(bx.toDouble(), by.toDouble(), bz.toDouble())
                    val properties = NodeTypeProcessor.cachedProperties(context, blockPos)

                    properties?.let { props ->
                        if (PathNodeProperty.OPENABLE in props && capabilities.canInteract) {
                            continue
                        }

                        if (PathNodeProperty.SURFACE_FEATURE in props) {
                            continue
                        }
                    }

                    val block = BukkitMapper.toLocation(blockPos, environmentContext.world).block
                    for (blockBox in block.collisionShape.boundingBoxes) {
                        val worldBlockBox = blockBox.clone().shift(bx.toDouble(), by.toDouble(), bz.toDouble())
                        val inflatedBox = createInflatedBox(worldBlockBox)

                        if (inflatedBox.contains(entityCenter)) {
                            val debugRecorder =
                                context.sharedData[DebugRecorderSupplier.RECORDER_KEY] as? PathfindingDebugRecorder
                            debugRecorder?.recordEvent(
                                position = context.currentPathPosition,
                                parentPosition = context.previousPathPosition,
                                event = PathfindingDebugEvent.NodeRejected(
                                    position = context.currentPathPosition,
                                    reason = "Entity bounding box is too big to fit in",
                                    processorName = "ObstructionProcessor"
                                ),
                                verbose = true
                            )
                            return true
                        }
                    }
                }
            }
        }

        return false
    }

    private fun createInflatedBox(worldBlockBox: BoundingBox): BoundingBox {
        val halfWidth = capabilities.width / 2.0
        val halfHeight = capabilities.height / 2.0

        return worldBlockBox.clone().expand(halfWidth, halfHeight, halfWidth)
    }

    private fun flooredBounds(box: BoundingBox): Array<Pair<Int, Int>> {
        return arrayOf(
            Pair(floor(box.minX).toInt(), floor(box.maxX).toInt()),
            Pair(floor(box.minY).toInt(), floor(box.maxY).toInt()),
            Pair(floor(box.minZ).toInt(), floor(box.maxZ).toInt())
        )
    }
}